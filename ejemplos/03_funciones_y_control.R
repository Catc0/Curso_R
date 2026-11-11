# ============================================================
# ejemplos/03_funciones_y_control.R
# Módulo 1: funciones, argumentos, condicionales y ciclos.
# Desde PowerShell: Rscript ejemplos/03_funciones_y_control.R
# ============================================================

# 1. FUNCIONES PERSONALIZADAS ---------------------------------
formato_pct <- function(x, decimales = 1) {
  paste0(round(x * 100, decimales), "%")
}
print(formato_pct(0.91665))
print(formato_pct(0.91665, decimales = 0))

# 2. VARIOS VALORES DE RETORNO --------------------------------
resumen <- function(x) {
  list(minimo = min(x, na.rm = TRUE),
       maximo = max(x, na.rm = TRUE),
       promedio = mean(x, na.rm = TRUE))
}
str(resumen(c(0.5, 1, NA, 0.8)))

# 3. IF / ELSE ------------------------------------------------
clasificar <- function(avance) {
  if (is.na(avance)) {
    return("Sin dato")
  } else if (avance >= 1) {
    return("Completo")
  } else if (avance > 0) {
    return("Con avance")
  } else {
    return("Sin avance")
  }
}
print(clasificar(NA))
print(clasificar(0.6))

# 4. IFELSE (vectorizado) -------------------------------------
avances <- c(1, 0.75, NA, 0, 1)
print(ifelse(is.na(avances), "Sin dato", ifelse(avances >= 1, "Completo", "Pendiente")))

# 5. FOR ------------------------------------------------------
for (avance in avances) {
  cat(format(avance, width = 4), "->", clasificar(avance), "\n")
}

# vapply aplica una función a cada elemento (alternativa al for)
print(vapply(avances, clasificar, character(1)))

# 6. WHILE ----------------------------------------------------
apoyos <- 1
pasos <- 0
while (apoyos <= 100) {
  apoyos <- apoyos * 2
  pasos <- pasos + 1
}
cat("Se superó 100 en", pasos, "pasos (valor:", apoyos, ")\n")

# 7. REPEAT ---------------------------------------------------
valores <- c(0.5, 0.8, 1, 0.9)
i <- 0
repeat {
  i <- i + 1
  if (i > length(valores)) {
    i <- NA
    break
  }
  if (valores[i] >= 1) break
}
cat("Primer avance completo en la posición:", i, "\n")
cat("Forma vectorizada:", which(valores >= 1)[1], "\n")

# 8. MANEJO DE ERRORES ----------------------------------------
dividir <- function(a, b) {
  if (b == 0) stop("No se puede dividir entre cero.")
  a / b
}
resultado <- tryCatch(dividir(10, 0), error = function(e) {
  message("Error controlado: ", conditionMessage(e))
  NA
})
print(resultado)
