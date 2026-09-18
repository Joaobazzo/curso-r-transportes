# Curso de R aplicado ao planejamento de transportes

Material do **Curso em linguagem de programação para análise de dados através do Software R**,
ofertado à Subsecretaria de Fomento e Planejamento do **Ministério dos Transportes**.

**Site:** <https://joaobazzo.github.io/curso-r-transportes/>

30 horas, 5 módulos semanais de 6h (3h síncronas + 3h assíncronas), formato on-line.

| Módulo | Tema | Estudo de caso |
|:--:|:--|:--|
| 1 | Fundamentos de R e manipulação de dados | TKU da cabotagem (ANTAQ) |
| 2 | Objetos espaciais: vetores e rasters | Faixa de influência da BR-116 (Serra do Mar) |
| 3 | Integração de bases, roteamento e matrizes OD | Fluxos de cabotagem no mapa do Brasil |
| 4 | Geoestatística, sensoriamento remoto e acessibilidade | Declividade × traçado; acessibilidade em Fortaleza |
| 5 | Mapas temáticos, relatórios reproduzíveis e projeto final | Relatório parametrizado; projeto final |

## Estrutura do repositório

```
.
├── _quarto.yml              # configuração do livro (navegação, formato)
├── index.qmd                # apresentação e cronograma
├── m1-*.qmd                 # capítulos do módulo 1
├── m2-*.qmd … m5-*.qmd      # capítulos dos módulos 2 a 5
├── a-dados.qmd              # dicionário e fontes dos dados
├── a-slides.qmd             # slides e gravações
├── a-recursos.qmd           # referências
├── dados/                   # bases de exemplo (pequenas)
├── slides/                  # apresentações das aulas
├── R/                       # scripts auxiliares
└── .github/workflows/       # publicação automática no GitHub Pages
```

## Dados

Os dados de exemplo pequenos estão em `dados/` e vão para o repositório. Os demais são
baixados pelo próprio código na primeira execução e guardados em `dados/brutos/`, que está no
`.gitignore` — malhas do IBGE (`geobr`), grade estatística, OpenStreetMap (`osmdata`),
altimetria (`elevatr`) e acessibilidade (`aopdata`).

Exigem preparo manual apenas os blocos do `r5r` (módulo 4), que precisam do **JDK 21** e de uma
pasta com o `.pbf` do OSM e o GTFS da cidade; esses blocos estão marcados como não executados.

## Como renderizar localmente

Requisitos: [R](https://cran.r-project.org/) (4.4+), [Quarto](https://quarto.org/docs/download/)
e, no Windows, [Rtools](https://cran.r-project.org/bin/windows/Rtools/).

```bash
# instalar os pacotes do módulo 1
Rscript -e 'source("R/instalar_pacotes.R")'

# renderizar o site inteiro em _site/
quarto render

# visualizar com recarga automática
quarto preview
```

O projeto usa `execute: freeze: auto`. Isso significa que:

1. Os blocos de código são executados **na sua máquina**, e o resultado é gravado em
   `_freeze/`.
2. O `_freeze/` **deve ser versionado** (`git add _freeze`).
3. O GitHub Actions apenas remonta o site a partir desse cache, sem precisar instalar R nem
   os pacotes espaciais — o que torna a publicação rápida e estável.

Fluxo de trabalho para publicar uma atualização:

```bash
quarto render
git add -A
git commit -m "atualiza módulo X"
git push
```

## Publicação

O workflow `.github/workflows/publish.yml` renderiza e publica em GitHub Pages a cada `push`
na branch `main`. Na primeira vez, no GitHub: **Settings > Pages > Build and deployment >
Source: GitHub Actions**.

## Dúvidas

Abra uma [issue](https://github.com/Joaobazzo/curso-r-transportes/issues) com o código, a
mensagem de erro completa e a saída de `sessionInfo()`.

## Licença

Material didático: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.pt-br).
Código: MIT. Os dados redistribuídos em `dados/` são públicos e pertencem às respectivas
fontes (ANTAQ, IBGE, MDIC).
