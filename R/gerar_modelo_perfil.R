# ------------------------------------------------------------------
# gerar_modelo_perfil.R
# Gera modelos/modelo_perfil.qmd, o modelo parametrizado do capítulo
# "Relatórios parametrizados", a partir do capítulo "Um relatório municipal:
# Paranaguá" (m5-03a-relatorio-municipal.qmd). O modelo é o próprio capítulo,
# da seção "Território" até antes de "Do relatório ao modelo", com o bloco que
# fixa o município trocado pelos parâmetros. Assim os dois nunca divergem.
#   Uso, na raiz do projeto:  Rscript R/gerar_modelo_perfil.R
# Rode de novo sempre que editar o capítulo de Paranaguá.
# ------------------------------------------------------------------

capitulo <- readLines("m5-03a-relatorio-municipal.qmd", encoding = "UTF-8")

ini <- grep("^## Território", capitulo)
fim <- grep("^## Do relatório ao modelo", capitulo) - 1
stopifnot(length(ini) == 1, length(fim) == 1, fim > ini)
corpo <- capitulo[ini:fim]
while (!nzchar(trimws(corpo[length(corpo)]))) corpo <- corpo[-length(corpo)]

cabecalho <- c(
  "---",
  'title: "Perfil municipal: `r params$municipio` (`r params$uf`)"',
  "lang: pt",
  "format:",
  "  html:",
  "    embed-resources: true",
  "    toc: true",
  "execute:",
  "  warning: false",
  "  message: false",
  "params:",
  '  municipio: "Paranaguá"',
  '  uf: "PR"',
  "---",
  "",
  "<!-- Gerado por R/gerar_modelo_perfil.R a partir de m5-03a-relatorio-municipal.qmd.",
  "     Para mudar o relatório, edite o capítulo e gere este arquivo de novo. -->",
  "",
  "```{r}",
  "library(dplyr)",
  "library(ggplot2)",
  "",
  "# o município vem dos parâmetros do cabeçalho (ou de execute_params, no quarto_render)",
  "municipio <- params$municipio",
  "uf        <- params$uf",
  "",
  "# o código IBGE: a chave que liga geobr, censobr e SIDRA",
  "codigo <- geobr::lookup_muni(name_muni = municipio, year = 2022) |>",
  "  dplyr::filter(abbrev_state == uf) |>",
  "  dplyr::pull(code_muni)",
  "```",
  ""
)

dir.create("modelos", showWarnings = FALSE)
writeLines(enc2utf8(c(cabecalho, corpo)), "modelos/modelo_perfil.qmd", useBytes = TRUE)
message("modelos/modelo_perfil.qmd: ", length(cabecalho) + length(corpo), " linhas")
