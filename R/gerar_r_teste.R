# ------------------------------------------------------------------
# gerar_r_teste.R
# Extrai o código R dos capítulos de cada módulo para R_teste/, um
# script por módulo (ou dois, quando o módulo é grande). Serve para
# testar, de ponta a ponta e numa única sessão, o código ensinado.
#   No terminal:  Rscript R/gerar_r_teste.R
#   No RStudio:   source("R/gerar_r_teste.R")
#
# Regras:
#   - blocos executados no site entram como código;
#   - blocos com `eval: false` entram comentados (não rodam no site);
#   - blocos com `error: true` entram dentro de try(), porque o erro
#     é proposital.
# R_teste/ está no .gitignore: rode este script de novo depois de
# editar os capítulos.
# ------------------------------------------------------------------

modulos <- list(
  "modulo1a" = c("m1-00-visao-geral.qmd", "m1-01-ambiente.qmd", "m1-02-linguagem.qmd",
                 "m1-03-datas-strings.qmd", "m1-04-manipulacao.qmd", "m1-05-limpeza.qmd"),
  "modulo1b" = c("m1-06-joins.qmd", "m1-07-ggplot2.qmd", "m1-08-estudo-de-caso.qmd",
                 "m1-08b-modelo4etapas.qmd", "m1-09-exercicios.qmd"),
  "modulo2"  = c("m2-00-visao-geral.qmd", "m2-06-bases.qmd", "m2-01-sf.qmd", "m2-02-crs.qmd",
                 "m2-03-geometrias.qmd", "m2-04-raster.qmd", "m2-05-mapas.qmd",
                 "m2-07-estudo-de-caso.qmd", "m2-08-exercicios.qmd"),
  "modulo3"  = c("m3-00-visao-geral.qmd", "m3-01-osm.qmd", "m3-02-duckdb.qmd",
                 "m3-02b-comexstat.qmd", "m3-02c-funcoes.qmd", "m3-03-geocodificacao.qmd",
                 "m3-04-roteamento.qmd", "m3-05-matrizes.qmd", "m3-06-estudo-de-caso.qmd",
                 "m3-07-exercicios.qmd"),
  "modulo4"  = c("m4-00-visao-geral.qmd", "m4-01-autocorrelacao.qmd", "m4-02-interpolacao.qmd",
                 "m4-03-declividade.qmd", "m4-04-acessibilidade.qmd", "m4-05-r5r.qmd",
                 "m4-06-exercicios.qmd"),
  "modulo5"  = c("m5-00-visao-geral.qmd", "m5-01-mapas-tematicos.qmd", "m5-02-quarto.qmd",
                 "m5-02b-git.qmd", "m5-03-parametrizados.qmd", "m5-04-projeto.qmd",
                 "m5-05-proximos-passos.qmd")
)

# devolve uma lista de blocos: código, opções e título da seção em que está
extrair_blocos <- function(arquivo) {
  linhas <- readLines(arquivo, encoding = "UTF-8", warn = FALSE)
  blocos <- list()
  secao <- ""
  dentro <- FALSE
  exemplo <- FALSE     # dentro de ````: exemplo de markdown, não é código a rodar
  for (l in linhas) {
    if (!dentro && grepl("^````", l)) exemplo <- !exemplo
    if (exemplo) next
    if (!dentro && grepl("^#{1,3} ", l)) secao <- sub("\\s*\\{.*\\}\\s*$", "", l)
    if (!dentro && grepl("^```\\{r", l)) {
      dentro <- TRUE
      atual <- character()
      next
    }
    if (dentro && grepl("^```\\s*$", l)) {
      dentro <- FALSE
      opcoes <- grep("^#\\|", atual, value = TRUE)
      codigo <- atual[!grepl("^#\\|", atual)]
      blocos[[length(blocos) + 1]] <- list(
        codigo = codigo,
        eval   = !any(grepl("^#\\|\\s*eval:\\s*false", opcoes)),
        erro   = any(grepl("^#\\|\\s*error:\\s*true", opcoes)),
        secao  = secao
      )
      next
    }
    if (dentro) atual <- c(atual, l)
  }
  blocos
}

formatar_bloco <- function(b) {
  cod <- b$codigo
  while (length(cod) > 0 && !nzchar(trimws(cod[length(cod)]))) cod <- cod[-length(cod)]
  if (length(cod) == 0) return(character())
  if (!b$eval) {
    return(c("# [eval: false no site: não roda por padrão]",
             ifelse(nzchar(cod), paste0("# ", cod), "#")))
  }
  if (b$erro) {
    return(c("# [error: true no site: o erro é proposital]",
             "try({", cod, "})"))
  }
  cod
}

dir.create("R_teste", showWarnings = FALSE)

for (nome in names(modulos)) {
  saida <- c(
    "# ------------------------------------------------------------------",
    sprintf("# %s.R: gerado por R/gerar_r_teste.R em %s", nome, format(Sys.Date(), "%d/%m/%Y")),
    "# Rode a partir da raiz do projeto (abra o curso-r-transportes.Rproj).",
    "# Não edite à mão: edite os capítulos e gere de novo.",
    "# ------------------------------------------------------------------",
    ""
  )
  for (arq in modulos[[nome]]) {
    blocos <- extrair_blocos(arq)
    if (length(blocos) == 0) next
    saida <- c(saida, "", strrep("#", 70), sprintf("# %s", arq), strrep("#", 70))
    secao_ant <- ""
    for (b in blocos) {
      linhas <- formatar_bloco(b)
      if (length(linhas) == 0) next
      if (b$secao != secao_ant) {
        saida <- c(saida, "", sprintf("# ---- %s ----", sub("^#+\\s*", "", b$secao)))
        secao_ant <- b$secao
      }
      saida <- c(saida, "", linhas)
    }
  }
  writeLines(enc2utf8(saida), file.path("R_teste", paste0(nome, ".R")), useBytes = TRUE)
  message(sprintf("R_teste/%s.R: %d linhas", nome, length(saida)))
}
