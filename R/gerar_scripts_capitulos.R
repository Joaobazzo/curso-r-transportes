# ------------------------------------------------------------------
# gerar_scripts_capitulos.R
# Extrai TODO o código R de cada capítulo para um script próprio em
# scripts/, para rodar fora do site, um capítulo por vez.
#   No RStudio:  source("R/gerar_scripts_capitulos.R")
#
# Regras:
#   - todos os blocos {r} entram como código, inclusive os que o site
#     não executa (`eval: false`). Esses levam um aviso logo acima:
#     alguns exigem o Java 21, baixam arquivos grandes ou são trechos
#     ilustrativos que dependem de objetos criados antes;
#   - blocos com `error: true` entram dentro de try(), porque o erro é
#     proposital.
# Os scripts são cópias: depois de editar um capítulo, rode este de novo.
# ------------------------------------------------------------------

# todos os capítulos do livro, na ordem do _quarto.yml
yml <- readLines("_quarto.yml", encoding = "UTF-8")
capitulos <- regmatches(yml, regexpr("[a-z0-9-]+[.]qmd", yml))

# reaproveita extrair_blocos() do gerar_r_teste.R
src <- readLines("R/gerar_r_teste.R", encoding = "UTF-8")
ini <- grep("^extrair_blocos <- function", src)
fim <- grep("^formatar_bloco <- function", src) - 1
eval(parse(text = src[ini:fim], encoding = "UTF-8"))

formatar <- function(b) {
  cod <- b$codigo
  while (length(cod) > 0 && !nzchar(trimws(cod[length(cod)]))) cod <- cod[-length(cod)]
  if (length(cod) == 0) return(character())
  aviso <- if (!b$eval) "# [não roda no site (eval: false): pode exigir Java, download grande ou objetos anteriores]"
  if (b$erro) {
    return(c(aviso, "# [o erro deste bloco é proposital]", "try({", cod, "})"))
  }
  c(aviso, cod)
}

dir.create("scripts", showWarnings = FALSE)

for (arq in capitulos) {
  qmd <- readLines(arq, encoding = "UTF-8")
  titulo <- sub("\\s*\\{.*\\}\\s*$", "", sub("^#\\s*", "", grep("^# ", qmd, value = TRUE)[1]))
  blocos <- extrair_blocos(arq)
  if (length(blocos) == 0) next          # capítulo sem código R
  n_off <- sum(!vapply(blocos, `[[`, logical(1), "eval"))

  # script de preparação do módulo, quando existe (m3-... -> R/preparar_modulo3.R)
  modulo <- regmatches(arq, regexpr("(?<=^m)[0-9]", arq, perl = TRUE))
  preparo <- if (length(modulo)) sprintf("R/preparar_modulo%s.R", modulo) else ""
  linhas_preparo <- if (file.exists(preparo)) c(
    sprintf("# depois de rodar uma vez o script de preparação do módulo %s:", modulo),
    sprintf("#   source(\"%s\")", preparo))

  saida <- c(
    "# ------------------------------------------------------------------",
    sprintf("# %s: código do capítulo \"%s\"", sub("qmd$", "R", arq), gsub("`", "", titulo)),
    sprintf("# Extraído de %s em %s por R/gerar_scripts_capitulos.R.", arq,
            format(Sys.Date(), "%d/%m/%Y")),
    "#",
    "# Todo o código citado no capítulo, na ordem do texto.",
    "# Rode a partir da raiz do projeto (abra o curso-r-transportes.Rproj)",
    linhas_preparo,
    if (n_off > 0) c(
      "#",
      sprintf("# %d bloco(s) não rodam no site e estão marcados com \"[não roda no site]\":", n_off),
      "# alguns exigem o Java 21, baixam arquivos grandes ou são trechos que",
      "# dependem de objetos criados antes. Rode bloco a bloco, conferindo."),
    "# ------------------------------------------------------------------"
  )
  secao_ant <- ""
  for (b in blocos) {
    linhas <- formatar(b)
    if (length(linhas) == 0) next
    if (b$secao != secao_ant) {
      saida <- c(saida, "", sprintf("# ---- %s ----", sub("^#+\\s*", "", b$secao)))
      secao_ant <- b$secao
    }
    saida <- c(saida, "", linhas)
  }
  destino <- file.path("scripts", sub("qmd$", "R", arq))
  writeLines(enc2utf8(saida), destino, useBytes = TRUE)

  # confere se o script é R válido (sem rodar nada)
  ok <- tryCatch({ parse(destino, encoding = "UTF-8"); TRUE }, error = function(e) conditionMessage(e))
  message(sprintf("%-31s %4d linhas, %2d blocos (%2d não rodam no site) | sintaxe: %s",
                  destino, length(saida), length(blocos), n_off, if (isTRUE(ok)) "ok" else ok))
}
