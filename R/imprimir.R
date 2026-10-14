raiz  <- "C:/Users/joaob/OneDrive/Desktop/curso-r-transportes"
saida <- "C:/Users/joaob/AppData/Local/Temp/claude/c--Users-joaob-OneDrive-Desktop-curso-r-transportes/04bece38-b467-4fd3-b495-f8fe58d9bcb3/scratchpad/pdf/paginas"
dir.create(saida, showWarnings = FALSE)

# ordem dos capítulos, como no _quarto.yml
yml <- readLines(file.path(raiz, "_quarto.yml"), encoding = "UTF-8")
caps <- regmatches(yml, regexpr("[a-z0-9-]+\\.qmd", yml))
caps <- sub("\\.qmd$", "", caps)

b <- chromote::ChromoteSession$new(width = 1280, height = 900)
pdfs <- character()
for (i in seq_along(caps)) {
  url <- paste0("file:///", raiz, "/_site/", caps[i], ".html")
  p <- b$Page$loadEventFired(wait_ = FALSE)
  b$Page$navigate(url, wait_ = FALSE)
  b$wait_for(p)
  # rola até o fim para os mapas e imagens carregarem, e espera os blocos do mapa de fundo
  b$Runtime$evaluate("window.scrollTo(0, document.body.scrollHeight)")
  Sys.sleep(4)
  b$Runtime$evaluate("window.scrollTo(0, 0)")
  # abre as caixas recolhidas (soluções dos exercícios) só na impressão
  b$Runtime$evaluate(paste(
    "document.querySelectorAll('.callout-collapse').forEach(e => { e.classList.add('show'); e.style.height = 'auto'; });",
    "document.querySelectorAll('[data-bs-toggle=\"collapse\"]').forEach(e => { e.classList.remove('collapsed'); e.setAttribute('aria-expanded', 'true'); });"))
  Sys.sleep(1)
  r <- b$Page$printToPDF(paperWidth = 8.27, paperHeight = 11.69,          # A4
                         marginTop = 0.5, marginBottom = 0.5,
                         marginLeft = 0.4, marginRight = 0.4,
                         printBackground = TRUE, displayHeaderFooter = FALSE)
  arq <- file.path(saida, sprintf("%02d-%s.pdf", i, caps[i]))
  writeBin(jsonlite::base64_dec(r$data), arq)
  pdfs <- c(pdfs, arq)
  message(sprintf("%02d/%d %s (%d páginas)", i, length(caps), caps[i], pdftools::pdf_length(arq)))
}
b$close()

final <- file.path(raiz, "releases", "curso-r-transportes.pdf")
qpdf::pdf_combine(pdfs, final)
message("PDF final: ", final, " | ", pdftools::pdf_length(final), " páginas | ",
        round(file.size(final) / 1e6, 1), " MB")
