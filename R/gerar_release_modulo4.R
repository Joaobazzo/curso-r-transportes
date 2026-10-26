# ------------------------------------------------------------------
# gerar_release_modulo4.R
# Monta releases/dados_modulo4.zip com os dados do Módulo 4, a partir
# dos arquivos que já estão em dados/brutos/ (não baixa nada).
# É esse zip que vai como asset do Release "dados-modulo4" no GitHub,
# e que o R/preparar_modulo4.R baixa para os alunos.
#
# Rode a partir da raiz do projeto:  source("R/gerar_release_modulo4.R")
#
# A malha do OSM é o extrato do Nordeste inteiro da Geofabrik (não há
# extrato só do Ceará, e o R não grava .pbf para recortar):
#   https://download.geofabrik.de/south-america/brazil/nordeste-latest.osm.pbf
# salvo como dados/brutos/fortaleza/nordeste.osm.pbf.
# ------------------------------------------------------------------

arquivos <- c(
  "dados/brutos/fortaleza/nordeste.osm.pbf",
  "dados/brutos/fortaleza/gtfs_fortaleza.zip",
  "dados/brutos/aop_fortaleza.rds",
  "dados/brutos/rede_sao_paulo_santos.gpkg",
  "dados/brutos/portos_osm.gpkg",
  "dados/brutos/pontes_br116.gpkg"
)

faltam <- arquivos[!file.exists(arquivos)]
if (length(faltam) > 0) {
  stop("Faltam arquivos para o release:\n  ", paste(faltam, collapse = "\n  "),
       "\nO .pbf do Nordeste vem da Geofabrik (endereço no topo deste script).", call. = FALSE)
}

leia_me <- c(
  "Dados do Módulo 4: Sensoriamento remoto e acessibilidade",
  "Curso de R aplicado ao planejamento de transportes",
  "https://github.com/Joaobazzo/curso-r-transportes",
  "",
  "COMO USAR",
  "O jeito mais simples é rodar o script de preparação do módulo, que baixa e descompacta",
  "este arquivo sozinho e confere o Java:",
  '  source("https://raw.githubusercontent.com/Joaobazzo/curso-r-transportes/main/R/preparar_modulo4.R")',
  "",
  "Para fazer à mão: descompacte este arquivo DENTRO da pasta do projeto do curso (a pasta",
  "que tem o arquivo curso-r-transportes.Rproj). Os arquivos vão para dados/brutos/.",
  "",
  "CONTEÚDO",
  "dados/brutos/fortaleza/nordeste.osm.pbf    malha viária do Nordeste (OpenStreetMap, extrato",
  "                                           da Geofabrik). O r5r monta a rede a partir dela:",
  "                                           reserve memória com -Xmx8G (veja o capítulo).",
  "dados/brutos/fortaleza/gtfs_fortaleza.zip  GTFS do transporte público de Fortaleza",
  "                                           A pasta fortaleza/ é a que o r5r lê.",
  "dados/brutos/aop_fortaleza.rds             acessibilidade em Fortaleza, 2019 (Ipea, aopdata)",
  "dados/brutos/rede_sao_paulo_santos.gpkg    malha viária São Paulo-Santos (OpenStreetMap),",
  "                                           para o OSM e o roteamento com dodgr",
  "dados/brutos/portos_osm.gpkg               portos mapeados no OpenStreetMap",
  "dados/brutos/pontes_br116.gpkg             pontes da BR-116 (OpenStreetMap)",
  "",
  "ATENÇÃO: VALIDADE DO GTFS",
  "O GTFS vale de 3 de abril a 3 de julho de 2026. O r5r só encontra ônibus em datas dentro",
  "desse período: para outra data, ele devolve tempos só de caminhada, sem dar erro.",
  "",
  "O QUE NÃO ESTÁ AQUI",
  "- Dados de Porto Alegre: vêm dentro do próprio pacote r5r.",
  "- O Java 21: o script de preparação mostra como instalar.",
  "",
  "FONTES E USO",
  "OpenStreetMap: (c) colaboradores do OpenStreetMap, licença ODbL.",
  "aopdata: Instituto de Pesquisa Econômica Aplicada (Ipea), dados públicos.",
  "GTFS de Fortaleza: Prefeitura de Fortaleza, dados abertos."
)

saida <- "releases/dados_modulo4.zip"
dir.create("releases", showWarnings = FALSE)
if (file.exists(saida)) file.remove(saida)

# o LEIA-ME vai na raiz do zip; os dados, com o caminho a partir da raiz do projeto
tmp <- file.path(tempdir(), "LEIA-ME.txt")
writeLines(enc2utf8(leia_me), tmp, useBytes = TRUE)
zip::zip(saida, files = arquivos, mode = "mirror")
zip::zip_append(saida, files = tmp, mode = "cherry-pick")

conteudo <- zip::zip_list(saida)
print(conteudo[, c("filename", "uncompressed_size")])
message("Release: ", normalizePath(saida), " (", round(file.size(saida) / 1e6, 1), " MB)")
