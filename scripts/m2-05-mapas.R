# ------------------------------------------------------------------
# m2-05-mapas.R: código do capítulo "Geovisualização"
# Extraído de m2-05-mapas.qmd em 04/11/2026 por R/gerar_scripts_capitulos.R.
#
# Todo o código citado no capítulo, na ordem do texto.
# Rode a partir da raiz do projeto (abra o curso-r-transportes.Rproj)
# depois de rodar uma vez o script de preparação do módulo 2:
#   source("R/preparar_modulo2.R")
#
# 1 bloco(s) não rodam no site e estão marcados com "[não roda no site]":
# alguns exigem o Java 21, baixam arquivos grandes ou são trechos que
# dependem de objetos criados antes. Rode bloco a bloco, conferindo.
# ------------------------------------------------------------------

# ---- Geovisualização ----

library(sf)
library(dplyr)
library(ggplot2)

arquivo <- "dados/brutos/muni_pr_sc.gpkg"
if (!file.exists(arquivo)) {
  muni <- dplyr::bind_rows(
    geobr::read_municipality(code_muni = "PR", year = 2022, showProgress = FALSE),
    geobr::read_municipality(code_muni = "SC", year = 2022, showProgress = FALSE)
  )
  sf::st_write(muni, arquivo, quiet = TRUE)
}
muni <- sf::st_read(arquivo, quiet = TRUE)

portos <- data.frame(
  nome = c("Paranaguá", "Antonina", "São Francisco do Sul", "Itajaí", "Imbituba"),
  tku_bi = c(21.4, 1.2, 8.7, 6.3, 3.1),
  lon = c(-48.5119, -48.7119, -48.6383, -48.6486, -48.6706),
  lat = c(-25.5016, -25.4283, -26.2400, -26.9077, -28.2300)
) |>
  sf::st_as_sf(coords = c("lon", "lat"), crs = 4326)

# ---- `geom_sf`: o mapa no `ggplot2` ----

ggplot(muni) + geom_sf()

muni |>
  dplyr::mutate(area_km2 = as.numeric(units::set_units(sf::st_area(geom), km^2))) |>
  ggplot() +
  geom_sf(aes(fill = area_km2), colour = "white", linewidth = 0.1) +
  scale_fill_viridis_c(option = "mako", direction = -1, transform = "log10",
                       name = "Área (km²)",
                       labels = scales::label_number(big.mark = ".")) +
  theme_void(base_size = 10)

# ---- Camadas, símbolos proporcionais e rótulos ----

ggplot() +
  geom_sf(data = muni, fill = "grey96", colour = "grey80", linewidth = 0.2) +
  geom_sf(data = portos, aes(size = tku_bi), colour = "#1a5b8a", alpha = 0.75) +
  ggrepel::geom_text_repel(
    data = portos,
    aes(label = nome, geometry = geometry),
    stat = "sf_coordinates", size = 2.8, min.segment.length = 0
  ) +
  scale_size_continuous(range = c(2, 10), name = "TKU (bi t·km)") +
  coord_sf(xlim = c(-49.5, -47.8), ylim = c(-28.8, -25.0)) +
  labs(caption = "Valores ilustrativos.") +
  theme_void(base_size = 10) +
  theme(legend.position = "right")

# ---- Escala, norte e grade de coordenadas ----

litoral <- muni |>
  dplyr::filter(name_muni %in% c("Paranaguá", "Antonina", "Morretes", "Guaratuba",
                          "Matinhos", "Pontal do Paraná", "Guaraqueçaba"))

ggplot(litoral) +
  geom_sf(aes(fill = name_muni), colour = "white", linewidth = 0.3) +
  geom_sf(data = portos |> dplyr::filter(nome %in% c("Paranaguá", "Antonina")),
          colour = "black", size = 2) +
  ggspatial::annotation_scale(location = "bl", width_hint = 0.25) +
  ggspatial::annotation_north_arrow(
    location = "tr", style = ggspatial::north_arrow_minimal(),
    height = unit(1, "cm"), width = unit(1, "cm")
  ) +
  scale_fill_brewer(palette = "Blues", name = NULL) +
  labs(title = "Litoral do Paraná",
       caption = "Fonte: IBGE, malha municipal 2022 (geobr).") +
  theme_minimal(base_size = 10) +
  theme(panel.grid = element_line(colour = "grey92", linewidth = 0.2))

# ---- Painéis ----

muni |>
  dplyr::mutate(area_km2 = as.numeric(units::set_units(sf::st_area(geom), km^2))) |>
  ggplot() +
  geom_sf(aes(fill = area_km2), colour = NA) +
  facet_wrap(~abbrev_state) +
  scale_fill_viridis_c(option = "mako", direction = -1, transform = "log10", name = "km²") +
  theme_void(base_size = 9)

# ---- `leaflet`: mapas interativos de publicação ----

leaflet::leaflet(portos) |>
  leaflet::addProviderTiles("Esri.WorldGrayCanvas") |>
  leaflet::addCircleMarkers(
    radius = ~sqrt(tku_bi) * 2,
    color = "#1a5b8a", fillOpacity = 0.6, stroke = FALSE,
    popup = ~paste0("<b>", nome, "</b><br>TKU: ", tku_bi, " bi t·km")
  ) |>
  leaflet::addPolygons(data = sf::st_transform(litoral, 4326),
              fillColor = "#e07b39", fillOpacity = 0.2,
              color = "white", weight = 1, label = ~name_muni) |>
  leaflet::addScaleBar(position = "bottomleft")

# ---- O uso mais valioso de um mapa interativo não é publicar. É conferir ----

area_analise <- litoral

mapview::mapview(area_analise, map.types = "Esri.WorldImagery")

# ---- `mapgl`: mapas vetoriais modernos ----

library(mapgl)

mapgl::maplibre(bounds = portos, height = "525px") |>   # sem height, o mapa ocupa 750 px
  mapgl::add_circle_layer(
    id = "portos",
    source = portos,
    circle_color = "#1a5b8a",
    circle_radius = 8,
    circle_opacity = 0.7,
    tooltip = "nome"
  )

# ---- Salvar mapas ----

# [não roda no site (eval: false): pode exigir Java, download grande ou objetos anteriores]
mapa <- ggplot(litoral) + geom_sf()

ggsave("resultados/mapa_litoral.png", mapa,
       width = 18, height = 14, units = "cm", dpi = 300)
ggsave("resultados/mapa_litoral.pdf", mapa,
       width = 18, height = 14, units = "cm")        # vetorial, para impressão
