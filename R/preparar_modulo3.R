# ------------------------------------------------------------------
# preparar_modulo3.R
# Deixa tudo pronto para o Módulo 3:
#   1. instala os pacotes que faltam;
#   2. baixa os dados do módulo da Release do GitHub para a pasta dados/;
#   3. baixa os arquivos do Comex Stat direto do servidor do MDIC.
#
# Abra o projeto do curso no RStudio e cole no console:
#   source("https://raw.githubusercontent.com/Joaobazzo/curso-r-transportes/main/R/preparar_modulo3.R")
#
# Pode rodar quantas vezes quiser: o que já estiver instalado ou baixado é pulado.
# ------------------------------------------------------------------

local({

  # pacotes usados nos capítulos do Módulo 3 (inclui os dos módulos anteriores que reaparecem)
  pacotes <- c(
    # OSM e redes
    "sf", "osmdata", "osmextract", "sfnetworks", "tidygraph", "dodgr",
    # geocodificação
    "geocodebr", "enderecobr", "geobr",
    # bases grandes e SQL
    "duckdb", "duckplyr", "duckspatial", "DBI", "dbplyr", "arrow", "data.table",
    # funções e iteração
    "purrr",
    # matrizes e fluxos
    "Matrix", "stplanr",
    # relevo e declividade
    "terra", "tidyterra", "elevatr", "ggspatial",
    # manipulação, leitura e gráficos
    "dplyr", "tidyr", "stringr", "stringi", "readr", "readxl", "writexl", "units",
    "ggplot2", "scales", "patchwork", "mapview", "knitr",
    # downloads
    "curl"
  )

  url_dados <- paste0(
    "https://github.com/Joaobazzo/curso-r-transportes/releases/download/",
    "dados-modulo3/dados_modulo3.zip"
  )

  # arquivos que o zip do módulo traz; se todos existem, o download é pulado
  arquivos <- file.path("dados", "brutos", c(
    "rede_sao_paulo_santos.gpkg", "portos_osm.gpkg", "pontes_br116.gpkg",
    "uf_br.gpkg", "muni_br.gpkg"
  ))

  # Comex Stat: baixados do servidor do MDIC, não da Release (são públicos e grandes)
  comex <- c(
    "EXP_2024_MUN.csv" = "https://balanca.economia.gov.br/balanca/bd/comexstat-bd/mun/EXP_2024_MUN.csv",
    "tab_UF_MUN.csv"   = "https://balanca.economia.gov.br/balanca/bd/tabelas/UF_MUN.csv"
  )
  pasta_comex <- file.path("dados", "brutos", "comexstat")

  titulo <- function(x) message("\n== ", x, " ", strrep("=", max(0, 60 - nchar(x))))

  # baixa um arquivo e confere se veio o que se esperava: um zip começa com "PK",
  # e o servidor do MDIC devolve uma página HTML ("<") quando algo dá errado
  baixar <- function(url, destino, tipo = c("zip", "csv")) {
    tipo <- match.arg(tipo)
    op <- options(timeout = max(900, getOption("timeout")))
    on.exit(options(op), add = TRUE)
    ok <- tryCatch({
      utils::download.file(url, destino, mode = "wb", quiet = FALSE)
      if (tipo == "zip") {
        identical(readBin(destino, "raw", 2), charToRaw("PK"))
      } else {
        !startsWith(readLines(destino, n = 1, warn = FALSE), "<")
      }
    }, error = function(e) FALSE)
    if (!ok && file.exists(destino)) file.remove(destino)
    ok
  }

  # o servidor do MDIC já esteve com o certificado de segurança vencido, o que faz o
  # download comum falhar com "SSL connect error". Os dados são públicos, então, só para
  # esse servidor, tentamos de novo sem verificar o certificado
  baixar_mdic <- function(url, destino) {
    if (baixar(url, destino, "csv")) return(TRUE)
    message("  O download comum falhou (provável certificado vencido no servidor do MDIC).")
    message("  Tentando de novo sem verificar o certificado...")
    ok <- tryCatch({
      curl::curl_download(url, destino, quiet = TRUE,
                          handle = curl::new_handle(ssl_verifypeer = 0L, ssl_verifyhost = 0L))
      !startsWith(readLines(destino, n = 1, warn = FALSE), "<")
    }, error = function(e) FALSE)
    if (!ok && file.exists(destino)) file.remove(destino)
    ok
  }

  # 0. onde os dados vão parar ----
  titulo("Pasta do projeto")
  message(getwd())
  if (length(list.files(pattern = "\\.Rproj$")) == 0) {
    warning(
      "Nenhum arquivo .Rproj nesta pasta: os dados serão salvos em ", getwd(), ".\n",
      "Se não for a pasta do curso, abra o projeto (File > Open Project) e rode de novo.",
      call. = FALSE, immediate. = TRUE
    )
  }

  # 1. pacotes ----
  titulo("Pacotes")

  repo <- getOption("repos")[["CRAN"]]
  if (is.null(repo) || is.na(repo) || repo %in% c("", "@CRAN@")) {
    options(repos = c(CRAN = "https://cloud.r-project.org"))
  }
  # no Windows e no macOS, usa sempre o binário pronto: não compila nada e não
  # pergunta "Do you want to install from sources?"
  if (.Platform$OS.type == "windows" || Sys.info()[["sysname"]] == "Darwin") {
    options(install.packages.compile.from.source = "never")
  }

  faltando <- setdiff(pacotes, rownames(installed.packages()))
  if (length(faltando) == 0) {
    message("Todos os ", length(pacotes), " pacotes já estão instalados.")
  } else {
    message("Instalando ", length(faltando), " pacote(s): ", paste(faltando, collapse = ", "))
    message("Pode levar alguns minutos.")
    install.packages(faltando)
  }
  falharam <- setdiff(pacotes, rownames(installed.packages()))

  # 2. dados do módulo (Release do GitHub) ----
  titulo("Dados do módulo")
  if (all(file.exists(arquivos))) {
    message("Os dados do Módulo 3 já estão em dados/brutos/.")
  } else {
    zip <- tempfile(fileext = ".zip")
    message("Baixando dados_modulo3.zip...")
    if (baixar(url_dados, zip, "zip")) {
      conteudo <- unzip(zip, list = TRUE)$Name
      unzip(zip, files = grep("^dados/", conteudo, value = TRUE), exdir = ".", overwrite = TRUE)
      unlink(zip)
      message("Dados extraídos em ", file.path(getwd(), "dados", "brutos"))
    } else {
      warning("Não foi possível baixar os dados do módulo. Baixe à mão pelo navegador:\n  ",
              url_dados, "\ne descompacte o arquivo dentro de ", getwd(),
              call. = FALSE, immediate. = TRUE)
    }
  }
  faltam_dados <- arquivos[!file.exists(arquivos)]

  # 3. Comex Stat (servidor do MDIC) ----
  titulo("Comex Stat")
  dir.create(pasta_comex, recursive = TRUE, showWarnings = FALSE)
  for (arq in names(comex)) {
    destino <- file.path(pasta_comex, arq)
    if (file.exists(destino) && file.size(destino) > 0) {
      message("Já baixado: ", arq)
      next
    }
    message("Baixando ", arq, if (startsWith(arq, "EXP")) " (cerca de 60 MB)", "...")
    if (!baixar_mdic(comex[[arq]], destino)) {
      warning("Falhou o download de ", arq, ". O servidor do MDIC às vezes fica fora do ar; ",
              "rode o script de novo mais tarde.", call. = FALSE, immediate. = TRUE)
    }
  }
  faltam_comex <- names(comex)[!file.exists(file.path(pasta_comex, names(comex)))]

  # 4. conferência ----
  titulo("Conferência")
  if (length(falharam) == 0 && length(faltam_dados) == 0 && length(faltam_comex) == 0) {
    message("\nTudo pronto para o Módulo 3.")
  } else {
    if (length(falharam) > 0) {
      message("\nPacotes que NÃO instalaram: ", paste(falharam, collapse = ", "))
      message("Rode de novo; se persistir, copie a mensagem de erro acima e abra uma issue:")
      message("  https://github.com/Joaobazzo/curso-r-transportes/issues")
    }
    if (length(faltam_dados) > 0) {
      message("\nArquivos do módulo que faltam: ", paste(basename(faltam_dados), collapse = ", "))
    }
    if (length(faltam_comex) > 0) {
      message("\nArquivos do Comex Stat que faltam: ", paste(faltam_comex, collapse = ", "))
    }
  }

  message("\nLembrete: na primeira geocodificação, o geocodebr baixa sozinho os dados do CNEFE ",
          "para uma pasta de cache. Isso pode levar alguns minutos.")
})
