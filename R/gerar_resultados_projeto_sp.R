# ------------------------------------------------------------------
# gerar_resultados_projeto_sp.R
# Gera os resultados da página "Projeto final 2: São Paulo"
# (m5-04b-projeto-sp.qmd) rodando, na ordem e numa só sessão, os blocos
# da própria página: o de rótulo "setup" e todos os de rótulo "calc-".
# Assim, o que a página mostra saiu exatamente do código que ela exibe.
#
# Pré-requisitos: Java 21 (JAVA_HOME), uns 8 GB livres para a JVM, a pasta
# data_raw/projeto_final/sao_paulo/ (Release dados-modulo5) e internet
# (o relevo é baixado com o elevatr, AWS Terrain Tiles).
#
# Uso, na raiz do projeto:  Rscript R/gerar_resultados_projeto_sp.R
# Saída: dados/projeto_final_sp/*.rds (uns 45 minutos)
# Depois: quarto render m5-04b-projeto-sp.qmd
# ------------------------------------------------------------------

linhas <- readLines("m5-04b-projeto-sp.qmd", encoding = "UTF-8")

inicio <- grep("^```\\{r\\}", linhas)
blocos <- lapply(inicio, function(i) {
  j <- i + which(grepl("^```\\s*$", linhas[(i + 1):length(linhas)]))[1]
  corpo <- linhas[(i + 1):(j - 1)]
  rotulo <- sub("^#\\|\\s*label:\\s*", "", grep("^#\\|\\s*label:", corpo, value = TRUE))
  list(rotulo = if (length(rotulo)) trimws(rotulo) else "", codigo = corpo[!grepl("^#\\|", corpo)])
})
blocos <- Filter(function(b) b$rotulo == "setup" || startsWith(b$rotulo, "calc-"), blocos)
stopifnot(length(blocos) >= 2)

for (b in blocos) {
  message("\n=== ", b$rotulo, " (", format(Sys.time(), "%H:%M"), ") ===")
  eval(parse(text = b$codigo, encoding = "UTF-8"), envir = globalenv())
}

# a pasta de entrada volta a ter só os dados do pacote
unlink(list.files("data_raw/projeto_final/sao_paulo", pattern = "^network|\\.mapdb|gtfs_errors",
                  full.names = TRUE))
message("\nResultados em dados/projeto_final_sp/:")
print(file.info(list.files("dados/projeto_final_sp", full.names = TRUE))[, "size", drop = FALSE])
