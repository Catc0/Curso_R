# ============================================================
# ejemplos/01_fundamentos.R
# Módulo 1: variables, tipos de datos, operadores, vectores y NA.
#
# Ejecución: abre proyecto_r.Rproj, abre este archivo y usa
# Ctrl + Enter (línea por línea) o Ctrl + Shift + Enter (todo).
# Desde PowerShell: Rscript ejemplos/01_fundamentos.R
# ============================================================

# 1. VARIABLES Y ASIGNACIÓN -----------------------------------
total_programas <- 250
nombre_curso <- "Curso de R"
cat("Curso:", nombre_curso, "| Programas:", total_programas, "\n")

# 2. CONSTANTES -----------------------------------------------
HOJA_DATOS <- "Exportar Hoja de Trabajo"   # en MAYÚSCULAS: no debe cambiar
cat("Área de un círculo de radio 3:", pi * 3^2, "\n")

# 3. TIPOS DE DATOS -------------------------------------------
avance_texto <- ".8333"            # así viene en el Excel
avance <- as.numeric(avance_texto)
anio <- 2025L
completo <- avance >= 1
fecha <- as.Date("09/11/26", format = "%d/%m/%y")
print(sapply(list(avance_texto, avance, anio, completo, fecha), class))

# 4. OPERADORES ARITMÉTICOS -----------------------------------
avance_programa <- 1
avance_apoyos <- 0.8333
avance_global <- (avance_programa + avance_apoyos) / 2
cat("Avance global:", round(avance_global * 100, 1), "%\n")
cat("250 programas entre 19 dependencias:", 250 %/% 19, "cada una y sobran", 250 %% 19, "\n")

# 5. OPERADORES DE COMPARACIÓN Y LÓGICOS ----------------------
print(avance_global == 1)                       # ¿completo?
print(avance_global > 0 & avance_global < 1)    # ¿con avance parcial?
print("S" %in% c("S", "U"))
print(isTRUE(all.equal(0.1 + 0.2, 0.3)))        # comparar decimales de forma segura

# 6. VECTORES -------------------------------------------------
avances <- c(1, 0.8333, 0.5, 1, 0.25)
print(avances[avances >= 0.8])        # filtrar
cat("Completos:", sum(avances >= 1), "\n")
print(avances * 100)                  # operación vectorizada
apoyos <- c(ISSSTE = 3, IMSS = 5, INPI = 1)
print(apoyos["IMSS"])

# 7. VALORES FALTANTES ----------------------------------------
con_na <- c(1, NA, 0.5)
print(mean(con_na))                   # NA
print(mean(con_na, na.rm = TRUE))     # 0.75
cat("Faltantes:", sum(is.na(con_na)), "\n")
print(c(0 / 0, 1 / 0, length(NULL)))  # NaN, Inf, 0

# 8. EJERCICIO ------------------------------------------------
# Calcula el porcentaje de programas completos del vector 'avances'.
# Solución:
porcentaje_completos <- mean(avances >= 1) * 100
cat("Porcentaje de completos:", porcentaje_completos, "%\n")
