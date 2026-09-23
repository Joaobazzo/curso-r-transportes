# ------------------------------------------------------------------
# fluxograma_curso.R
# Fluxograma didático do curso inteiro, com DiagrammeR: cada módulo
# vira um "cartão" (tabela HTML do Graphviz) com seus capítulos, na
# ordem do _quarto.yml. Estudos de caso ganham destaque (★, cor
# cheia); exercícios e capítulos-ponte ficam em itálico.
#
#   No RStudio:   source("R/fluxograma_curso.R")   # abre no Viewer
#   No terminal:  Rscript -e 'source("R/fluxograma_curso.R")'
#                 # também salva img/fluxograma_curso.svg e .png
# ------------------------------------------------------------------

if (!requireNamespace("DiagrammeR", quietly = TRUE)) {
  stop("Instale primeiro: install.packages('DiagrammeR')")
}

# ---- 1. O conteúdo do curso, na mesma ordem do _quarto.yml --------
# tipo: geral | conteudo | estudo_caso | exercicios | ponte
# "ponte" = capítulo extra que conecta módulos (ex.: Git, funções)

capitulos <- data.frame(
  modulo = c(
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    2, 2, 2, 2, 2, 2, 2, 2, 2,
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
    4, 4, 4, 4, 4, 4, 4,
    5, 5, 5, 5, 5, 5, 5
  ),
  label = c(
    "Visão geral", "Ambiente de trabalho", "A linguagem R", "Datas e textos",
    "Manipulação de dados", "Limpeza de dados", "Joins", "Visualização com ggplot2",
    "★ TKU da cabotagem", "Modelo de 4 etapas (VISUM)", "Exercícios",

    "Visão geral", "O objeto sf", "Sistemas de coordenadas", "Operações geométricas",
    "Rasters com terra", "Geovisualização", "Bases públicas brasileiras",
    "★ Faixa da BR-116", "Exercícios",

    "Visão geral", "Dados do OpenStreetMap", "SQL com DuckDB",
    "Comex Stat: o join que some com SP", "De script a função", "Geocodificação",
    "Roteamento", "Matrizes OD", "★ Fluxos de cabotagem", "Exercícios",

    "Visão geral", "Autocorrelação espacial", "Interpolação", "★ Declividade viária",
    "Acessibilidade", "Roteamento com r5r", "Exercícios",

    "Visão geral", "Mapas temáticos", "Relatórios com Quarto", "Git e GitHub",
    "Relatórios parametrizados", "★ Projeto final", "Próximos passos"
  ),
  tipo = c(
    "geral", "conteudo", "conteudo", "conteudo", "conteudo", "conteudo",
    "conteudo", "conteudo", "estudo_caso", "ponte", "exercicios",

    "geral", "conteudo", "conteudo", "conteudo", "conteudo", "conteudo",
    "conteudo", "estudo_caso", "exercicios",

    "geral", "conteudo", "conteudo", "ponte", "ponte", "conteudo",
    "conteudo", "conteudo", "estudo_caso", "exercicios",

    "geral", "conteudo", "conteudo", "estudo_caso", "conteudo", "conteudo", "exercicios",

    "geral", "conteudo", "conteudo", "ponte", "conteudo", "estudo_caso", "exercicios"
  )
)

titulos_modulo <- c(
  "1" = "Módulo 1\nFundamentos de R",
  "2" = "Módulo 2\nVetores e rasters",
  "3" = "Módulo 3\nBases, roteamento,\nmatrizes OD",
  "4" = "Módulo 4\nGeoestatística e\nacessibilidade",
  "5" = "Módulo 5\nRelatórios e\nprojeto final"
)

estudo_caso_modulo <- c(
  "1" = "TKU da cabotagem (ANTAQ)",
  "2" = "Faixa de influência da BR-116",
  "3" = "Fluxos de cabotagem no mapa",
  "4" = "Declividade × traçado",
  "5" = "Relatório e projeto final"
)

# cor de cada módulo: a mesma paleta usada nas figuras do curso
cor_modulo <- c(
  "1" = "#1a5b8a", "2" = "#1a9850", "3" = "#e07b39",
  "4" = "#b3402a", "5" = "#6b4c9a"
)

escapar_html <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  gsub("<", "&lt;", gsub(">", "&gt;", x, fixed = TRUE), fixed = TRUE)
}

# ---- 2. Um "cartão" HTML por módulo, com seus capítulos ------------
cartao_modulo <- function(m) {
  cor <- cor_modulo[[as.character(m)]]
  bloco <- capitulos[capitulos$modulo == m, ]

  linhas <- vapply(seq_len(nrow(bloco)), function(i) {
    rotulo <- escapar_html(bloco$label[i])
    switch(bloco$tipo[i],
      estudo_caso = sprintf(
        '<tr><td align="left" bgcolor="%s"><font color="white" point-size="10"><b>%s</b></font></td></tr>',
        cor, rotulo),
      exercicios = sprintf(
        '<tr><td align="left"><font color="#666666" point-size="10"><i>%s</i></font></td></tr>', rotulo),
      ponte = sprintf(
        '<tr><td align="left"><font color="%s" point-size="10"><i>%s</i></font></td></tr>', cor, rotulo),
      geral = sprintf(
        '<tr><td align="left"><font color="#666666" point-size="10">%s</font></td></tr>', rotulo),
      sprintf('<tr><td align="left"><font point-size="10">%s</font></td></tr>', rotulo)
    )
  }, character(1))

  sprintf(
    '<<table border="1" cellborder="0" cellspacing="2" cellpadding="4" color="%s" bgcolor="white">
      <tr><td bgcolor="%s"><font color="white" point-size="13"><b>%s</b></font></td></tr>
      %s
    </table>>',
    cor, cor, gsub("\n", "<br/>", escapar_html(titulos_modulo[[as.character(m)]])),
    paste(linhas, collapse = "\n")
  )
}

# ---- 3. Monta o grafo: um nó-cartão por módulo, em cadeia ----------
nos_modulo <- vapply(1:5, function(m) {
  sprintf('  m%d [shape=plain label=%s];', m, cartao_modulo(m))
}, character(1))

arestas_modulo <- vapply(1:4, function(m) {
  sprintf('  m%d -> m%d [color="#888888" penwidth=1.4];', m, m + 1)
}, character(1))

dot <- sprintf('
digraph fluxograma_curso {
  graph [rankdir=TB, fontname="Helvetica", bgcolor="white", nodesep=0.4, ranksep=0.5];
  node  [fontname="Helvetica"];
  edge  [fontname="Helvetica", arrowsize=0.8];

  intro [shape=box style="rounded,filled" fillcolor="#5a5a5a" fontcolor="white"
         label="Apresentação  +  \\"Nem sempre é simples\\" (anedota)"];

%s

%s

  intro -> m1 [color="#5a5a5a" penwidth=1.4];

  apendices [shape=box style="rounded,filled" fillcolor="#8a8a8a" fontcolor="white"
             label="Apêndices\\nDados de exemplo · Slides · Recursos e referências"];
  m5 -> apendices [color="#888888" penwidth=1.4];
}
', paste(nos_modulo, collapse = "\n"), paste(arestas_modulo, collapse = "\n"))

# ---- 4. Renderiza --------------------------------------------------
grafico <- DiagrammeR::grViz(dot)
print(grafico)

# ---- 5. Exporta como imagem estática, para usar no site -----------
dir.create("img", showWarnings = FALSE)

if (requireNamespace("DiagrammeRsvg", quietly = TRUE) &&
    requireNamespace("rsvg", quietly = TRUE)) {
  svg <- DiagrammeRsvg::export_svg(grafico)
  writeLines(svg, "img/fluxograma_curso.svg")
  rsvg::rsvg_png("img/fluxograma_curso.svg", "img/fluxograma_curso.png",
                  width = 2200)
  message("Salvo: img/fluxograma_curso.svg e img/fluxograma_curso.png")
} else {
  message("Para exportar como imagem, instale: ",
          "install.packages(c('DiagrammeRsvg', 'rsvg'))")
}
