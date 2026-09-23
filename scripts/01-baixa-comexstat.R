# -----------------------------------------------------------------------------
# Baixa as bases completas do Comex Stat (MDIC) e as tabelas de correspondencia.
#
# Saida: dados/brutos/comexstat/   (fora do repositorio, ver .gitignore)
# Rode a partir da raiz do projeto:  source("scripts/01-baixa-comexstat.R")
#
# ATENCAO: sao arquivos grandes (alguns milhoes de linhas por ano). O download
# acontece uma vez; nas execucoes seguintes o script le do cache local.
# -----------------------------------------------------------------------------

anos   <- 2023:2024          # ajuste conforme a necessidade
fluxos <- c("EXP", "IMP")

raiz_dados   <- "https://balanca.economia.gov.br/balanca/bd/comexstat-bd"
raiz_tabelas <- "https://balanca.economia.gov.br/balanca/bd/tabelas"
destino      <- "dados/brutos/comexstat"

dir.create(destino, recursive = TRUE, showWarnings = FALSE)

# -----------------------------------------------------------------------------
# 1. Download com cache
# -----------------------------------------------------------------------------

baixa_se_preciso <- function(url, arquivo) {
  caminho <- file.path(destino, arquivo)
  if (file.exists(caminho) && file.size(caminho) > 0) {
    message("cache:     ", arquivo)
    return(invisible(caminho))
  }
  message("baixando:  ", arquivo)
  utils::download.file(url, caminho, mode = "wb", quiet = TRUE)
  # O servidor devolve uma pagina de erro em PHP quando o caminho nao existe,
  # e download.file nao reclama. Conferir o primeiro byte e obrigatorio.
  if (startsWith(readLines(caminho, n = 1, warn = FALSE), "<")) {
    file.remove(caminho)
    stop("O servidor devolveu HTML/PHP em vez de CSV: ", url)
  }
  invisible(caminho)
}

# Base por NCM: tem UF, via de transporte e URF, mas NAO tem municipio.
for (ano in anos) for (fl in fluxos) {
  baixa_se_preciso(sprintf("%s/ncm/%s_%d.csv", raiz_dados, fl, ano),
                   sprintf("%s_%d.csv", fl, ano))
}

# Base municipal: tem municipio, mas so ate SH4 e SEM via de transporte.
for (ano in anos) for (fl in fluxos) {
  baixa_se_preciso(sprintf("%s/mun/%s_%d_MUN.csv", raiz_dados, fl, ano),
                   sprintf("%s_%d_MUN.csv", fl, ano))
}

# Tabelas de correspondencia. Repare que NAO ficam sob comexstat-bd/,
# e sim direto em bd/tabelas/.
for (tb in c("NCM", "UF", "UF_MUN", "PAIS", "VIA", "URF")) {
  baixa_se_preciso(sprintf("%s/%s.csv", raiz_tabelas, tb), sprintf("tab_%s.csv", tb))
}

# -----------------------------------------------------------------------------
# 2. Leitura com os tipos declarados
#
# REGRA DE OURO desta base: todo campo que comeca com CO_ e' CODIGO, nao numero.
#   CO_MES = "02"   CO_VIA = "04"   CO_URF = "0817600"
# Se o R inferir como numerico, o zero a esquerda some e o join com a tabela de
# correspondencia falha EM SILENCIO para todos esses codigos.
# -----------------------------------------------------------------------------

le_comex <- function(arquivo) {
  caminho   <- file.path(destino, arquivo)
  cabecalho <- strsplit(gsub('"', "", readLines(caminho, n = 1)), ";")[[1]]
  tipos     <- ifelse(grepl("^(CO_|SG_|NO_|SH)", cabecalho), "c", "d")
  readr::read_delim(
    caminho,
    delim = ";", quote = '"',
    col_types = paste(tipos, collapse = ""),
    locale = readr::locale(encoding = "latin1"),
    progress = FALSE
  )
}

# -----------------------------------------------------------------------------
# 3. Conversao para Parquet (leitura muito mais rapida nos capitulos)
# -----------------------------------------------------------------------------

converte_parquet <- function(arquivo) {
  saida <- file.path(destino, sub("\\.csv$", ".parquet", arquivo))
  if (file.exists(saida)) return(invisible(saida))

  con <- duckdb::dbConnect(duckdb::duckdb())
  on.exit(duckdb::dbDisconnect(con, shutdown = TRUE), add = TRUE)

  # all_varchar = todos os campos como texto: preserva os zeros a esquerda.
  DBI::dbExecute(con, sprintf(
    "COPY (SELECT * FROM read_csv('%s', delim=';', header=true, all_varchar=true))
     TO '%s' (FORMAT PARQUET)",
    normalizePath(file.path(destino, arquivo), winslash = "/"),
    normalizePath(saida, winslash = "/", mustWork = FALSE)))
  invisible(saida)
}

invisible(lapply(list.files(destino, pattern = "\\.csv$"), converte_parquet))

message("Pronto. Arquivos em ", normalizePath(destino))
message("Tamanho total: ",
        round(sum(file.size(list.files(destino, full.names = TRUE))) / 1024^2), " MB")

# -----------------------------------------------------------------------------
# 4. O que da e o que nao da para cruzar
#
#   EXP_2024.csv      CO_ANO CO_MES CO_NCM CO_UNID CO_PAIS SG_UF_NCM CO_VIA
#                     CO_URF QT_ESTAT KG_LIQUIDO VL_FOB
#   EXP_2024_MUN.csv  CO_ANO CO_MES SH4 CO_PAIS SG_UF_MUN CO_MUN
#                     KG_LIQUIDO VL_FOB
#
# NAO existe municipio + via de transporte na mesma tabela. Para origem de carga
# por modo, so da por UF, e declarando a hipotese no relatorio.
# A base municipal tambem nao tem QT_ESTAT (quantidade estatistica).
#
# Chaves de juncao:
#   CO_PAIS -> tab_PAIS.csv    (CO_PAIS)
#   CO_VIA  -> tab_VIA.csv     (CO_VIA)
#   CO_URF  -> tab_URF.csv     (CO_URF)
#   CO_NCM  -> tab_NCM.csv     (CO_NCM)
#   CO_MUN  -> tab_UF_MUN.csv  (CO_MUN_GEO)   <- nomes de coluna diferentes
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# 5. De-para do codigo de municipio: Comex Stat -> IBGE
#
# O campo CO_MUN da base municipal (e CO_MUN_GEO da tabela UF_MUN) NAO e' o
# codigo do IBGE, apesar do nome. Os cinco ultimos digitos sao iguais; o que
# muda e' o prefixo de UF, e so em quatro unidades da federacao:
#
#     UF   Comex   IBGE
#     SP     34      35
#     MS     52      50
#     GO     53      52
#     DF     54      53
#
# As outras 23 UFs coincidem. Por isso o join direto "funciona": casa cerca de
# 90% das linhas, nao devolve erro nenhum, e faz Sao Paulo (o maior exportador
# do pais), Goias, Mato Grosso do Sul e o Distrito Federal desaparecerem.
#
# Ha ainda dois codigos especiais, sem correspondencia territorial:
#     93 = EX (exportacao/importacao nao atribuida a municipio)
#     99 = ND (nao declarado)
# -----------------------------------------------------------------------------

prefixo_comex_para_ibge <- c(
  "34" = "35",   # Sao Paulo
  "52" = "50",   # Mato Grosso do Sul
  "53" = "52",   # Goias
  "54" = "53"    # Distrito Federal
)

co_mun_comex_para_ibge <- function(co_mun) {
  co_mun <- as.character(co_mun)
  prefixo <- substr(co_mun, 1, 2)
  sufixo  <- substr(co_mun, 3, 7)

  novo <- prefixo_comex_para_ibge[prefixo]
  prefixo <- ifelse(is.na(novo), prefixo, novo)

  resultado <- paste0(prefixo, sufixo)
  # 93 (EX) e 99 (ND) nao sao territorio: viram NA de proposito.
  resultado[substr(co_mun, 1, 2) %in% c("93", "99")] <- NA_character_
  resultado
}

# Teste embutido: Betim nao muda, Jundiai muda.
stopifnot(
  co_mun_comex_para_ibge("3106705") == "3106705",   # Betim/MG
  co_mun_comex_para_ibge("3425904") == "3525904",   # Jundiai/SP
  is.na(co_mun_comex_para_ibge("9300000"))
)
