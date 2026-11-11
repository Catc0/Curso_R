# ============================================================
# ejemplos/02_estructuras_datos.R
# Módulo 2: listas, matrices y data frames.
# Desde PowerShell: Rscript ejemplos/02_estructuras_datos.R
# ============================================================

# 1. LISTAS ---------------------------------------------------
programa <- list(
  clave = "51U001",
  anio = 2025,
  avances = c(programa = 1, apoyos = 1)
)
programa$estatus <- 2          # crear
programa$anio <- 2024          # modificar
programa$avances <- NULL       # eliminar
str(programa)

# 2. MATRICES -------------------------------------------------
avances <- matrix(
  c(0.950, 0.948, 0.921, 0.952),
  nrow = 2,
  dimnames = list(c("Programa", "Apoyos"), c("2024", "2025"))
)
print(avances)
print(colMeans(avances))
avances <- rbind(avances, Global = c(0.972, 0.973))
print(avances["Global", ])

# 3. DATA FRAMES ----------------------------------------------
muestra <- data.frame(
  clave = c("54U001", "47S313", "51U001", "38E004"),
  anio = c(2025, 2024, 2025, 2025),
  avance_global = c(1, 0.91665, NA, 1)
)

# Crear y modificar columnas
muestra$tipo <- substr(muestra$clave, 3, 3)
muestra$avance_pct <- muestra$avance_global * 100

# Seleccionar
print(muestra[1, ])
print(muestra[, c("clave", "tipo")])

# Filtrar (cuidado con los NA)
print(muestra[muestra$anio == 2025 & !is.na(muestra$avance_global), ])
print(subset(muestra, anio == 2025, select = c(clave, avance_pct)))

# Ordenar
print(muestra[order(muestra$avance_global, decreasing = TRUE), ])

# Eliminar una columna y una fila
muestra$avance_pct <- NULL
muestra <- muestra[-1, ]
print(muestra)

# 4. EJERCICIO ------------------------------------------------
# Muestra las claves con avance menor que 1.
# Solución:
pendientes <- muestra[!is.na(muestra$avance_global) & muestra$avance_global < 1, "clave"]
print(pendientes)
