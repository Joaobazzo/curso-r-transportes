# Curso de R aplicado ao planejamento de transportes

Material do **Curso em linguagem de programação para análise de dados através do Software R**,
ofertado à Subsecretaria de Fomento e Planejamento do **Ministério dos Transportes**.

**Site:** <https://joaobazzo.github.io/curso-r-transportes/>

30 horas, 5 módulos semanais de 6h (3h síncronas + 3h assíncronas), formato on-line.

| Módulo | Tema | Estudo de caso |
|:--:|:--|:--|
| 1 | Fundamentos de R e manipulação de dados | TKU da cabotagem (ANTAQ) |
| 2 | Objetos espaciais: vetores e rasters | Faixa de influência da BR-116 (Serra do Mar) |
| 3 | Integração de bases, roteamento e matrizes OD | Declividade × traçado; fluxos de cabotagem no mapa do Brasil |
| 4 | Sensoriamento remoto e acessibilidade | Acessibilidade em Fortaleza |
| 5 | Mapas temáticos, relatórios reproduzíveis e projeto final | Relatório parametrizado; projeto final |

## Estrutura do repositório

```
.
├── _quarto.yml              # configuração do livro (navegação, formato)
├── index.qmd                # apresentação e cronograma
├── m1-*.qmd                 # capítulos do módulo 1
├── m2-*.qmd … m5-*.qmd      # capítulos dos módulos 2 a 5
├── a-dados.qmd              # dicionário e fontes dos dados
├── a-recursos.qmd           # recursos e referências
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

# depois, a versão em inglês, em _site/en/ (sempre nesta ordem: o render do
# português limpa a pasta _site/)
quarto render en

# visualizar com recarga automática
quarto preview
```

### Versão em inglês

O site tem uma versão em inglês em `<site>/en/`, com a mesma página no mesmo nome de
arquivo: `m1-01-ambiente.html` ↔ `en/m1-01-ambiente.html`. Ela é um projeto Quarto à
parte, na pasta `en/`, com os capítulos traduzidos e o próprio `en/_quarto.yml`. O código roda
a partir da raiz do curso, então os caminhos `dados/...` são os mesmos. O botão de idioma, com
a bandeira, vem de `idioma.html`, incluído nos dois projetos.

Ao mudar um capítulo, mude também o arquivo de mesmo nome em `en/`. O cache da versão em
inglês fica em `en/_freeze/` e também deve ser versionado.

O projeto usa `execute: freeze: auto`. Isso significa que:

1. Os blocos de código são executados **na sua máquina**, e o resultado é gravado em
   `_freeze/`.
2. O `_freeze/` **deve ser versionado** (`git add _freeze en/_freeze`).
3. O GitHub Actions apenas remonta o site a partir desse cache, sem precisar instalar R nem
   os pacotes espaciais — o que torna a publicação rápida e estável.

Fluxo de trabalho para publicar uma atualização:

```bash
quarto render
quarto render en
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

## Como citar

Norma ABNT:

> VIEIRA, João Pedro Bazzo. **Análise de dados com R aplicada ao planejamento de transportes**.
> Brasília: Ministério dos Transportes, 2026. Material didático. Disponível em:
> <https://joaobazzo.github.io/curso-r-transportes/>. Acesso em: 25 nov. 2026.

Troque a data de acesso pela data em que você consultou o material.

BibTeX:

```bibtex
@misc{vieira2026cursoR,
  author       = {Vieira, Jo{\~a}o Pedro Bazzo},
  title        = {An{\'a}lise de Dados com {R} Aplicada ao Planejamento de Transportes},
  year         = {2026},
  publisher    = {Minist{\'e}rio dos Transportes},
  address      = {Bras{\'i}lia},
  howpublished = {\url{https://joaobazzo.github.io/curso-r-transportes/}},
  note         = {Material did{\'a}tico}
}
```

Versão em inglês (APA):

> Vieira, J. P. B. (2026). *Data analysis with R for transport planning* [Course material].
> Ministry of Transport, Brazil. <https://joaobazzo.github.io/curso-r-transportes/en/>

O arquivo [`CITATION.cff`](CITATION.cff) traz os mesmos dados. Com ele, o GitHub mostra o botão
**Cite this repository** na página do repositório.

## Licença

Texto, figuras e slides: [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/deed.pt_BR).
Código: MIT. Os dados mantêm os termos das respectivas fontes (ANTAQ, IBGE, MDIC, OSM).
Detalhes em [`LICENSE.md`](LICENSE.md). Para dar o crédito pedido pela licença, use a
citação acima.
