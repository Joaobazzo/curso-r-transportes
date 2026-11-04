# Prepara os resultados que o capítulo "Roteamento de transporte público com r5r"
# (@sec-m4-gtfs) mostra no site sem rodar o Java: o itinerário detalhado e as
# isócronas do exemplo de Porto Alegre que vem com o r5r.
# Os resultados de Fortaleza (@sec-m4-r5r) vêm do próprio script do capítulo,
# scripts/m4-05-r5r.R, que os salva em dados/projeto_final/.
# Exige Java 21. Roda uma vez, fora da renderização:
# Rscript R/preparar_exemplos_r5r.R

options(java.parameters = "-Xmx4G")
library(sf)

# Porto Alegre: o exemplo que vem com o r5r ------------------------------------
saida_poa <- "dados/processados/poa"
dir.create(saida_poa, recursive = TRUE, showWarnings = FALSE)

pasta_poa <- file.path(tempdir(), "poa")
dir.create(pasta_poa, showWarnings = FALSE)
file.copy(list.files(system.file("extdata/poa", package = "r5r"), full.names = TRUE),
          pasta_poa, recursive = TRUE)

rede_poa <- r5r::build_network(data_path = pasta_poa)
pontos_poa <- read.csv(file.path(pasta_poa, "poa_points_of_interest.csv"))
partida_poa <- as.POSIXct("2019-05-13 14:00:00", tz = "America/Sao_Paulo")

det <- r5r::detailed_itineraries(
  rede_poa,
  origins            = pontos_poa[pontos_poa$id == "farrapos_station", ],
  destinations       = pontos_poa[pontos_poa$id == "pucrs", ],
  mode               = c("WALK", "TRANSIT"),
  departure_datetime = partida_poa,
  shortest_path      = FALSE
)
saveRDS(sf::st_transform(det, 4326), file.path(saida_poa, "itinerario.rds"))

iso <- r5r::isochrone(
  rede_poa,
  origins            = pontos_poa[pontos_poa$id == "bus_central_station", ],
  mode               = c("WALK", "TRANSIT"),
  departure_datetime = partida_poa,
  cutoffs            = c(15, 30, 45)
)
saveRDS(sf::st_transform(iso, 4326), file.path(saida_poa, "isocronas.rds"))
r5r::stop_r5(rede_poa)
