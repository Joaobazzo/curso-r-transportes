# ------------------------------------------------------------------
# preparar_modulo4.R
# Deixa tudo pronto para o Módulo 4:
#   1. instala os pacotes que faltam;
#   2. baixa os dados do módulo da Release do GitHub para a pasta dados/;
#   3. confere se o R enxerga o Java 21, que o r5r exige;
#   4. testa se a máquina roda o roteamento: dodgr (automóvel) e r5r
#      (transporte público, com os dados de Porto Alegre que vêm no pacote).
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
    "fortaleza/fortaleza.osm.pbf", "fortaleza/gtfs_fortaleza.zip", "aop_fortaleza.rds",
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
    message("Baixando dados_modulo4.zip (cerca de 70 MB)...")
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

  # 4. teste de roteamento ----
  # cada teste roda num processo separado: se travar ou faltar memória, sua sessão segue viva
  titulo("Teste de roteamento")

  ram_gb <- tryCatch(ps::ps_system_memory()$total / 2^30, error = function(e) NA)
  if (!is.na(ram_gb)) {
    message(sprintf("Memória RAM: %.0f GB", ram_gb))
    if (ram_gb < 6) message("  Pouca memória para o r5r: feche outros programas antes de rodar o módulo.")
  }

  cronometrar <- function(f) {
    t0 <- Sys.time()
    r <- tryCatch(f(), error = function(e) structure(conditionMessage(e), class = "falha"))
    list(resultado = r, segundos = as.numeric(difftime(Sys.time(), t0, units = "secs")))
  }

  # dodgr: rede de exemplo do próprio pacote (Hampi, Índia), matriz de distâncias 50 x 50
  teste_dodgr <- cronometrar(function() callr::r(function() {
    g <- dodgr::weight_streetnet(dodgr::hampi, wt_profile = "motorcar")
    v <- dodgr::dodgr_vertices(g)
    set.seed(1)
    pts <- v$id[sample(nrow(v), 50)]
    d <- dodgr::dodgr_dists(g, from = pts, to = pts)
    sum(is.finite(d))
  }, timeout = 300))
  dodgr_ok <- !inherits(teste_dodgr$resultado, "falha")
  if (dodgr_ok) {
    message(sprintf("dodgr: ok (%.0f s). Roteamento de automóvel funciona.", teste_dodgr$segundos))
  } else {
    message("dodgr: FALHOU. ", teste_dodgr$resultado)
  }

  # r5r: monta a rede de Porto Alegre e calcula uma matriz de tempos a pé + transporte público
  r5r_ok <- FALSE
  # o r5r baixa o motor R5 (um .jar de uns 60 MB) na primeira vez; sem ele, a rede vem vazia.
  # Baixamos antes, para dar um aviso claro se a rede bloquear o download
  r5_jar <- if (java_ok) tryCatch(callr::r(function() {
    ns <- asNamespace("r5r")
    jar <- suppressMessages(r5r::download_r5(quiet = TRUE))
    url <- tryCatch(ns$fileurl_from_metadata(ns$r5r_env$r5_jar_version), error = function(e) NA)
    list(ok = !is.null(jar), url = url, pasta = ns$r5r_env$cache_dir)
  }, timeout = 900), error = function(e) list(ok = FALSE, url = NA, pasta = NA))
  if (java_ok && !isTRUE(r5_jar$ok)) {
    message("r5r: não consegui baixar o motor R5 (arquivo .jar, uns 60 MB).")
    message("  Em redes com restrição, baixe pelo navegador:")
    message("    ", r5_jar$url)
    message("  e salve o arquivo, sem renomear, nesta pasta:")
    message("    ", r5_jar$pasta)
    message("  Depois rode este script de novo.")
  }

  if (java_ok && isTRUE(r5_jar$ok)) {
    message("r5r: montando a rede de Porto Alegre (leva de 1 a 3 minutos na primeira vez)...")
    teste_r5r <- cronometrar(function() callr::r(function() {
      options(java.parameters = "-Xmx2G")
      origem <- system.file("extdata/poa", package = "r5r")
      pasta <- file.path(tempdir(), "teste_r5r_poa")
      dir.create(pasta, showWarnings = FALSE)
      file.copy(file.path(origem, c("poa_osm.pbf", "poa_eptc.zip", "poa_trensurb.zip")), pasta)
      rede <- r5r::build_network(pasta, verbose = FALSE)
      if (is.null(rede)) stop("o r5r não conseguiu montar a rede (o motor R5 está faltando?)")
      pts <- read.csv(file.path(origem, "poa_points_of_interest.csv"))
      m <- r5r::travel_time_matrix(
        rede, origins = pts, destinations = pts, mode = c("WALK", "TRANSIT"),
        departure_datetime = as.POSIXct("13-05-2019 14:00:00", format = "%d-%m-%Y %H:%M:%S"),
        max_trip_duration = 60, progress = FALSE, verbose = FALSE
      )
      r5r::stop_r5(rede)
      nrow(m)
    }, timeout = 900))
    r5r_ok <- !inherits(teste_r5r$resultado, "falha") && teste_r5r$resultado > 0
    if (r5r_ok) {
      message(sprintf("r5r: ok (%.0f s, %d pares origem-destino). Transporte público funciona.",
                      teste_r5r$segundos, teste_r5r$resultado))
    } else {
      message("r5r: FALHOU. ", if (inherits(teste_r5r$resultado, "falha")) teste_r5r$resultado else
                "a matriz veio vazia.")
      message("  Copie a mensagem acima e abra uma issue, ou leve para o encontro síncrono.")
    }
  } else if (!java_ok) {
    message("r5r: teste pulado, porque falta o Java 21 (veja acima).")
  }

  # 5. conferência ----
  titulo("Conferência")
  if (length(falharam) == 0 && length(faltam_dados) == 0 && java_ok && dodgr_ok && r5r_ok) {
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
    if (!dodgr_ok) message("\nO teste do dodgr falhou (veja acima).")
    if (java_ok && !isTRUE(r5_jar$ok)) {
      message("\nFalta o motor R5 do r5r: baixe o .jar à mão (veja acima).")
    } else if (java_ok && !r5r_ok) {
      message("\nO teste do r5r falhou (veja acima).")
    }
  }
})
