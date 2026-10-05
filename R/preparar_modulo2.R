# ------------------------------------------------------------------
# preparar_modulo2.R
# Deixa tudo pronto para o Módulo 2: instala os pacotes que faltam e baixa
# os dados da Release do GitHub para a pasta dados/ do projeto.
#
# Abra o projeto do curso no RStudio e cole no console:
#   source("https://raw.githubusercontent.com/Joaobazzo/curso-r-transportes/main/R/preparar_modulo2.R")
#
# Pode rodar quantas vezes quiser: o que já estiver instalado ou baixado é pulado.
# ------------------------------------------------------------------

local({

  # pacotes usados nos capítulos do Módulo 2 (inclui os do Módulo 1 que reaparecem)
  pacotes <- c(
    # espaciais
    "sf", "terra", "tidyterra", "units", "duckdb", "duckspatial",
    # bases públicas brasileiras
    "geobr", "censobr", "sidrar", "osmdata", "osmextract", "elevatr",
    # mapas
    "ggplot2", "ggspatial", "leaflet", "mapview", "mapgl", "scales", "patchwork", "ggrepel",
    # manipulação e leitura
    "dplyr", "stringr", "readr", "writexl", "janitor", "knitr"
  )

  url_dados <- paste0(
    "https://github.com/Joaobazzo/curso-r-transportes/releases/download/",
    "dados-modulo2/dados_modulo2.zip"
  )

  # arquivos que o zip traz; se todos existem, o download é pulado
  arquivos <- file.path("dados", c(
    "portos_antaq.csv",
    file.path("brutos", c(
      "br116_serra.gpkg", "dem_br116_perfil.tif", "dem_morretes.tif", "grade_pr.gpkg",
      "muni_br.gpkg", "muni_pr_sc.gpkg", "pr.gpkg", "sedes_2022.gpkg"
    ))
  ))

  titulo <- function(x) message("\n== ", x, " ", strrep("=", max(0, 60 - nchar(x))))

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

  # sem espelho do CRAN definido, o R pergunta qual usar
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

  # 2. dados ----
  titulo("Dados")
  if (all(file.exists(arquivos))) {
    message("Os dados do Módulo 2 já estão em dados/.")
  } else {
    zip <- tempfile(fileext = ".zip")
    message("Baixando dados_modulo2.zip (cerca de 55 MB)...")
    ok <- tryCatch({
      op <- options(timeout = max(600, getOption("timeout")))
      on.exit(options(op), add = TRUE)
      download.file(url_dados, zip, mode = "wb", quiet = FALSE)
      # um zip válido começa com "PK"; um proxy que bloqueia devolve uma página HTML
      identical(readBin(zip, "raw", 2), charToRaw("PK"))
    }, error = function(e) FALSE)

    if (!ok) {
      stop(
        "Não foi possível baixar os dados. Baixe à mão pelo navegador:\n  ", url_dados,
        "\ne descompacte o arquivo dentro de ", getwd(), call. = FALSE
      )
    }
    # extrai só a pasta dados/ (o LEIA-ME.txt do zip fica de fora)
    conteudo <- unzip(zip, list = TRUE)$Name
    unzip(zip, files = grep("^dados/", conteudo, value = TRUE), exdir = ".", overwrite = TRUE)
    unlink(zip)
    message("Dados extraídos em ", file.path(getwd(), "dados"))
  }
  faltam_dados <- arquivos[!file.exists(arquivos)]

  # 3. conferência ----
  titulo("Conferência")
  if ("sf" %in% rownames(installed.packages())) {
    v <- sf::sf_extSoftVersion()
    message("sf ", packageVersion("sf"), " | GDAL ", v[["GDAL"]], " | PROJ ", v[["PROJ"]])
  }
  if ("terra" %in% rownames(installed.packages())) {
    message("terra ", packageVersion("terra"))
  }

  if (length(falharam) == 0 && length(faltam_dados) == 0) {
    message("\nTudo pronto para o Módulo 2.")
  } else {
    if (length(falharam) > 0) {
      message("\nPacotes que NÃO instalaram: ", paste(falharam, collapse = ", "))
      message("Rode de novo; se persistir, copie a mensagem de erro acima e abra uma issue:")
      message("  https://github.com/Joaobazzo/curso-r-transportes/issues")
    }
    if (length(faltam_dados) > 0) {
      message("\nArquivos que faltam: ", paste(faltam_dados, collapse = ", "))
    }
  }
})
