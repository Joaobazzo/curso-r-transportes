# Recorte didatico: modelo quatro etapas da RMC (VISUM, 2018)

Origem: `dados/brutos/modelo4etapas/shapefile/` (exportacao PTV VISUM, hora pico manha,
rede de 2018, contagens de 2017, 18 municipios da Regiao Metropolitana de Curitiba).

## Arquivos

| arquivo | conteudo |
|---|---|
| `links_rmc_2018_completo.parquet` | 208.336 links direcionais, sem geometria. Use para os totais da rede. |
| `links_rmc_2018_estrutural.parquet` | 33.198 links (rede estrutural + todos os links com contagem), sem geometria. |
| `rede_rmc_2018.gpkg` | camadas `links` (rede estrutural), `nos` (19.610, com paradas e BRT) e `zonas_centroide` (967). |
| `dicionario_campos_visum.csv` | de-para entre o nome truncado do shapefile e o nome original do VISUM (vem do arquivo .CTF). |

Recorte estrutural = `typeno < 50` (rodovias, arteriais e coletoras principais) mais
qualquer link com contagem. Exclui via local, condominio, ciclovia e conector.
Geometria simplificada em 1e-5 grau (~1 m).

## Correcoes ja aplicadas

O VISUM exporta com nomes que nao correspondem a unidade gravada:

- `VEHKMTRAVPRT` esta em **metros**, nao em km -> coluna `veic_km` (dividido por 1000)
- `VEHHOURTRAVT0` e `VEHHOURTRAVTCUR` estao em **segundos**, nao em horas -> `veic_h_livre`, `veic_h_carreg`
- `VOLCAPRATIOPRT` esta em percentual -> `vc` (razao)
- `T0_PRTSYS = 360000000` e sentinela de "sem acesso" -> virou `NA`, sinalizado em `sem_acesso`

## Totais de referencia (rede completa, hora pico manha)

| indicador | valor |
|---|---|
| veiculos-km | 3.676.335 |
| veiculos-hora em fluxo livre | 67.755 |
| veiculos-hora carregado | 176.158 |
| atraso | 108.403 veiculos-hora |
| velocidade media | 20,9 km/h (contra 54,3 km/h em fluxo livre) |
| links com V/C >= 1 | 3.436 |
| links com contagem | 63 (25 postos, tipo screenline) |

Confira sempre contra estes numeros depois de qualquer join ou filtro.

## Armadilhas mantidas de proposito (sao o exercicio)

1. **Duas linhas por link.** Cada link tem sentido direto e inverso (`isforward`, `sentido`).
   Somar sem atentar a isso nao duplica o volume, mas agrupar por `no` sim.
   A pasta `dados/brutos/modelo4etapas/modelo/` traz a MESMA rede na convencao oposta
   (ida e volta na mesma linha, prefixo `R_`). Comparar as duas e o exercicio de formato largo x longo.
2. **Nome de municipio corrompido.** O DBF de origem nao declara pagina de codigo e
   "ARAUCARIA" vem com byte invalido. `nm_municip_orig` guarda o original,
   `nm_municip_norm` a versao normalizada, e `code_muni` esta vazia de proposito:
   preencher via `geobr::read_municipality(code_muni = 41)` e o exercicio de de-para.
3. **CRS geografico.** O arquivo esta em WGS84 (graus) mas `comprimento_m` esta em metros.
   Calcular comprimento pela geometria exige reprojetar para SIRGAS 2000 / UTM 22S (EPSG:31982).
   Comparar o calculado com o gravado e uma checagem honesta.
4. **Falta legenda.** Os codigos de `tsysset` (B, C, D, k, P, A, R, PUTW) e de `typeno`
   nao vem documentados na exportacao. Pedir ao orgao antes de separar caminhao de automovel.

## O que nao esta aqui

Matrizes OD (demanda e tempo), poligonos das zonas, e os insumos das tres primeiras
etapas do modelo. Este recorte cobre apenas o resultado da alocacao.
