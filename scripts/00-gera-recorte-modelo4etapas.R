# -----------------------------------------------------------------------------
# Gera o recorte didatico do modelo quatro etapas da RMC (exportacao PTV VISUM)
#
# Entrada : dados/brutos/modelo4etapas/shapefile/   (fora do repositorio)
# Saida   : dados/processados/modelo4etapas/
#
# Rode a partir da raiz do projeto:  source("scripts/00-gera-recorte-modelo4etapas.R")
# -----------------------------------------------------------------------------

library(sf)
library(dplyr)
library(stringr)

dir_bruto <- "dados/brutos/modelo4etapas/shapefile"
dir_saida <- "dados/processados/modelo4etapas"
dir.create(dir_saida, recursive = TRUE, showWarnings = FALSE)

# -----------------------------------------------------------------------------
# 1. Dicionario de campos: o shapefile trunca nomes em 10 caracteres,
#    e o arquivo .CTF que acompanha a exportacao guarda o nome original.
# -----------------------------------------------------------------------------

le_ctf <- function(arquivo) {
  utils::read.csv2(arquivo, fileEncoding = "latin1", stringsAsFactors = FALSE)
}

# VOLVEHPRT(AP) -> volvehprt
limpa_nome <- function(x) {
  x |>
    stringr::str_remove_all("\\((AP|C)\\)") |>
    stringr::str_replace_all("[^A-Za-z0-9_]", "_") |>
    stringr::str_replace_all("_+", "_") |>
    stringr::str_remove("^_|_$") |>
    stringr::str_to_lower()
}

renomeia_por_ctf <- function(x, arquivo_ctf) {
  ctf <- le_ctf(arquivo_ctf)
  de   <- stringr::str_trim(ctf$Alias)
  para <- limpa_nome(stringr::str_trim(ctf$Name))
  nomes <- stringr::str_trim(names(x))
  casa <- match(nomes, de)
  nomes[!is.na(casa)] <- para[casa[!is.na(casa)]]
  stats::setNames(x, nomes)
}

# -----------------------------------------------------------------------------
# 2. Links
# -----------------------------------------------------------------------------

links <- sf::st_read(
  file.path(dir_bruto, "Modelo OD_Pico Manha_20180530_link.SHP"),
  options = "ENCODING=LATIN1", quiet = TRUE
) |>
  renomeia_por_ctf(file.path(dir_bruto, "Modelo OD_Pico Manha_20180530_link.CTF"))

numericas <- c("typeno", "length", "lengthdir", "numlanes", "capprt", "v0prt",
               "vcur_prtsys", "t0_prtsys", "tcur_prtsys", "volvehprt",
               "volcapratioprt", "vehhourtravt0", "vehhourtravtcur",
               "vehkmtravprt", "fluxo_hpm", "fluxo_hpt", "hpm_tc",
               "vel_bus", "vel_bus_linha", "vel_linha_bus")

links <- links |>
  dplyr::mutate(dplyr::across(dplyr::any_of(numericas), ~ suppressWarnings(as.numeric(.x))))

# ---- correcao de unidades ---------------------------------------------------
# ATENCAO: os nomes do VISUM nao correspondem a unidade gravada.
#   VEHKMTRAVPRT    esta em metros  (nao em km)
#   VEHHOURTRAVT0   esta em segundos (nao em horas)
#   VEHHOURTRAVTCUR esta em segundos (nao em horas)
#   VOLCAPRATIOPRT  esta em percentual (nao em razao)
# Confira sempre: volume x comprimento_km deve reproduzir veic_km.

links <- links |>
  dplyr::mutate(
    comprimento_m  = lengthdir,
    comprimento_km = lengthdir / 1000,
    veic_km        = vehkmtravprt    / 1000,
    veic_h_livre   = vehhourtravt0   / 3600,
    veic_h_carreg  = vehhourtravtcur / 3600,
    atraso_veic_h  = veic_h_carreg - veic_h_livre,
    vc             = volcapratioprt / 100,
    # 360000000 e o sentinela do VISUM para "sistema sem acesso ao link"
    sem_acesso     = t0_prtsys >= 3.6e8,
    t0_prtsys      = dplyr::if_else(sem_acesso, NA_real_, t0_prtsys),
    tcur_prtsys    = dplyr::if_else(sem_acesso, NA_real_, tcur_prtsys),
    sentido        = dplyr::if_else(stringr::str_trim(as.character(isforward)) == "1",
                                    "direto", "inverso"),
    tem_contagem   = !is.na(hpm_tc) & hpm_tc > 0
  )

colunas <- c("no", "name", "fromnodeno", "tonodeno", "typeno", "tsysset",
             "isforward", "sentido", "numlanes", "isonewayroad",
             "capprt", "v0prt", "vcur_prtsys", "t0_prtsys", "tcur_prtsys",
             "volvehprt", "vc", "comprimento_m", "comprimento_km",
             "veic_km", "veic_h_livre", "veic_h_carreg", "atraso_veic_h",
             "fluxo_hpm", "hpm_tc", "tem_contagem", "id_posto", "tipo_posto",
             "vel_bus", "vel_linha_bus", "sem_acesso",
             # campos originais, mantidos para o exercicio de unidades
             "lengthdir", "vehkmtravprt", "vehhourtravt0", "vehhourtravtcur",
             "volcapratioprt")

links <- links |> dplyr::select(dplyr::any_of(colunas))

# Recorte estrutural: rodovias, arteriais e coletoras principais (typeno < 50),
# mais qualquer link com contagem de trafego.
links_estrutural <- links |>
  dplyr::filter(typeno < 50 | tem_contagem) |>
  dplyr::mutate(geometry = sf::st_simplify(geometry, dTolerance = 1e-5))

# -----------------------------------------------------------------------------
# 3. Nos
# -----------------------------------------------------------------------------

nos <- sf::st_read(
  file.path(dir_bruto, "Modelo OD_Pico Manhã_20180530_node.SHP"),
  options = "ENCODING=LATIN1", quiet = TRUE
)
names(nos) <- stringr::str_to_lower(stringr::str_trim(names(nos)))

nos_usados <- unique(c(links_estrutural$fromnodeno, links_estrutural$tonodeno))

nos <- nos |>
  dplyr::mutate(
    stop_name = dplyr::coalesce(as.character(stop_name), ""),
    stop_name = stringr::str_trim(stop_name),
    eh_parada = stop_name != ""
  ) |>
  dplyr::filter(no %in% nos_usados | eh_parada | brt == 1) |>
  dplyr::select(no, xcoord, ycoord, volprt, brt, eh_parada,
                stop_id, stop_code, stop_name)

# -----------------------------------------------------------------------------
# 4. Zonas (apenas centroides nesta exportacao)
# -----------------------------------------------------------------------------

zonas <- sf::st_read(
  file.path(dir_bruto, "Modelo OD_Pico Manhã_20180530_zone_centroid.SHP"),
  options = "ENCODING=LATIN1", quiet = TRUE
) |>
  renomeia_por_ctf(file.path(dir_bruto, "Modelo OD_Pico Manhã_20180530_zone_centroid.CTF"))

zonas <- zonas |>
  dplyr::mutate(
    nm_municip_orig = nm_municip,
    # o DBF de origem nao declara pagina de codigo e traz bytes invalidos;
    # aqui so normalizamos. O de-para com o codigo do IBGE e exercicio de aula.
    nm_municip_norm = nm_municip |>
      iconv(from = "", to = "ASCII//TRANSLIT", sub = "") |>
      stringr::str_to_upper() |>
      stringr::str_squish(),
    code_muni = NA_integer_
  )

# -----------------------------------------------------------------------------
# 5. Escrita
# -----------------------------------------------------------------------------

gpkg <- file.path(dir_saida, "rede_rmc_2018.gpkg")
if (file.exists(gpkg)) file.remove(gpkg)

sf::st_write(links_estrutural, gpkg, layer = "links",           quiet = TRUE)
sf::st_write(nos,              gpkg, layer = "nos",             append = TRUE, quiet = TRUE)
sf::st_write(zonas,            gpkg, layer = "zonas_centroide", append = TRUE, quiet = TRUE)

escreve_parquet <- function(x, caminho) {
  tabela <- sf::st_drop_geometry(x)
  con <- duckdb::dbConnect(duckdb::duckdb())
  on.exit(duckdb::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  duckdb::duckdb_register(con, "tmp", tabela)
  DBI::dbExecute(con, sprintf("COPY tmp TO '%s' (FORMAT PARQUET)",
                              normalizePath(caminho, winslash = "/", mustWork = FALSE)))
  invisible(caminho)
}

escreve_parquet(links,           file.path(dir_saida, "links_rmc_2018_completo.parquet"))
escreve_parquet(links_estrutural, file.path(dir_saida, "links_rmc_2018_estrutural.parquet"))

dic <- le_ctf(file.path(dir_bruto, "Modelo OD_Pico Manha_20180530_link.CTF"))
names(dic) <- c("campo_visum", "campo_shapefile")
utils::write.csv(dic, file.path(dir_saida, "dicionario_campos_visum.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8")

# -----------------------------------------------------------------------------
# 6. Conferencia: estes numeros devem bater com o README do recorte
# -----------------------------------------------------------------------------

conferencia <- links |>
  sf::st_drop_geometry() |>
  dplyr::summarise(
    links            = dplyr::n(),
    veic_km          = round(sum(veic_km, na.rm = TRUE)),
    veic_h_livre     = round(sum(veic_h_livre, na.rm = TRUE)),
    veic_h_carreg    = round(sum(veic_h_carreg, na.rm = TRUE)),
    atraso_veic_h    = round(sum(atraso_veic_h, na.rm = TRUE)),
    vel_media_kmh    = round(sum(veic_km, na.rm = TRUE) / sum(veic_h_carreg, na.rm = TRUE), 1),
    links_saturados  = sum(vc >= 1, na.rm = TRUE),
    links_com_contagem = sum(tem_contagem, na.rm = TRUE)
  )

print(conferencia)

stopifnot(
  conferencia$links == 208336,
  abs(conferencia$veic_km - 3676335) < 5,
  conferencia$links_saturados == 3436,
  conferencia$links_com_contagem == 63
)

message("Recorte gerado em ", normalizePath(dir_saida))
