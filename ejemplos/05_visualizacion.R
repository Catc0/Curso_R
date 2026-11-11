# ============================================================
# ejemplos/05_visualizacion.R
# Módulo 6: estadística descriptiva, resúmenes y gráficas.
# Guarda las gráficas en salidas/graficas/.
# Desde PowerShell: Rscript ejemplos/05_visualizacion.R
# ============================================================

library(ggplot2)
source(file.path("scripts", "validar_datos.R"), encoding = "UTF-8")
source(file.path("dashboard", "graficas.R"), encoding = "UTF-8")

programas <- cargar_datos(file.path("datos", "datos.xlsx"))
carpeta <- file.path("salidas", "graficas")
dir.create(carpeta, recursive = TRUE, showWarnings = FALSE)

# 1. ESTADÍSTICA DESCRIPTIVA ----------------------------------
print(summary(programas$TOTAL_APOYOS))
cat("Desviación estándar de apoyos:", round(sd(programas$TOTAL_APOYOS, na.rm = TRUE), 2), "\n")

# 2. RESÚMENES POR GRUPO --------------------------------------
print(aggregate(AVANCE_GLOBAL ~ ANIO, data = programas, FUN = mean))
print(aggregate(TOTAL_APOYOS ~ TIPO, data = programas, FUN = sum))

# 3. INDICADORES ----------------------------------------------
kpis <- calcular_kpis(programas)
cat("Programas:", kpis$total_programas,
    "| Completos:", kpis$completos,
    "| Avance global:", formato_pct(kpis$avance_global), "\n")

# 4. GRÁFICAS CON GGPLOT2 -------------------------------------
# Pregunta: ¿cómo se distribuye el total de apoyos?
g_hist <- ggplot(programas[!is.na(programas$TOTAL_APOYOS), ], aes(x = TOTAL_APOYOS)) +
  geom_histogram(binwidth = 1, fill = "#1a9ba1", color = "white") +
  labs(title = "Distribución del total de apoyos", x = "Apoyos", y = "Programas") +
  theme_minimal()
ggsave(file.path(carpeta, "histograma_apoyos.png"), g_hist, width = 7, height = 4, dpi = 150)

# Pregunta: ¿cuántos programas hay por tipo y año?
g_tipo_anio <- ggplot(programas, aes(x = TIPO, fill = factor(ANIO))) +
  geom_bar(position = "dodge") +
  scale_fill_manual(values = c("#7fd1d4", "#0e6e73"), name = "Año") +
  labs(title = "Programas por tipo y año", x = "Tipo", y = "Programas") +
  theme_minimal()
ggsave(file.path(carpeta, "programas_tipo_anio.png"), g_tipo_anio, width = 7, height = 4, dpi = 150)

# 5. LAS GRÁFICAS DEL DASHBOARD -------------------------------
graficas <- list(
  avance_dependencia = grafica_avance_dependencia(programas),
  estatus            = grafica_estatus(programas),
  tipo               = grafica_tipo(programas),
  comparativo_anio   = grafica_comparativo_anio(programas),
  top_dependencias   = grafica_top_dependencias(programas),
  responsables       = grafica_responsables(programas)
)
for (nombre in names(graficas)) {
  ggsave(file.path(carpeta, paste0(nombre, ".png")), graficas[[nombre]],
         width = 8, height = 5, dpi = 150, bg = "white")
}
cat("Gráficas guardadas en", normalizePath(carpeta), "\n")
