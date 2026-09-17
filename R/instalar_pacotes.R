# ------------------------------------------------------------------
# instalar_pacotes.R
# Instala os pacotes usados no curso. Rode uma vez, antes do módulo 1.
# ------------------------------------------------------------------

pacotes_modulo1 <- c(
  "readr", "readxl", "writexl", "data.table", "duckplyr", "arrow",
  "dplyr", "tidyr", "stringr", "lubridate", "forcats", "janitor",
  "ggplot2", "scales", "patchwork", "classInt", "ggrepel",
  "knitr", "rmarkdown"
)

pacotes_espaciais <- c(
  "sf", "terra", "leaflet", "mapgl", "duckspatial",
  "geobr", "censobr", "sidrar", "geocodebr",
  "osmdata", "osmextract"
)

pacotes_transportes <- c(
  "r5r", "dodgr", "accessibility", "aopdata", "gtfstools", "Matrix", "duckdb"
)

instalar <- function(pacotes) {
  faltando <- setdiff(pacotes, rownames(installed.packages()))
  if (length(faltando) == 0) {
    message("Todos instalados: ", paste(pacotes, collapse = ", "))
  } else {
    message("Instalando: ", paste(faltando, collapse = ", "))
    install.packages(faltando)
  }
  invisible(faltando)
}

instalar(pacotes_modulo1)

# descomente conforme o curso avança
# instalar(pacotes_espaciais)
# instalar(pacotes_transportes)

# r5r exige Java 21; verifique com:
# rJava::.jinit(); rJava::.jcall("java/lang/System", "S", "getProperty", "java.version")
