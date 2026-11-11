# ============================================================
# scripts/generar_documentacion.R
# Genera los HTML del proyecto a partir de los archivos fuente:
#   - manual/index.html     (manual completo del curso)
#   - salidas/demos/*.html  (una demo por módulo)
#   - salidas/informe_<año>.html (informe con parámetros)
#   - salidas/dashboard.html (versión HTML fija del dashboard)
#   - README.html
#
# Desde PowerShell, en la carpeta proyecto_r:
#   Rscript scripts/generar_documentacion.R
# Desde RStudio (proyecto abierto):
#   source("scripts/generar_documentacion.R")
#
# Requiere Pandoc. RStudio lo incluye; desde PowerShell puede ser
# necesario instalarlo (ver README).
# ============================================================

if (!file.exists("proyecto_r.Rproj")) {
  stop("Ejecuta este script con la carpeta proyecto_r como directorio de trabajo.",
       "\nDirectorio actual: ", getwd(), call. = FALSE)
}
if (!requireNamespace("rmarkdown", quietly = TRUE)) {
  stop("Falta el paquete rmarkdown. Ejecuta: Rscript requirements.R", call. = FALSE)
}

# RStudio trae su propio Pandoc; si existe, lo usamos.
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
if (!rmarkdown::pandoc_available()) {
  stop("No se encontró Pandoc. Genera los documentos desde RStudio o instala Pandoc:",
       "\n  winget install --id JohnMacFarlane.Pandoc -e", call. = FALSE)
}

dir.create(file.path("salidas", "demos"), recursive = TRUE, showWarnings = FALSE)
resultados <- data.frame(archivo = character(), estado = character())

generar <- function(entrada, ...) {
  cat("\n--- Generando", entrada, "\n")
  estado <- tryCatch({
    rmarkdown::render(entrada, quiet = TRUE, envir = new.env(), ...)
    "OK"
  }, error = function(e) paste("ERROR:", conditionMessage(e)))
  cat(estado, "\n")
  resultados[nrow(resultados) + 1, ] <<- c(entrada, estado)
}

# 1. Manual completo
generar(file.path("manual", "index.Rmd"))

# 2. Demos por módulo
for (demo in list.files("demos", pattern = "^[0-9].*\\.Rmd$", full.names = TRUE)) {
  generar(demo, output_dir = file.path("salidas", "demos"))
}

# 3. Informe con parámetros: uno por cada año del Excel
source(file.path("scripts", "validar_datos.R"), encoding = "UTF-8")
for (anio in sort(unique(cargar_datos()$ANIO))) {
  generar(
    file.path("demos", "informe_parametrizado.Rmd"),
    params = list(anio = anio),
    output_file = paste0("informe_", anio, ".html"),
    output_dir = "salidas"
  )
}

# 4. Versión HTML del dashboard (sin filtros; se abre sin R)
generar(
  file.path("dashboard", "dashboard_estatico.Rmd"),
  output_file = "dashboard.html",
  output_dir = "salidas"
)

# 5. README
generar("README.md", output_format = "html_document")

cat("\n========== RESUMEN ==========\n")
print(resultados, right = FALSE, row.names = FALSE)
if (any(resultados$estado != "OK")) {
  # Desde PowerShell devolvemos un código de error; en RStudio solo avisamos
  # (quit() cerraría la sesión de RStudio).
  if (interactive()) warning("Algunos documentos no se generaron.", call. = FALSE)
  else quit(status = 1)
}
