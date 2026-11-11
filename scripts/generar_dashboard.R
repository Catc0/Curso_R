# ============================================================
# scripts/generar_dashboard.R
# 1. Genera la versión HTML autónoma del dashboard:
#      salidas/dashboard.html  (se abre sin R; vistas fijas por año)
# 2. Inicia el dashboard interactivo (Shiny) en el navegador.
#
# Desde PowerShell, en la carpeta proyecto_r:
#   Rscript scripts/generar_dashboard.R             # HTML + dashboard
#   Rscript scripts/generar_dashboard.R --solo-html # solo el HTML
# Desde RStudio (proyecto abierto):
#   source("scripts/generar_dashboard.R")
#
# El dashboard interactivo necesita que R siga ejecutándose (es un
# servidor local). Para detenerlo: Ctrl + C en PowerShell, o el botón
# rojo "Stop" en la consola de RStudio.
# ============================================================

if (!file.exists(file.path("dashboard", "app.R"))) {
  stop(
    "No se encontró dashboard/app.R. El directorio de trabajo debe ser la carpeta proyecto_r.",
    "\nDirectorio actual: ", getwd(),
    call. = FALSE
  )
}

paquetes <- c("shiny", "bslib", "ggplot2", "readxl", "rmarkdown", "knitr")
faltan <- paquetes[!vapply(paquetes, requireNamespace, logical(1), quietly = TRUE)]
if (length(faltan) > 0) {
  stop("Faltan paquetes: ", paste(faltan, collapse = ", "),
       ". Ejecuta primero: Rscript requirements.R", call. = FALSE)
}

# 1. VERSIÓN HTML ---------------------------------------------
# RStudio trae su propio Pandoc; si existe y no hay otro, lo usamos.
if (!rmarkdown::pandoc_available()) {
  candidatos <- c(
    file.path(Sys.getenv("LOCALAPPDATA"), "Pandoc"),  # winget (instalación por usuario)
    "C:/Program Files/RStudio/resources/app/bin/quarto/bin/tools",
    "C:/Program Files/RStudio/bin/quarto/bin/tools",
    "C:/Program Files/RStudio/resources/app/bin/pandoc",
    "C:/Program Files/RStudio/bin/pandoc"
  )
  encontrado <- candidatos[file.exists(file.path(candidatos, "pandoc.exe"))]
  if (length(encontrado) > 0) Sys.setenv(RSTUDIO_PANDOC = encontrado[1])
}

solo_html <- "--solo-html" %in% commandArgs(trailingOnly = TRUE)
salida_html <- file.path("salidas", "dashboard.html")

if (rmarkdown::pandoc_available()) {
  dir.create("salidas", showWarnings = FALSE)
  cat("Generando", salida_html, "...\n")
  rmarkdown::render(
    file.path("dashboard", "dashboard_estatico.Rmd"),
    output_file = "dashboard.html",
    output_dir = "salidas",
    envir = new.env(),
    quiet = TRUE
  )
  cat("Listo:", normalizePath(salida_html), "\n")
} else {
  msg <- paste("No se encontró Pandoc: no se generó", salida_html,
               "\n  Instálalo con: winget install --id JohnMacFarlane.Pandoc -e")
  if (solo_html) stop(msg, call. = FALSE) else warning(msg, call. = FALSE)
}

# 2. DASHBOARD INTERACTIVO ------------------------------------
if (!solo_html) {
  puerto <- 3838
  cat("Iniciando el dashboard en http://127.0.0.1:", puerto, "\n", sep = "")
  cat("Presiona Ctrl + C (o Stop en RStudio) para detenerlo.\n")
  shiny::runApp("dashboard", port = puerto, launch.browser = TRUE)
}
