# ------------------------------------------------------------------
# gerar_resultados_projeto_final.R
# Gera os arquivos da seção "Resultados" do projeto final (m5-04-projeto.qmd):
# para cada uma das cinco cidades, um script de roteamento e um relatório.
#
#   recursos/projeto_final/roteamento_{cidade}.R   -> dados/projeto_final/{cidade}/*.rds
#   recursos/projeto_final/relatorio_{cidade}.qmd  -> o relatório final
#   recursos/projeto_final/projeto_final_resultados.zip   (os dez arquivos)
#
# Os dois modelos estão em R/projeto_final/modelos/; os parâmetros de cada
# cidade, em R/projeto_final/cidades.R (os mesmos dos LEIA-ME dos pacotes).
#
# Uso, na raiz do projeto:  Rscript R/gerar_resultados_projeto_final.R
# ------------------------------------------------------------------

source("R/projeto_final/cidades.R", encoding = "UTF-8")

modelo_r   <- readLines("R/projeto_final/modelos/roteamento.R", encoding = "UTF-8")
modelo_qmd <- readLines("R/projeto_final/modelos/relatorio.qmd", encoding = "UTF-8")

destino <- "recursos/projeto_final"
dir.create(destino, recursive = TRUE, showWarnings = FALSE)

# memória da JVM: 2 GB bastam para Fortaleza; as outras foram testadas com 8 GB.
# Tempo do cálculo: o info.rds dos testes das cinco cidades (r5r 2.4.0)
memoria <- c(fortaleza = "-Xmx2G", belo_horizonte = "-Xmx8G", porto_alegre = "-Xmx8G",
             rio_de_janeiro = "-Xmx8G", sao_paulo = "-Xmx8G")
tempo   <- c(fortaleza = "uns 3 minutos", belo_horizonte = "uns 6 minutos",
             porto_alegre = "uns 5 minutos", rio_de_janeiro = "uns 10 minutos",
             sao_paulo = "uns 20 minutos")

# "de Messejana", mas "da Restinga" e "da Cidade Tiradentes"
de_bairro <- c(fortaleza = "de", belo_horizonte = "de", porto_alegre = "da",
               rio_de_janeiro = "de", sao_paulo = "da")

preencher <- function(texto, valores) {
  for (chave in names(valores)) {
    texto <- gsub(paste0("{{", chave, "}}"), valores[[chave]], texto, fixed = TRUE)
  }
  restou <- grep("\\{\\{[A-Z_]+\\}\\}", texto, value = TRUE)
  if (length(restou)) stop("Marcador sem valor: ", restou[1])
  texto
}

arquivos <- character()
for (cid in names(cidades)) {
  cfg <- cidades[[cid]]
  partida <- as.POSIXct(cfg$partida, tz = cfg$fuso)
  feminino <- cfg$centro$genero == "f"

  valores <- list(
    CIDADE = cid, NOME = cfg$nome,
    PARTIDA = cfg$partida, FUSO = cfg$fuso, DATA = format(partida, "%d/%m/%Y"),
    DIA = c("num domingo", "numa segunda-feira", "numa terça-feira", "numa quarta-feira",
            "numa quinta-feira", "numa sexta-feira", "num sábado")[as.POSIXlt(partida)$wday + 1],
    CENTRO_NOME = cfg$centro$nome, CENTRO_LON = cfg$centro$lon, CENTRO_LAT = cfg$centro$lat,
    BAIRRO_NOME = cfg$bairro$nome, BAIRRO_LON = cfg$bairro$lon, BAIRRO_LAT = cfg$bairro$lat,
    DA = if (feminino) "da" else "do", AO = if (feminino) "à" else "ao",
    DE_BAIRRO = de_bairro[[cid]],
    # "de Fortaleza", "em Fortaleza", mas "do Rio de Janeiro", "no Rio de Janeiro"
    DE_NOME = paste(if (cid == "rio_de_janeiro") "do" else "de", cfg$nome),
    EM_NOME = paste(if (cid == "rio_de_janeiro") "no" else "em", cfg$nome),
    MEMORIA = memoria[[cid]], TEMPO = tempo[[cid]],
    LIMITACOES = paste0("- ", cfg$limitacoes, collapse = "\n")
  )

  f_r   <- file.path(destino, paste0("roteamento_", cid, ".R"))
  f_qmd <- file.path(destino, paste0("relatorio_", cid, ".qmd"))
  writeLines(enc2utf8(preencher(modelo_r, valores)), f_r, useBytes = TRUE)
  writeLines(enc2utf8(preencher(modelo_qmd, valores)), f_qmd, useBytes = TRUE)
  arquivos <- c(arquivos, f_r, f_qmd)
}

# todos num zip só, para baixar de uma vez
zip <- file.path(destino, "projeto_final_resultados.zip")
unlink(zip)
utils::zip(zip, files = arquivos, flags = "-j9X")   # -j: sem as pastas

message("Gerados em ", destino, ":")
print(file.info(list.files(destino, full.names = TRUE))[, "size", drop = FALSE])
