# ============================================================
# ejemplos/04_importacion_excel.R
# Módulo 2: importar datos.xlsx, limpiarlo y validarlo.
# Requiere el paquete readxl (ver requirements.R).
# Desde PowerShell: Rscript ejemplos/04_importacion_excel.R
# ============================================================

library(readxl)

# 1. LEER EL EXCEL "CRUDO" ------------------------------------
ruta <- file.path("datos", "datos.xlsx")
if (!file.exists(ruta)) stop("No se encontró ", ruta, ". Revisa getwd(): ", getwd())

print(excel_sheets(ruta))
crudo <- as.data.frame(read_excel(ruta, sheet = "Exportar Hoja de Trabajo"))
cat("Filas:", nrow(crudo), " Columnas:", ncol(crudo), "\n")
print(sapply(crudo, class))

# 2. EL PROBLEMA: AVANCES COMO TEXTO --------------------------
print(head(crudo$AVANCE_APOYOS, 10))
# read_excel() recorta espacios (trim_ws = TRUE): las celdas " " llegan como NA.
cat("Celdas vacías (NA):", sum(is.na(crudo$AVANCE_APOYOS)), "\n")

# 3. LIMPIEZA PASO A PASO -------------------------------------
limpio <- crudo
limpio$AVANCE_APOYOS <- trimws(limpio$AVANCE_APOYOS)
limpio$AVANCE_APOYOS[limpio$AVANCE_APOYOS == ""] <- NA
limpio$AVANCE_APOYOS <- as.numeric(limpio$AVANCE_APOYOS)
print(summary(limpio$AVANCE_APOYOS))

limpio$ULTIMA_MODIFICACION <- as.Date(limpio$ULTIMA_MODIFICACION, format = "%d/%m/%y")
print(range(limpio$ULTIMA_MODIFICACION, na.rm = TRUE))

# 4. LIMPIEZA COMPLETA CON LAS FUNCIONES DEL PROYECTO ---------
source(file.path("scripts", "validar_datos.R"), encoding = "UTF-8")
programas <- cargar_datos(ruta)
str(programas[, c("ANIO", "ESTATUS", "AVANCE_PROGRAMA", "AVANCE_APOYOS",
                  "AVANCE_GLOBAL", "TOTAL_APOYOS", "ULTIMA_MODIFICACION")])

# 5. VALIDACIÓN -----------------------------------------------
print(validar_datos(programas), right = FALSE)

# 6. TEXTO Y VALORES FALTANTES --------------------------------
print(head(unique(programas$DEPENDENCIA_CORTA)))
print(colSums(is.na(programas[, c("TITULAR_RP", "INFORMANTE", "AVANCE_GLOBAL")])))

# 7. GUARDAR UNA COPIA LIMPIA EN CSV --------------------------
# El Excel original no se modifica.
dir.create("salidas", showWarnings = FALSE)
write.csv(programas, file.path("salidas", "programas_limpios.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
cat("Copia limpia guardada en salidas/programas_limpios.csv\n")
