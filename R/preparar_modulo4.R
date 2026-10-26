# ------------------------------------------------------------------
# preparar_modulo4.R
# Deixa tudo pronto para o Módulo 4:
#   1. instala os pacotes que faltam;
#   2. baixa os dados do módulo da Release do GitHub para a pasta dados/;
#   3. confere se o R enxerga o Java 21, que o r5r exige.
#
# Abra o projeto do curso no RStudio e cole no console:
#   source("https://raw.githubusercontent.com/Joaobazzo/curso-r-transportes/main/R/preparar_modulo4.R")
#
# Pode rodar quantas vezes quiser: o que já estiver instalado ou baixado é pulado.
# ------------------------------------------------------------------

local({

  # pacotes usados nos capítulos do Módulo 4 (inclui os dos módulos anteriores que reaparecem)
  pacotes <- c(
    # OSM e redes
    "sf", "osmdata", "osmextract", "sfnetworks", "tidygraph", "dodgr",
    # transporte público e acessibilidade
    "r5r", "rJava", "gtfstools", "accessibility", "aopdata", "h3jsr",
    # fluxos
    "stplanr",
    # manipulação e gráficos
    "dplyr", "tidyr", "ggplot2", "scales", "patchwork", "mapview", "knitr",
    # para testar o Java num processo separado
    "callr"
  )

  url_dados <- paste0(
    "https://github.com/Joaobazzo/curso-r-transportes/releases/download/",
    "dados-modulo4/dados_modulo4.zip"
  )

  # arquivos que o zip do módulo traz; se todos existem, o download é pulado
  arquivos <- file.path("dados", "brutos", c(
    "fortaleza/nordeste.osm.pbf", "fortaleza/gtfs_fortaleza.zip", "aop_fortaleza.rds",
    "rede_sao_paulo_santos.gpkg", "portos_osm.gpkg", "pontes_br116.gpkg"
  ))

  titulo <- function(x) message("\n== ", x, " ", strrep("=", max(0, 60 - nchar(x))))

  # baixa o zip e confere se veio um zip de verdade (começa com "PK")
  baixar <- function(url, destino) {
    op <- options(timeout = max(1800, getOption("timeout")))
    on.exit(options(op), add = TRUE)
    ok <- tryCatch({
      utils::download.file(url, destino, mode = "wb", quiet = FALSE)
      identical(readBin(destino, "raw", 2), charToRaw("PK"))
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
    message("Os dados do Módulo 4 já estão em dados/brutos/.")
  } else {
    zip <- tempfile(fileext = ".zip")
    message("Baixando dados_modulo4.zip (cerca de 460 MB, pode demorar)...")
    if (baixar(url_dados, zip)) {
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

  # 3. Java 21 para o r5r ----
  # rJava é carregado num processo separado: se falhar, não derruba a sua sessão
  titulo("Java")
  versao_java <- tryCatch(
    callr::r(function() {
      rJava::.jinit()
      rJava::.jcall("java/lang/System", "S", "getProperty", "java.version")
    }),
    error = function(e) NA_character_
  )
  java_ok <- !is.na(versao_java) && startsWith(versao_java, "21")
  if (java_ok) {
    message("O R enxerga o Java ", versao_java, ". O r5r vai funcionar.")
  } else {
    message(if (is.na(versao_java)) "O R não encontrou nenhum Java." else
              paste0("O R enxerga o Java ", versao_java, ", mas o r5r exige o 21."))
    message("Instale o JDK 21 sem precisar de administrador:")
    message('  install.packages("rJavaEnv")')
    message("  rJavaEnv::java_quick_install(version = 21)")
    message("e reinicie o R. O passo a passo está no capítulo de roteamento.")
  }

  # 4. conferência ----
  titulo("Conferência")
  if (length(falharam) == 0 && length(faltam_dados) == 0 && java_ok) {
    message("\nTudo pronto para o Módulo 4.")
  } else {
    if (length(falharam) > 0) {
      message("\nPacotes que NÃO instalaram: ", paste(falharam, collapse = ", "))
      message("Rode de novo; se persistir, copie a mensagem de erro acima e abra uma issue:")
      message("  https://github.com/Joaobazzo/curso-r-transportes/issues")
    }
    if (length(faltam_dados) > 0) {
      message("\nArquivos do módulo que faltam: ", paste(basename(faltam_dados), collapse = ", "))
    }
    if (!java_ok) message("\nFalta o Java 21 (veja acima). Só os capítulos do r5r precisam dele.")
  }
})
