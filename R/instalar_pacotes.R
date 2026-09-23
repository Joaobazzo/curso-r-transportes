# ------------------------------------------------------------------
# instalar_pacotes.R
# Instala os pacotes usados no curso. Rode uma vez, antes do módulo 1.
#   No terminal:  Rscript -e 'source("R/instalar_pacotes.R")'
#   No RStudio:   source("R/instalar_pacotes.R")
# ------------------------------------------------------------------

# Define o espelho do CRAN. Necessário quando o script roda via Rscript,
# onde não há sessão interativa para perguntar qual espelho usar.
repo_atual <- getOption("repos")[["CRAN"]]
if (is.null(repo_atual) || is.na(repo_atual) || repo_atual %in% c("", "@CRAN@")) {
  options(repos = c(CRAN = "https://cloud.r-project.org"))
}

# Necessários para renderizar o módulo 1
pacotes_modulo1 <- c(
  "readr", "readxl", "writexl",
  "dplyr", "tidyr", "stringr", "lubridate", "forcats", "janitor",
  "ggplot2", "scales", "patchwork", "classInt", "ggrepel",
  "knitr", "rmarkdown"
)

# Usados apenas em exemplos não executados (eval: false) do módulo 1.
# Instale quando quiser reproduzir as comparações de desempenho.
pacotes_opcionais <- c("data.table", "duckplyr", "duckdb", "arrow", "skimr")

pacotes_espaciais <- c(
  "sf", "terra", "tidyterra", "leaflet", "mapview", "mapgl", "duckspatial",
  "geobr", "censobr", "sidrar", "geocodebr",
  "osmdata", "osmextract", "elevatr", "ggspatial", "units", "RColorBrewer"
)

# módulo 4: geoestatística e acessibilidade
pacotes_geoestatistica <- c("spdep", "gstat", "sp")

# módulo 5: relatórios
pacotes_relatorios <- c("quarto", "rmarkdown", "knitr", "gt")

pacotes_transportes <- c(
  "r5r", "dodgr", "accessibility", "aopdata", "gtfstools", "Matrix",
  "sfnetworks", "stplanr"
)

# módulo 3: bases grandes e SQL
pacotes_dados_grandes <- c("duckdb", "duckplyr", "DBI", "dbplyr", "data.table", "arrow")

instalar <- function(pacotes) {
  faltando <- setdiff(pacotes, rownames(installed.packages()))
  if (length(faltando) == 0) {
    message("Todos instalados: ", paste(pacotes, collapse = ", "))
  } else {
    message("Instalando: ", paste(faltando, collapse = ", "))
    install.packages(faltando)
    ainda <- setdiff(pacotes, rownames(installed.packages()))
    if (length(ainda) > 0) {
      warning("Falharam: ", paste(ainda, collapse = ", "), call. = FALSE)
    }
  }
  invisible(setdiff(pacotes, rownames(installed.packages())))
}

instalar(pacotes_modulo1)

# descomente conforme o curso avança
# instalar(pacotes_opcionais)          # módulo 1 (exemplos não executados)
# instalar(pacotes_espaciais)          # módulo 2
# instalar(pacotes_dados_grandes)      # módulo 3
# instalar(pacotes_transportes)        # módulos 3 e 4
# instalar(pacotes_geoestatistica)     # módulo 4
# instalar(pacotes_relatorios)         # módulo 5

# r5r exige Java 21; verifique com:
# rJava::.jinit(); rJava::.jcall("java/lang/System", "S", "getProperty", "java.version")
