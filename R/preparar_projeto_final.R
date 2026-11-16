# ------------------------------------------------------------------
# preparar_projeto_final.R
# Monta data_raw/projeto_final/{cidade}/ com os dados de entrada do projeto
# final (@sec-m5-projeto) para cinco cidades: o aluno escolhe uma e roda o
# roteamento e a acessibilidade do módulo 5 com ela.
#
# Curitiba ficou de fora: o GTFS da URBS (Mobility Database, mdb-3225) só tem o
# horário da primeira parada, repetido na última, e as viagens saem com duração
# zero no r5r. Entrou o Rio de Janeiro, também no aopdata.
#
# Cada pasta de cidade recebe:
#   {cidade}.osm.pbf   malha viária (OpenStreetMap), recortada em volta da cidade
#   gtfs_{cidade}.zip  GTFS do transporte público (um arquivo só, mesmo onde há mais
#                      de um operador: os feeds são unidos com gtfstools::merge_gtfs)
#   aop_{cidade}.rds   grade hexagonal do aopdata (Ipea): população, empregos,
#                      renda e acessibilidade de 2019
#   LEIA-ME.txt        fontes, validade do GTFS e a data de partida recomendada
#
# É um script de quem mantém o curso, não dos alunos: baixa uns 1,5 GB de
# extratos do OSM e leva uns 30 minutos. Os alunos recebem as pastas prontas.
#
# Requisitos: Java 21 (o mesmo do r5r) e o jar do R5, que o r5r baixa. O
# recorte do .pbf é feito em Java, com o osm-lib que vem dentro do jar do R5
# (o R não grava .pbf). Rode a partir da raiz do projeto:
#   Rscript R/preparar_projeto_final.R
# ------------------------------------------------------------------

library(sf)
library(data.table)   # remover_viagens_instantaneas() usa a sintaxe do data.table

destino <- "data_raw/projeto_final"
fontes  <- file.path(tempdir(), "fontes_osm")     # extratos regionais, só durante o preparo
fontes  <- Sys.getenv("FONTES_OSM", fontes)       # ou uma pasta fixa, para não baixar de novo
dir.create(destino, recursive = TRUE, showWarnings = FALSE)
dir.create(fontes,  recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------------
# As cidades
#   aop:      código da cidade no aopdata
#   regiao:   extrato da Geofabrik que contém a cidade
#   gtfs:     ids dos feeds no Mobility Database (https://mobilitydatabase.org)
#   partida:  data e hora recomendadas, dentro da validade do GTFS e num dia com viagens
#   centro, bairro: origem das isócronas e as duas pontas do itinerário de exemplo
#             (no capítulo, Praça do Ferreira e Messejana, em Fortaleza)
# ------------------------------------------------------------------
cidades <- list(
  fortaleza = list(
    nome = "Fortaleza (CE)", aop = "for", regiao = "nordeste",
    gtfs = "local",                       # o mesmo do módulo 4 (dados/brutos/fortaleza)
    partida = "2026-05-16 07:00:00", fuso = "America/Fortaleza",
    centro = list(nome = "Praça do Ferreira", lon = -38.5267, lat = -3.7275),
    bairro = list(nome = "Messejana", lon = -38.4920, lat = -3.8300),
    obs = c("O GTFS só tem viagens de SÁBADO e DOMINGO: use um sábado ou domingo entre",
            "abril e julho de 2026. Num dia útil o r5r não acha ônibus e devolve só caminhada.")
  ),
  sao_paulo = list(
    nome = "São Paulo (SP)", aop = "spo", regiao = "sudeste",
    gtfs = "mdb-8",                       # SPTrans
    partida = "2026-05-13 07:00:00", fuso = "America/Sao_Paulo",
    centro = list(nome = "Praça da Sé", lon = -46.6340, lat = -23.5504),
    bairro = list(nome = "Cidade Tiradentes", lon = -46.4020, lat = -23.5830),
    obs = c("O GTFS da SPTrans traz ônibus, metrô e trens da CPTM. O original usa horários por",
            "frequência, que o detailed_itineraries() do r5r não aceita: foi convertido em",
            "horários (stop_times) e cobre só as viagens das 5h às 11h. Para outro horário,",
            "refaça com R/preparar_projeto_final.R.",
            "É a maior rede do pacote: são uns 9.700 hexágonos com população, e a matriz de",
            "tempos leva bem mais que nas outras cidades. Reserve memória (-Xmx8G) e tempo.")
  ),
  rio_de_janeiro = list(
    nome = "Rio de Janeiro (RJ)", aop = "rio", regiao = "sudeste",
    gtfs = "mdb-1791",                    # SMTR: ônibus municipais e BRT
    partida = "2026-05-13 07:00:00", fuso = "America/Sao_Paulo",
    centro = list(nome = "Central do Brasil", lon = -43.1910, lat = -22.9035),
    bairro = list(nome = "Madureira", lon = -43.3384, lat = -22.8735),
    obs = c("O GTFS da Secretaria Municipal de Transportes traz os ônibus municipais e o BRT;",
            "metrô, trens da SuperVia, VLT e barcas não estão incluídos. O original usa horários",
            "por frequência, que o detailed_itineraries() do r5r não aceita: foi convertido em",
            "horários (stop_times) e cobre só as viagens das 5h às 11h.")
  ),
  porto_alegre = list(
    nome = "Porto Alegre (RS)", aop = "poa", regiao = "sul",
    gtfs = "mdb-7",                       # EPTC
    partida = "2025-10-22 07:00:00", fuso = "America/Sao_Paulo",
    centro = list(nome = "Mercado Público", lon = -51.2276, lat = -30.0277),
    bairro = list(nome = "Restinga", lon = -51.1530, lat = -30.1480),
    obs = c("O GTFS da EPTC vale de 12/09/2025 a 12/12/2025. Use uma data dentro desse",
            "período (a recomendada é uma quarta-feira de outubro de 2025): fora dele, o r5r",
            "não acha ônibus. O trem metropolitano (Trensurb) não está incluído.")
  ),
  belo_horizonte = list(
    nome = "Belo Horizonte (MG)", aop = "bho", regiao = "sudeste",
    gtfs = c("mdb-9", "mdb-687"),        # SUMOB: convencional e suplementar
    partida = "2026-05-13 07:00:00", fuso = "America/Sao_Paulo",
    centro = list(nome = "Praça Sete", lon = -43.9378, lat = -19.9191),
    bairro = list(nome = "Venda Nova", lon = -43.9580, lat = -19.8160),
    obs = c("O GTFS une os dois feeds da SUMOB/BH, o sistema convencional e o suplementar",
            "(os identificadores do segundo ganharam um prefixo). Vale até 31/12/2026.",
            "O metrô não está incluído.")
  )
)

# ------------------------------------------------------------------
# 1. Grade do aopdata e retângulo de recorte (os hexágonos com 10 km de folga)
# ------------------------------------------------------------------
for (slug in names(cidades)) {
  pasta <- file.path(destino, slug)
  dir.create(pasta, showWarnings = FALSE)
  arq <- file.path(pasta, paste0("aop_", slug, ".rds"))
  if (!file.exists(arq)) {
    aop <- aopdata::read_access(city = cidades[[slug]]$aop, mode = "public_transport", year = 2019,
                                peak = TRUE, geometry = TRUE, showProgress = FALSE)
    saveRDS(aop, arq)
  }
  aop <- readRDS(arq)
  com_pop <- aop[aop$P001 > 0, ]
  cidades[[slug]]$hexagonos <- nrow(com_pop)
  cidades[[slug]]$bbox <- sf::st_as_sfc(sf::st_bbox(com_pop)) |>
    sf::st_transform(5880) |>                        # SIRGAS 2000 / Brazil Polyconic: metros
    sf::st_buffer(10000) |>
    sf::st_transform(4326) |>
    sf::st_bbox()
}

# ------------------------------------------------------------------
# 2. GTFS
# ------------------------------------------------------------------

# Remove as viagens em que a última parada tem o mesmo horário da primeira (duração
# zero). Acontecem em alguns feeds (6% das viagens de Porto Alegre, 1% das do Rio) e,
# no r5r, viram teletransporte: a acessibilidade sai maior do que é. Sem elas, o
# serviço fica um pouco subestimado, o que é o erro menos grave.
remover_viagens_instantaneas <- function(gtfs) {
  seg <- function(h) {
    p <- data.table::tstrsplit(h, ":", fixed = TRUE, type.convert = TRUE)
    p[[1]] * 3600 + p[[2]] * 60 + p[[3]]
  }
  st <- gtfs$stop_times[order(trip_id, stop_sequence)]
  dur <- st[, .(dur = seg(arrival_time[.N]) - seg(departure_time[1])), by = trip_id]
  zero <- dur$trip_id[!is.na(dur$dur) & dur$dur <= 0]
  saida <- if (length(zero) == 0) gtfs else
    gtfstools::filter_by_trip_id(gtfs, trip_id = zero, keep = FALSE)
  attr(saida, "removidas") <- c(length(zero), nrow(dur))
  saida
}

removidas <- list()
for (slug in names(cidades)) {
  arq  <- file.path(destino, slug, paste0("gtfs_", slug, ".zip"))
  if (file.exists(arq)) next
  ids <- cidades[[slug]]$gtfs
  if (identical(ids, "local")) {
    baixados <- "dados/brutos/fortaleza/gtfs_fortaleza.zip"
  } else {
    baixados <- file.path(tempdir(), paste0(ids, ".zip"))
    for (k in seq_along(ids)) {
      utils::download.file(sprintf("https://files.mobilitydatabase.org/%s/latest.zip", ids[k]),
                           baixados[k], mode = "wb", quiet = TRUE)
    }
  }
  feeds <- lapply(baixados, gtfstools::read_gtfs, quiet = TRUE)
  if (length(feeds) == 1) {
    gtfs <- feeds[[1]]
  } else {
    gtfs <- do.call(gtfstools::merge_gtfs, c(feeds, list(prefix = TRUE)))
    # o merge_gtfs() põe o prefixo em stop_id, mas não em parent_station: sem isto, as
    # paradas apontam para estações que não existem e o r5r recusa o GTFS
    pai <- !is.na(gtfs$stops$parent_station) & gtfs$stops$parent_station != ""
    gtfs$stops$parent_station[pai] <- paste0(sub("_.*$", "", gtfs$stops$stop_id[pai]), "_",
                                             gtfs$stops$parent_station[pai])
  }
  if (!is.null(gtfs$frequencies) && nrow(gtfs$frequencies) > 0) {
    # horários por frequência: o detailed_itineraries() do r5r não aceita. Convertemos em
    # stop_times, mas só das 5h às 11h, que cobrem a partida às 7h com janela de 60 min e
    # viagens de até 90 min; o dia inteiro deixaria o arquivo com centenas de MB
    gtfs <- gtfstools::filter_by_time_of_day(gtfs, from = "05:00:00", to = "11:00:00")
    gtfs <- gtfstools::frequencies_to_stop_times(gtfs)
  }
  gtfs <- remover_viagens_instantaneas(gtfs)
  removidas[[slug]] <- attr(gtfs, "removidas")
  gtfstools::write_gtfs(gtfs, arq, quiet = TRUE)
}

# o número de viagens removidas fica registrado na pasta, para o LEIA-ME
for (slug in names(removidas)) {
  r <- removidas[[slug]]
  aviso <- file.path(destino, slug, "removidas.txt")
  if (r[1] == 0) { unlink(aviso); next }
  writeLines(enc2utf8(sprintf(paste0("Foram removidas %s de %s viagens (%s%%) cuja última parada tem o
",
                                     "mesmo horário da primeira (duração zero: no r5r, seriam teletransporte)."),
                              format(r[1], big.mark = ".", decimal.mark = ","),
                              format(r[2], big.mark = ".", decimal.mark = ","),
                              format(round(100 * r[1] / r[2], 1), decimal.mark = ","))),
             aviso, useBytes = TRUE)
}

# ------------------------------------------------------------------
# 3. OpenStreetMap: extrato regional da Geofabrik, recortado em Java
# ------------------------------------------------------------------
java_home <- Sys.getenv("JAVA_HOME")
if (!nzchar(java_home)) stop("Defina JAVA_HOME apontando para o JDK 21 (o mesmo do r5r).")
jar <- list.files(file.path(r5r:::r5r_env$cache_dir), pattern = "\\.jar$", recursive = TRUE,
                  full.names = TRUE)[1]
if (is.na(jar)) jar <- r5r::download_r5(quiet = TRUE)

# o programa de recorte: lê o extrato uma vez e grava um .pbf por retângulo
codigo_java <- '
import com.conveyal.osmlib.*;
import java.io.*;

public class Recorte {
  // args: entrada.pbf banco [saida.pbf minLat minLon maxLat maxLon]...
  public static void main(String[] a) throws Exception {
    OSM osm = new OSM(a[1]);
    osm.tileIndexing = true;
    osm.readFromFile(a[0]);
    System.out.println("lido: " + osm.ways.size() + " vias");
    for (int i = 2; i + 4 < a.length; i += 5) {
      TileOSMSource src = new TileOSMSource(osm);
      src.setBoundingBox(Double.parseDouble(a[i + 1]), Double.parseDouble(a[i + 2]),
                         Double.parseDouble(a[i + 3]), Double.parseDouble(a[i + 4]));
      try (OutputStream out = new BufferedOutputStream(new FileOutputStream(a[i]))) {
        src.copyTo(new PBFOutput(out));
      }
      System.out.println("gravado: " + a[i]);
    }
    osm.close();
  }
}'
pasta_java <- file.path(tempdir(), "recorte_java")
dir.create(pasta_java, showWarnings = FALSE)
writeLines(codigo_java, file.path(pasta_java, "Recorte.java"))
bin <- file.path(java_home, "bin")
status <- system2(file.path(bin, "javac"), c("-cp", shQuote(jar), "-d", shQuote(pasta_java),
                                             shQuote(file.path(pasta_java, "Recorte.java"))))
if (status != 0) stop("não foi possível compilar o recorte em Java")

# Fortaleza: o recorte já existe no pacote do módulo 4 (veja R/gerar_release_modulo4.R)
pbf_fortaleza <- file.path(destino, "fortaleza", "fortaleza.osm.pbf")
if (!file.exists(pbf_fortaleza)) file.copy("dados/brutos/fortaleza/fortaleza.osm.pbf", pbf_fortaleza)

regioes <- setdiff(unique(vapply(cidades, `[[`, character(1), "regiao")), "nordeste")
for (regiao in regioes) {
  slugs <- names(cidades)[vapply(cidades, `[[`, character(1), "regiao") == regiao]
  saidas <- file.path(destino, slugs, paste0(slugs, ".osm.pbf"))
  if (all(file.exists(saidas))) next

  extrato <- file.path(fontes, paste0(regiao, "-latest.osm.pbf"))
  if (!file.exists(extrato)) {
    options(timeout = 3600)
    utils::download.file(sprintf("https://download.geofabrik.de/south-america/brazil/%s-latest.osm.pbf",
                                 regiao), extrato, mode = "wb")
  }

  argumentos <- c(shQuote(extrato), shQuote(file.path(fontes, paste0(regiao, ".db"))))
  for (k in seq_along(slugs)) {
    bb <- cidades[[slugs[k]]]$bbox
    argumentos <- c(argumentos, shQuote(saidas[k]),
                    sprintf("%.4f", c(bb[["ymin"]], bb[["xmin"]], bb[["ymax"]], bb[["xmax"]])))
  }
  message("Recortando ", regiao, " (pode levar uns 15 minutos)...")
  status <- system2(file.path(bin, "java"),
                    c("-Xmx8G", "-cp", shQuote(paste(jar, pasta_java, sep = .Platform$path.sep)),
                      "Recorte", argumentos))
  if (status != 0) stop("o recorte de ", regiao, " falhou")
  unlink(list.files(fontes, pattern = paste0("^", regiao, "\\.db"), full.names = TRUE))
}

# ------------------------------------------------------------------
# 4. LEIA-ME de cada cidade
# ------------------------------------------------------------------
for (slug in names(cidades)) {
  cid   <- cidades[[slug]]
  pasta <- file.path(destino, slug)
  arqs  <- list.files(pasta, pattern = "\\.(pbf|zip|rds)$")
  tam   <- sprintf("%-28s %6.1f MB", arqs, file.size(file.path(pasta, arqs)) / 1e6)
  bb    <- round(cid$bbox, 3)
  fonte_gtfs <- if (identical(cid$gtfs, "local")) {
    "GTFS: o mesmo do módulo 4 (Etufor)."
  } else {
    paste0("GTFS: Mobility Database, ", paste(sprintf("https://files.mobilitydatabase.org/%s/latest.zip",
                                                      cid$gtfs), collapse = " e "),
           " (baixado em ", format(Sys.Date(), "%d/%m/%Y"), ").")
  }
  writeLines(enc2utf8(c(
    paste0("Projeto final: ", cid$nome),
    strrep("=", 60),
    "",
    "Arquivos:",
    paste0("  ", tam),
    "",
    paste0("Hexágonos com população (aopdata): ", format(cid$hexagonos, big.mark = ".", decimal.mark = ",")),
    "",
    "Data de partida recomendada para o r5r:",
    paste0('  partida <- as.POSIXct("', cid$partida, '", tz = "', cid$fuso, '")'),
    "",
    "Observações:",
    paste0("  ", cid$obs),
    if (file.exists(file.path(pasta, "removidas.txt")))
      paste0("  ", readLines(file.path(pasta, "removidas.txt"), encoding = "UTF-8")),
    "",
    "Fontes:",
    paste0("  OSM: recorte do extrato '", cid$regiao, "' da Geofabrik (download.geofabrik.de),"),
    sprintf("       lon %s a %s, lat %s a %s.", bb[["xmin"]], bb[["xmax"]], bb[["ymin"]], bb[["ymax"]]),
    paste0("  ", fonte_gtfs),
    "  aopdata: Ipea, grade H3, transporte público, pico, 2019 (aop_*.rds).",
    "",
    "Para usar no projeto final: rode o script do capítulo de roteamento multimodal",
    "(scripts/m4-05-r5r.R) trocando estas linhas, que no capítulo são de Fortaleza:",
    "",
    paste0('  arquivo   <- "', pasta, '/aop_', slug, '.rds"'),
    paste0('  pasta     <- "', pasta, '"'),
    paste0('  partida   <- as.POSIXct("', cid$partida, '", tz = "', cid$fuso, '")'),
    paste0('  centro    <- data.frame(id = "centro", lon = ', cid$centro$lon, ', lat = ', cid$centro$lat,
           ')   # ', cid$centro$nome),
    paste0('  messejana <- data.frame(id = "bairro", lon = ', cid$bairro$lon, ', lat = ', cid$bairro$lat,
           ')   # ', cid$bairro$nome),
    "",
    paste0('e, onde aparece "gtfs_fortaleza.zip", use "gtfs_', slug, '.zip". O cenário copia o .pbf'),
    paste0('para dados/brutos/fortaleza_cenario/: troque por ', slug, '_cenario, se quiser manter as duas.')
  )), file.path(pasta, "LEIA-ME.txt"), useBytes = TRUE)
}

message("Pronto: ", destino)
print(data.frame(
  cidade = names(cidades),
  hexagonos = vapply(cidades, `[[`, numeric(1), "hexagonos"),
  arquivos = vapply(names(cidades), function(s) paste(list.files(file.path(destino, s)), collapse = ", "),
                    character(1))
), row.names = FALSE)
