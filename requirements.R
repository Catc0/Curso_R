# ============================================================
# requirements.R
# Instala (solo si faltan) y verifica los paquetes del proyecto.
#
# Cómo ejecutarlo:
#   - En RStudio: abre proyecto_r.Rproj y ejecuta  source("requirements.R")
#   - En PowerShell, desde la carpeta proyecto_r:  Rscript requirements.R
#
# Requiere conexión a Internet la primera vez (descarga desde CRAN).
# ============================================================

# 1. VERSIÓN MÍNIMA DE R -------------------------------------
# R 4.2 o superior usa UTF-8 de forma nativa en Windows, lo que
# evita problemas con acentos en los scripts y en los datos.
if (getRversion() < "4.2.0") {
  stop(
    "Este proyecto requiere R 4.2.0 o superior. Versión instalada: ",
    getRversion(), ". Actualiza R desde https://cran.r-project.org",
    call. = FALSE
  )
}

# 2. LISTA CENTRALIZADA DE PAQUETES ---------------------------
paquetes <- c(
  "readxl",     # leer archivos Excel (.xlsx)
  "ggplot2",    # gráficas
  "rmarkdown",  # documentos R Markdown y HTML
  "knitr",      # ejecutar código dentro de R Markdown
  "shiny",      # dashboard interactivo
  "bslib"       # diseño (Bootstrap 5) para Shiny y R Markdown
)

# 3. LIBRERÍA PERSONAL ----------------------------------------
# Si R está en "C:/Program Files", esa carpeta no admite escritura sin
# permisos de administrador. RStudio pregunta si crear una librería
# personal, pero Rscript no puede preguntar: la creamos aquí.
libreria_usuario <- Sys.getenv("R_LIBS_USER")
if (file.access(.libPaths()[1], mode = 2) != 0 && nzchar(libreria_usuario)) {
  dir.create(libreria_usuario, recursive = TRUE, showWarnings = FALSE)
  .libPaths(c(libreria_usuario, .libPaths()))
  message("Los paquetes se instalarán en la librería personal: ", libreria_usuario)
}

# 4. INSTALAR SOLO LOS QUE FALTAN -----------------------------
instalado <- vapply(paquetes, requireNamespace, logical(1), quietly = TRUE)
faltantes <- paquetes[!instalado]

if (length(faltantes) > 0) {
  message("Instalando paquetes: ", paste(faltantes, collapse = ", "))
  install.packages(faltantes, repos = "https://cloud.r-project.org")
} else {
  message("Todos los paquetes ya estaban instalados.")
}

# 5. VERIFICAR ------------------------------------------------
instalado <- vapply(paquetes, requireNamespace, logical(1), quietly = TRUE)
if (!all(instalado)) {
  stop(
    "No se pudieron instalar: ", paste(paquetes[!instalado], collapse = ", "),
    ". Revisa tu conexión a Internet o los permisos de la carpeta de librerías ",
    "(ejecuta .libPaths() para verla).",
    call. = FALSE
  )
}

# 6. REGISTRAR VERSIONES --------------------------------------
versiones <- data.frame(
  componente = c("R", paquetes),
  version = c(
    as.character(getRversion()),
    vapply(paquetes, function(p) as.character(packageVersion(p)), character(1))
  ),
  row.names = NULL
)
print(versiones)

pandoc_ok <- rmarkdown::pandoc_available()
cat("\nPandoc disponible:", pandoc_ok,
    if (pandoc_ok) paste0("(versión ", rmarkdown::pandoc_version(), ")") else "", "\n")
if (!pandoc_ok) {
  message(
    "Pandoc no se encontró. RStudio lo incluye: genera los HTML desde RStudio, ",
    "o instala Pandoc con  winget install --id JohnMacFarlane.Pandoc -e"
  )
}

dir.create("salidas", showWarnings = FALSE)
write.csv(versiones, file.path("salidas", "versiones.csv"), row.names = FALSE)
cat("Versiones guardadas en salidas/versiones.csv\n")
