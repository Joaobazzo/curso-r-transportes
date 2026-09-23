# ------------------------------------------------------------------
# baixar_logos.R
# Baixa os hexágonos (hex stickers) dos pacotes mais usados no curso
# e salva em img/logos/<pacote>.png. Segue a convenção usethis::use_logo(),
# que guarda o hex em man/figures/logo.png no repositório do pacote.
# Pacotes sem hex sticker conhecido são ignorados, com aviso.
#   No terminal:  Rscript -e 'source("R/baixar_logos.R")'
# ------------------------------------------------------------------

dir.create("img/logos", recursive = TRUE, showWarnings = FALSE)

# pacote -> "dono/repositorio" no GitHub (convenção usethis::use_logo():
# man/figures/logo.png). Alguns pacotes fogem da convenção (empacotados
# num monorepo, nome de arquivo diferente etc.) -- ver `caminhos_especiais`.
repositorios <- c(
  dplyr         = "tidyverse/dplyr",
  tidyr         = "tidyverse/tidyr",
  ggplot2       = "tidyverse/ggplot2",
  stringr       = "tidyverse/stringr",
  readr         = "tidyverse/readr",
  readxl        = "tidyverse/readxl",
  lubridate     = "tidyverse/lubridate",
  scales        = "r-lib/scales",
  patchwork     = "thomasp85/patchwork",
  janitor       = "sfirke/janitor",
  writexl       = "ropensci/writexl",

  sf            = "r-spatial/sf",
  terra         = "rspatial/terra",
  units         = "r-quantities/units",
  mapview       = "r-spatial/mapview",
  leaflet       = "rstudio/leaflet",
  ggspatial     = "paleolimbot/ggspatial",
  classInt      = "r-spatial/classInt",
  gstat         = "r-spatial/gstat",
  spdep         = "r-spatial/spdep",

  geobr         = "ipeaGIT/geobr",
  censobr       = "ipeaGIT/censobr",
  aopdata       = "ipeaGIT/aopdata",
  r5r           = "ipeaGIT/r5r",
  gtfstools     = "ipeaGIT/gtfstools",
  accessibility = "ipeaGIT/accessibility",
  geocodebr     = "ipeaGIT/geocodebr",
  osmdata       = "ropensci/osmdata",
  osmextract    = "ropensci/osmextract",
  dodgr         = "UrbanAnalyst/dodgr",
  stplanr       = "ropensci/stplanr",

  DBI           = "r-dbi/DBI",
  gt            = "rstudio/gt",
  quarto        = "quarto-dev/quarto-r",
  knitr         = "yihui/knitr"
)

# pacote -> caminho exato do arquivo dentro do repositório, para quem foge
# da convenção padrão (geralmente pacotes do ipeaGIT vivem num monorepo,
# dentro de "r-package/")
caminhos_especiais <- c(
  geobr     = "r-package/man/figures/geobr_logo_y.png",
  aopdata   = "r-package/man/figures/logo.png",
  r5r       = "r-package/man/figures/logo.png",
  geocodebr = "r-package/man/figures/logo.png",
  janitor   = "man/figures/logo_small.png"
)

# confere a assinatura PNG (89 50 4E 47) ou o cabeçalho SVG: evita salvar
# página de erro do GitHub (404) como se fosse imagem
e_imagem_valida <- function(caminho) {
  if (!file.exists(caminho) || file.size(caminho) < 50) return(FALSE)
  inicio <- readBin(caminho, "raw", 5)
  png  <- identical(as.integer(inicio[1:4]), c(0x89L, 0x50L, 0x4EL, 0x47L))
  svg  <- identical(rawToChar(inicio[1:5]), "<?xml") || identical(rawToChar(inicio[1:4]), "<svg")
  png || svg
}

baixar_logo <- function(pacote, repo) {
  extensao_especial <- if (pacote %in% names(caminhos_especiais)) caminhos_especiais[[pacote]] else NULL
  extensao <- if (!is.null(extensao_especial)) sub(".*\\.", "", extensao_especial) else "png"
  destino <- file.path("img/logos", paste0(pacote, ".", extensao))
  if (file.exists(destino)) return(TRUE)

  caminhos <- if (!is.null(extensao_especial)) {
    extensao_especial
  } else {
    c("man/figures/logo.png", "man/figures/logo.svg")
  }

  for (branch in c("main", "master")) {
    for (caminho in caminhos) {
      url <- sprintf("https://raw.githubusercontent.com/%s/%s/%s", repo, branch, caminho)
      destino <- file.path("img/logos", paste0(pacote, ".", sub(".*\\.", "", caminho)))
      tryCatch(
        utils::download.file(url, destino, mode = "wb", quiet = TRUE),
        error = function(e) invisible(NULL), warning = function(w) invisible(NULL)
      )
      if (e_imagem_valida(destino)) return(TRUE)
      if (file.exists(destino)) file.remove(destino)
    }
  }
  FALSE
}

resultado <- vapply(names(repositorios), function(pkg) {
  ok <- baixar_logo(pkg, repositorios[[pkg]])
  message(if (ok) paste("OK:     ", pkg) else paste("FALHOU: ", pkg))
  ok
}, logical(1))

message("\n", sum(resultado), " de ", length(resultado), " logos baixados em img/logos/")
if (any(!resultado)) {
  message("Sem hex sticker encontrado: ", paste(names(resultado)[!resultado], collapse = ", "))
}
