# ------------------------------------------------------------------
# Projeto final: roteamento de Porto Alegre
#
# Faz todo o cálculo do capítulo de roteamento multimodal com os dados de Porto Alegre
# e grava os resultados intermediários que o relatorio_porto_alegre.qmd lê.
#
# Antes de rodar:
#   - o pacote porto_alegre.7z, do Release dados-modulo5, extraído em
#     dados/brutos/projeto_final/porto_alegre/;
#   - Java 21 instalado (java -version responde 21);
#   - os pacotes r5r, gtfstools, accessibility, stplanr, sf e dplyr.
#
# Uso: com o projeto do curso aberto no RStudio, abra este arquivo e
# clique em Source, ou rode no terminal, na pasta do projeto:
#   Rscript roteamento_porto_alegre.R
#
# Resultado: dados/projeto_final/porto_alegre/*.rds (leva uns 5 minutos)
# ------------------------------------------------------------------

options(java.parameters = "-Xmx8G")   # memória da JVM: antes de carregar o r5r
library(sf)
library(r5r)

# ---- Parâmetros de Porto Alegre -----------------------------------------
cidade  <- "porto_alegre"
entrada <- file.path("dados/brutos/projeto_final", cidade)   # o pacote da cidade
saidas  <- file.path("dados/projeto_final", cidade)          # os resultados
pasta_cenario <- file.path("dados/brutos", paste0(cidade, "_cenario"))

partida <- as.POSIXct("2025-10-22 07:00:00", tz = "America/Sao_Paulo")   # numa quarta-feira
centro  <- data.frame(id = "centro", lon = -51.2276, lat = -30.0277)   # Mercado Público
bairro  <- data.frame(id = "bairro", lon = -51.153, lat = -30.148)   # Restinga

arquivo_aop  <- file.path(entrada, paste0("aop_", cidade, ".rds"))
arquivo_gtfs <- file.path(entrada, paste0("gtfs_", cidade, ".zip"))
if (!file.exists(arquivo_aop) || !file.exists(arquivo_gtfs)) {
  stop("Não achei o pacote de dados em ", entrada, ". Baixe ", cidade, ".7z do Release ",
       "dados-modulo5 e extraia-o em dados/brutos/projeto_final/.")
}
dir.create(saidas, recursive = TRUE, showWarnings = FALSE)
inicio <- Sys.time()

# ---- 1. A rede atual ------------------------------------------------
aop <- readRDS(arquivo_aop) |>
  dplyr::filter(P001 > 0)

rede <- r5r::build_network(data_path = entrada, verbose = FALSE)
n_rotas <- nrow(r5r::transit_network_to_sf(rede)$routes)
stopifnot(n_rotas > 0)

# ---- 2. Os pontos: o centro de cada hexágono com população -----------
xy <- sf::st_coordinates(sf::st_centroid(sf::st_geometry(aop)))
pontos <- data.frame(id = aop$id_hex, lon = xy[, 1], lat = xy[, 2])

# ---- 3. A matriz de tempos de viagem --------------------------------
matriz <- function(r) {
  r5r::travel_time_matrix(
    r, origins = pontos, destinations = pontos,
    mode = c("WALK", "TRANSIT"), departure_datetime = partida,
    time_window = 60, percentiles = 50,
    max_walk_time = 20, max_trip_duration = 90,
    verbose = FALSE, progress = FALSE
  )
}
ttm <- matriz(rede)

# ---- 4. Isócronas a partir do centro --------------------------------
iso <- r5r::isochrone(
  rede, origins = centro, mode = c("WALK", "TRANSIT"),
  departure_datetime = partida, cutoffs = c(15, 30, 45, 60),
  time_window = 60, max_walk_time = 20, verbose = FALSE, progress = FALSE
)
saveRDS(iso, file.path(saidas, "isocronas.rds"))

# ---- 5. Itinerário detalhado, do bairro ao centro -------------------
det <- r5r::detailed_itineraries(
  rede, origins = bairro, destinations = centro,
  mode = c("WALK", "TRANSIT"), departure_datetime = partida,
  max_walk_time = 20, shortest_path = FALSE, verbose = FALSE, progress = FALSE
)
saveRDS(det, file.path(saidas, "itinerario.rds"))

# ---- 6. Carregamento da rede viária ---------------------------------
# dos 30 hexágonos mais populosos aos 10 com mais empregos, de carro
origens  <- aop |> sf::st_drop_geometry() |> dplyr::slice_max(P001, n = 30, with_ties = FALSE) |>
  dplyr::select(id_hex, P001)
destinos <- aop |> sf::st_drop_geometry() |> dplyr::slice_max(T001, n = 10, with_ties = FALSE) |>
  dplyr::select(id_hex, T001)

pares_od <- expand.grid(origem = origens$id_hex, destino = destinos$id_hex,
                        stringsAsFactors = FALSE) |>
  dplyr::filter(origem != destino) |>
  dplyr::left_join(origens, by = c("origem" = "id_hex")) |>
  dplyr::left_join(destinos, by = c("destino" = "id_hex")) |>
  dplyr::mutate(fluxo = P001 * T001 / sum(destinos$T001))

rotas <- r5r::detailed_itineraries(
  rede,
  origins      = pontos[match(pares_od$origem, pontos$id), ],
  destinations = pontos[match(pares_od$destino, pontos$id), ],
  mode = "CAR", departure_datetime = partida, shortest_path = TRUE,
  verbose = FALSE, progress = FALSE
) |>
  dplyr::left_join(dplyr::select(pares_od, origem, destino, fluxo),
                   by = c("from_id" = "origem", "to_id" = "destino"))

carga <- stplanr::overline(rotas, attrib = "fluxo")
saveRDS(carga, file.path(saidas, "carga.rds"))

r5r::stop_r5(rede)

# ---- 7. O cenário: sem o quarto das linhas com menos viagens --------
gtfs <- gtfstools::read_gtfs(arquivo_gtfs)
viagens <- gtfs$trips |>
  dplyr::count(route_id, name = "viagens")
cortadas <- viagens |>
  dplyr::filter(viagens <= stats::quantile(viagens, 0.25)) |>
  dplyr::pull(route_id)
saveRDS(cortadas, file.path(saidas, "linhas_cortadas.rds"))

gtfs_cenario <- gtfstools::filter_by_route_id(gtfs, route_id = cortadas, keep = FALSE)

unlink(pasta_cenario, recursive = TRUE)     # uma rede antiga ignoraria o GTFS novo
dir.create(pasta_cenario, recursive = TRUE)
file.copy(list.files(entrada, pattern = "\\.pbf$", full.names = TRUE), pasta_cenario)
gtfstools::write_gtfs(gtfs_cenario, file.path(pasta_cenario, "gtfs_cenario.zip"))

# ---- 8. Recalcular e comparar ---------------------------------------
rede_cenario <- r5r::build_network(data_path = pasta_cenario, verbose = FALSE)
ttm_cenario  <- matriz(rede_cenario)
r5r::stop_r5(rede_cenario)

uso_solo <- aop |>
  sf::st_drop_geometry() |>
  dplyr::transmute(id = id_hex, populacao = P001, empregos = T001, renda = R002)

acesso_cum <- function(m) {
  accessibility::cumulative_cutoff(
    travel_matrix = m, land_use_data = uso_solo,
    opportunity = "empregos", travel_cost = "travel_time_p50", cutoff = 60
  )
}

comparacao <- acesso_cum(ttm) |>
  dplyr::rename(atual = empregos) |>
  dplyr::left_join(dplyr::rename(acesso_cum(ttm_cenario), cenario = empregos), by = "id") |>
  dplyr::left_join(uso_solo, by = "id") |>
  dplyr::mutate(
    perda_abs = cenario - atual,
    perda_pct = dplyr::if_else(atual > 0, 100 * (cenario / atual - 1), NA_real_)
  )
saveRDS(comparacao, file.path(saidas, "comparacao.rds"))

# o que o relatório cita sobre o cálculo
saveRDS(list(rotas = n_rotas, rotas_cenario = nrow(gtfs_cenario$routes),
             pares = nrow(ttm), pares_cenario = nrow(ttm_cenario),
             minutos = as.numeric(difftime(Sys.time(), inicio, units = "mins")),
             r5r = as.character(packageVersion("r5r"))),
        file.path(saidas, "info.rds"))

message("Pronto: ", length(list.files(saidas)), " arquivos em ", saidas, ", em ",
        round(as.numeric(difftime(Sys.time(), inicio, units = "mins")), 1), " minutos.")
