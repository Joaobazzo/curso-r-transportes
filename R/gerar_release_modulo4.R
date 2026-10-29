# ------------------------------------------------------------------
# gerar_release_modulo4.R
# Monta releases/dados_modulo4.zip com os dados do Módulo 4, a partir
# dos arquivos que já estão em dados/brutos/ (não baixa nada).
# É esse zip que vai como asset do Release "dados-modulo4" no GitHub,
# e que o R/preparar_modulo4.R baixa para os alunos.
#
# Rode a partir da raiz do projeto:  source("R/gerar_release_modulo4.R")
#
# A malha do OSM é um recorte da região de Fortaleza (lon -38,75 a -38,29;
# lat -4,00 a -3,58: os hexágonos do AOP com uns 10 km de folga), tirado do
# extrato do Nordeste da Geofabrik:
#   https://download.geofabrik.de/south-america/brazil/nordeste-latest.osm.pbf
# O Nordeste inteiro (444 MB) deixa o build_network() do r5r lento e pesado
# demais. O R não grava .pbf; o recorte foi feito em Java, com o osm-lib que
# vem dentro do jar do R5 (TileOSMSource + setBoundingBox), e salvo como
# dados/brutos/fortaleza/fortaleza.osm.pbf (54 MB).
# ------------------------------------------------------------------

arquivos <- c(
  "dados/brutos/fortaleza/fortaleza.osm.pbf",
  "dados/brutos/fortaleza/gtfs_fortaleza.zip",
  "dados/brutos/aop_fortaleza.rds",
  "dados/brutos/rede_sao_paulo_santos.gpkg",
  "dados/brutos/portos_osm.gpkg",
  "dados/brutos/pontes_br116.gpkg"
)

faltam <- arquivos[!file.exists(arquivos)]
if (length(faltam) > 0) {
  stop("Faltam arquivos para o release:\n  ", paste(faltam, collapse = "\n  "),
       "\nO .pbf de Fortaleza é um recorte do Nordeste da Geofabrik (veja o topo deste script).", call. = FALSE)
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
  "dados/brutos/fortaleza/fortaleza.osm.pbf   malha viária da região de Fortaleza (OpenStreetMap,",
  "                                           recorte do extrato do Nordeste da Geofabrik).",
  "                                           O r5r monta a rede a partir dela em uns 2 minutos.",
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
