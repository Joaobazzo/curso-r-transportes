# ------------------------------------------------------------------
# rodar_todas.R
# Renderiza o relatório do projeto final para as cinco cidades de
# data_raw/projeto_final/, a partir do mesmo R/projeto_final/relatorio.qmd.
#
# Uso, na raiz do projeto do curso:
#   Rscript R/projeto_final/rodar_todas.R                 # as cinco
#   Rscript R/projeto_final/rodar_todas.R sao_paulo       # só uma
#   Rscript R/projeto_final/rodar_todas.R --recalcular    # refaz o r5r
#
# Pré-requisitos: Java 21 (JAVA_HOME), Quarto, os pacotes r5r, gtfstools,
# accessibility, stplanr, mapgl, sf, dplyr, ggplot2, e a pasta
# data_raw/projeto_final/ (R/preparar_projeto_final.R).
#
# Saídas:
#   R/projeto_final/html/relatorio_{cidade}.html   os relatórios
#   R/projeto_final/saidas/{cidade}/*.rds          os resultados do r5r
# ------------------------------------------------------------------

args <- commandArgs(trailingOnly = TRUE)
recalcular <- "--recalcular" %in% args
args <- setdiff(args, "--recalcular")

source("R/projeto_final/cidades.R", encoding = "UTF-8")
alvo <- if (length(args)) args else names(cidades)
stopifnot(all(alvo %in% names(cidades)))

resumo <- data.frame(cidade = alvo, ok = NA, minutos = NA_real_, mb = NA_real_)
for (i in seq_along(alvo)) {
  cid <- alvo[i]
  message("\n=== ", cid, " ===")
  inicio <- Sys.time()
  # o título com o nome da cidade, num arquivo (acentos na linha de comando falham no Windows)
  meta <- file.path(tempdir(), paste0("meta_", cid, ".yml"))
  writeLines(enc2utf8(sprintf('title: "Acessibilidade a empregos em %s"', cidades[[cid]]$nome)),
             meta, useBytes = TRUE)
  # o Quarto roda dentro da pasta do relatório. Cada render é um processo R novo:
  # a JVM do r5r começa limpa em cada cidade
  raiz <- setwd("R/projeto_final")
  status <- system2("quarto", c("render", "relatorio.qmd",
                                "-P", paste0("cidade:", cid),
                                "-P", paste0("recalcular:", tolower(recalcular)),
                                "--metadata-file", shQuote(normalizePath(meta, "/")),
                                "--output", paste0("relatorio_", cid, ".html")))
  setwd(raiz)
  # o log do r5r fica preso pela JVM até o fim do processo: apaga aqui
  unlink(file.path("data_raw/projeto_final", cid, "r5r-log.log"))
  html <- file.path("R/projeto_final/html", paste0("relatorio_", cid, ".html"))
  resumo$ok[i] <- status == 0 && file.exists(html)
  resumo$minutos[i] <- round(as.numeric(difftime(Sys.time(), inicio, units = "mins")), 1)
  if (file.exists(html)) resumo$mb[i] <- round(file.size(html) / 1e6, 1)
}

print(resumo, row.names = FALSE)
if (!all(resumo$ok)) quit(status = 1)
