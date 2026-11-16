# ------------------------------------------------------------------
# cidades.R
# Os parâmetros de cada cidade do projeto final: os mesmos de
# R/preparar_projeto_final.R e dos LEIA-ME de data_raw/projeto_final/{cidade}.
# Lido pelo relatorio.qmd e pelo rodar_todas.R.
# ------------------------------------------------------------------

cidades <- list(
  fortaleza = list(
    nome = "Fortaleza",
    partida = "2026-05-16 07:00:00", fuso = "America/Fortaleza",
    centro = list(nome = "Praça do Ferreira", genero = "f", lon = -38.5267, lat = -3.7275),
    bairro = list(nome = "Messejana", lon = -38.4920, lat = -3.8300),
    limitacoes = c(
      "O GTFS só tem viagens de fim de semana: o resultado vale para um sábado de manhã, não para o pico de um dia útil."
    )
  ),
  sao_paulo = list(
    nome = "São Paulo",
    partida = "2026-05-13 07:00:00", fuso = "America/Sao_Paulo",
    centro = list(nome = "Praça da Sé", genero = "f", lon = -46.6340, lat = -23.5504),
    bairro = list(nome = "Cidade Tiradentes", lon = -46.4020, lat = -23.5830),
    limitacoes = c(
      "O GTFS da SPTrans descreve os horários por frequência; foi convertido em horários fixos só entre 5h e 11h.",
      "Os trens da CPTM e o metrô entram no GTFS como linhas: o corte do quarto de menor oferta pode atingi-los."
    )
  ),
  rio_de_janeiro = list(
    nome = "Rio de Janeiro",
    partida = "2026-05-13 07:00:00", fuso = "America/Sao_Paulo",
    centro = list(nome = "Central do Brasil", genero = "f", lon = -43.1910, lat = -22.9035),
    bairro = list(nome = "Madureira", lon = -43.3384, lat = -22.8735),
    limitacoes = c(
      "O GTFS traz só os ônibus municipais e o BRT: metrô, trens da SuperVia, VLT e barcas não estão na rede, e a acessibilidade está subestimada.",
      "Os horários por frequência foram convertidos em horários fixos só entre 5h e 11h."
    )
  ),
  porto_alegre = list(
    nome = "Porto Alegre",
    partida = "2025-10-22 07:00:00", fuso = "America/Sao_Paulo",
    centro = list(nome = "Mercado Público", genero = "m", lon = -51.2276, lat = -30.0277),
    bairro = list(nome = "Restinga", lon = -51.1530, lat = -30.1480),
    limitacoes = c(
      "O GTFS da EPTC venceu em dezembro de 2025: a análise usa uma quarta-feira de outubro de 2025.",
      "O trem metropolitano (Trensurb) não está na rede.",
      "Foram removidas as viagens de duração zero do GTFS (6% do total), que o r5r trataria como teletransporte."
    )
  ),
  belo_horizonte = list(
    nome = "Belo Horizonte",
    partida = "2026-05-13 07:00:00", fuso = "America/Sao_Paulo",
    centro = list(nome = "Praça Sete", genero = "f", lon = -43.9378, lat = -19.9191),
    bairro = list(nome = "Venda Nova", lon = -43.9580, lat = -19.8160),
    limitacoes = c(
      "O GTFS une o sistema convencional e o suplementar da SUMOB; o metrô não está na rede."
    )
  )
)
