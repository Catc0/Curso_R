# ============================================================
# scripts/validar_datos.R
# Funciones para leer, limpiar y validar datos/datos.xlsx.
#
# Uso desde otros scripts (con la carpeta proyecto_r como directorio de trabajo):
#   source("scripts/validar_datos.R", encoding = "UTF-8")
#   programas <- cargar_datos("datos/datos.xlsx")
#
# Uso directo desde PowerShell (muestra el reporte de validación):
#   Rscript scripts/validar_datos.R
# ============================================================

# 1. CONFIGURACIÓN --------------------------------------------

HOJA_DATOS <- "Exportar Hoja de Trabajo"

COLUMNAS_REQUERIDAS <- c(
  "TIPO", "CLAVE", "PROGRAMA", "ESTATUS", "DEPENDENCIA", "ANIO",
  "TITULAR_RP", "INFORMANTE", "ULTIMA_MODIFICACION",
  "AVANCE_PROGRAMA", "AVANCE_APOYOS", "TOTAL_APOYOS", "AVANCE_GLOBAL"
)

# Etiquetas confirmadas por el responsable de los datos.
# (En datos.xlsx aparecen los códigos 0 a 3; el 4 se incluye por si aparece.)
ETIQUETAS_ESTATUS <- c(
  "0" = "Sin ingreso o captura",
  "1" = "Pendiente",
  "2" = "Liberado Informante",
  "3" = "Liberado Titular RP",
  "4" = "Liberado Titular AE"
)

# Tipo = tercer carácter de la clave del programa.
# Modalidades de programas presupuestarios (confirmadas).
ETIQUETAS_TIPO <- c(
  "B" = "B - Provisión de bienes públicos",
  "E" = "E - Prestación de servicios públicos",
  "S" = "S - Sujetos a reglas de operación",
  "U" = "U - Otros subsidios"
)

# 2. FUNCIONES AUXILIARES -------------------------------------

# Convierte texto a número. Los textos vacíos o con solo espacios
# (por ejemplo " ") se convierten en NA.
convertir_numero <- function(x) {
  x <- trimws(as.character(x))
  x[x == ""] <- NA
  numero <- suppressWarnings(as.numeric(x))
  no_convertibles <- sum(!is.na(x) & is.na(numero))
  if (no_convertibles > 0) {
    warning(no_convertibles, " valores no numéricos se convirtieron en NA.", call. = FALSE)
  }
  numero
}

# Limpia una columna de texto: quita espacios y convierte "" en NA.
limpiar_texto <- function(x) {
  x <- trimws(as.character(x))
  x[x == ""] <- NA
  x
}

# Nombre corto de una dependencia para las gráficas:
# usa la sigla entre paréntesis si existe, por ejemplo "(ISSSTE)".
nombre_corto <- function(x, max_caracteres = 34) {
  tiene_sigla <- grepl("\\(([^)]+)\\)\\s*$", x)
  corto <- ifelse(tiene_sigla, sub(".*\\(([^)]+)\\)\\s*$", "\\1", x), x)
  ifelse(
    nchar(corto) > max_caracteres,
    paste0(substr(corto, 1, max_caracteres - 3), "..."),
    corto
  )
}

# 3. CARGAR Y LIMPIAR -----------------------------------------

cargar_datos <- function(ruta = file.path("datos", "datos.xlsx")) {
  if (!requireNamespace("readxl", quietly = TRUE)) {
    stop("Falta el paquete readxl. Ejecuta source(\"requirements.R\").", call. = FALSE)
  }
  if (!file.exists(ruta)) {
    stop(
      "No se encontró el archivo de datos: ", ruta,
      "\nDirectorio de trabajo actual: ", getwd(),
      "\nAbre proyecto_r.Rproj o usa setwd() hacia la carpeta proyecto_r.",
      call. = FALSE
    )
  }

  hojas <- readxl::excel_sheets(ruta)
  if (!HOJA_DATOS %in% hojas) {
    stop(
      "El Excel no tiene la hoja '", HOJA_DATOS, "'. Hojas encontradas: ",
      paste(hojas, collapse = ", "),
      call. = FALSE
    )
  }

  # Se lee todo como texto y luego se convierte cada columna:
  # así controlamos los espacios vacíos y los decimales como ".8333".
  datos <- as.data.frame(readxl::read_excel(ruta, sheet = HOJA_DATOS, col_types = "text"))

  faltantes <- setdiff(COLUMNAS_REQUERIDAS, names(datos))
  if (length(faltantes) > 0) {
    stop("Faltan columnas en el Excel: ", paste(faltantes, collapse = ", "), call. = FALSE)
  }

  # Columnas de texto
  columnas_texto <- intersect(
    c("TIPO", "CLAVE", "PROGRAMA", "DEPENDENCIA", "ENLACE_AE",
      "TITULAR_AE", "TITULAR_RP", "INFORMANTE"),
    names(datos)
  )
  for (columna in columnas_texto) {
    datos[[columna]] <- limpiar_texto(datos[[columna]])
  }

  # Columnas numéricas
  datos$ANIO <- as.integer(convertir_numero(datos$ANIO))
  datos$ESTATUS <- as.integer(convertir_numero(datos$ESTATUS))
  datos$AVANCE_PROGRAMA <- convertir_numero(datos$AVANCE_PROGRAMA)
  datos$AVANCE_APOYOS <- convertir_numero(datos$AVANCE_APOYOS)
  datos$AVANCE_GLOBAL <- convertir_numero(datos$AVANCE_GLOBAL)
  datos$TOTAL_APOYOS <- convertir_numero(datos$TOTAL_APOYOS)

  # Fecha en formato dd/mm/aa (por ejemplo "09/11/26")
  datos$ULTIMA_MODIFICACION <- as.Date(
    limpiar_texto(datos$ULTIMA_MODIFICACION),
    format = "%d/%m/%y"
  )

  # Columnas derivadas para el análisis y el dashboard
  datos$ESTATUS_ETIQUETA <- factor(
    ifelse(
      is.na(datos$ESTATUS), "Sin estatus",
      ifelse(as.character(datos$ESTATUS) %in% names(ETIQUETAS_ESTATUS),
             ETIQUETAS_ESTATUS[as.character(datos$ESTATUS)],
             paste("Estatus", datos$ESTATUS))
    ),
    # Orden del flujo de captura (0 -> 4), no alfabético
    levels = unique(c(ETIQUETAS_ESTATUS, "Sin estatus",
                      paste("Estatus", sort(unique(datos$ESTATUS)))))
  )
  datos$TIPO_ETIQUETA <- factor(
    ifelse(datos$TIPO %in% names(ETIQUETAS_TIPO), ETIQUETAS_TIPO[datos$TIPO], datos$TIPO)
  )
  datos$DEPENDENCIA_CORTA <- nombre_corto(datos$DEPENDENCIA)

  # Los avances son proporciones: 1 = 100 %.
  # Completo   = avance global de 100 %.
  # Con avance = avance global mayor que 0 % y menor que 100 % (supuesto).
  datos$COMPLETO <- !is.na(datos$AVANCE_GLOBAL) & datos$AVANCE_GLOBAL >= 1
  datos$CON_AVANCE <- !is.na(datos$AVANCE_GLOBAL) &
    datos$AVANCE_GLOBAL > 0 & datos$AVANCE_GLOBAL < 1

  datos
}

# 4. VALIDAR --------------------------------------------------
# Devuelve una tabla con cada revisión, su resultado y un detalle.

validar_datos <- function(datos) {
  revision <- function(nombre, correcto, detalle) {
    data.frame(revision = nombre,
               resultado = ifelse(correcto, "OK", "REVISAR"),
               detalle = detalle)
  }

  en_rango <- function(x) all(is.na(x) | (x >= 0 & x <= 1))

  tipo_desde_clave <- substr(datos$CLAVE, 3, 3)
  coincide_tipo <- is.na(datos$TIPO) | is.na(datos$CLAVE) | datos$TIPO == tipo_desde_clave

  # AVANCE_GLOBAL debería ser el promedio de los otros dos avances (hoja SQL).
  esperado <- (datos$AVANCE_PROGRAMA + datos$AVANCE_APOYOS) / 2
  diferencia <- abs(datos$AVANCE_GLOBAL - esperado)
  promedio_ok <- all(is.na(diferencia) | diferencia < 0.001)

  duplicadas <- sum(duplicated(paste(datos$CLAVE, datos$ANIO)))

  rbind(
    revision("Filas leídas", nrow(datos) > 0, paste(nrow(datos), "programas")),
    revision("Años", all(!is.na(datos$ANIO)),
             paste(sort(unique(datos$ANIO)), collapse = ", ")),
    revision("Códigos de estatus conocidos",
             all(is.na(datos$ESTATUS) | as.character(datos$ESTATUS) %in% names(ETIQUETAS_ESTATUS)),
             paste(sort(unique(datos$ESTATUS)), collapse = ", ")),
    revision("Tipo = 3er carácter de la clave", all(coincide_tipo),
             paste(sum(!coincide_tipo), "diferencias")),
    revision("Avances entre 0 y 1",
             en_rango(datos$AVANCE_PROGRAMA) && en_rango(datos$AVANCE_APOYOS) &&
               en_rango(datos$AVANCE_GLOBAL),
             "AVANCE_PROGRAMA, AVANCE_APOYOS, AVANCE_GLOBAL"),
    revision("Avance global = promedio de avances", promedio_ok,
             "Regla tomada de la hoja SQL"),
    revision("Avance global sin dato", TRUE,
             paste(sum(is.na(datos$AVANCE_GLOBAL)), "programas (se excluyen de los promedios)")),
    revision("Titular RP sin asignar", TRUE,
             paste(sum(is.na(datos$TITULAR_RP)), "programas")),
    revision("Informante sin asignar", TRUE,
             paste(sum(is.na(datos$INFORMANTE)), "programas")),
    revision("Fechas de modificación válidas", TRUE,
             paste(sum(is.na(datos$ULTIMA_MODIFICACION)), "sin fecha")),
    revision("Clave + año sin duplicar", duplicadas == 0,
             paste(duplicadas, "posibles duplicados"))
  )
}

# 5. EJECUCIÓN DIRECTA ----------------------------------------
# Este bloque solo corre con  Rscript scripts/validar_datos.R ;
# no se ejecuta cuando el archivo se carga con source().
if (sys.nframe() == 0) {
  programas <- cargar_datos(file.path("datos", "datos.xlsx"))
  reporte <- validar_datos(programas)
  print(reporte, right = FALSE, row.names = FALSE)
  dir.create("salidas", showWarnings = FALSE)
  write.csv(reporte, file.path("salidas", "validacion_datos.csv"), row.names = FALSE)
  cat("\nReporte guardado en salidas/validacion_datos.csv\n")
  if (any(reporte$resultado == "REVISAR")) {
    cat("Hay revisiones marcadas como REVISAR.\n")
  }
}
