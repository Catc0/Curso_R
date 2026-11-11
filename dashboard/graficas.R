# ============================================================
# dashboard/graficas.R
# Cálculo de indicadores (KPI) y funciones de gráficas con ggplot2.
# Lo usa dashboard/app.R y también puede usarse desde un .Rmd.
# ============================================================

# 1. COLORES (tomados de la imagen de referencia) -------------
COLORES <- list(
  principal = "#1a9ba1",
  oscuro    = "#0e6e73",
  claro     = "#7fd1d4",
  muy_claro = "#c9eef0",
  texto     = "#2c3e50",
  gris      = "#b8c4cc"
)
PALETA <- c("#0e6e73", "#1a9ba1", "#5cc3c8", "#a6e1e3", "#d4eff0", "#b8c4cc")

# 2. FORMATOS -------------------------------------------------
formato_pct <- function(x, decimales = 1) {
  ifelse(is.na(x), "Sin dato", paste0(formatC(x * 100, format = "f", digits = decimales), "%"))
}

formato_entero <- function(x) {
  formatC(x, format = "d", big.mark = ",")
}

# Promedio que devuelve NA (y no NaN) cuando no hay datos.
promedio <- function(x) {
  if (all(is.na(x))) NA_real_ else mean(x, na.rm = TRUE)
}

# 3. INDICADORES ----------------------------------------------
calcular_kpis <- function(d) {
  list(
    total_programas = nrow(d),
    completos       = sum(d$COMPLETO),
    con_avance      = sum(d$CON_AVANCE),
    total_apoyos    = sum(d$TOTAL_APOYOS, na.rm = TRUE),
    avance_programa = promedio(d$AVANCE_PROGRAMA),
    avance_apoyos   = promedio(d$AVANCE_APOYOS),
    avance_global   = promedio(d$AVANCE_GLOBAL)
  )
}

# 4. TEMA COMÚN -----------------------------------------------
tema_dashboard <- function() {
  ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      text = ggplot2::element_text(color = COLORES$texto),
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      legend.position = "bottom",
      plot.margin = ggplot2::margin(5, 15, 5, 5)
    )
}

# 5. GRÁFICAS -------------------------------------------------
# Todas reciben el data frame ya filtrado.

# Pregunta: ¿qué dependencias tienen mayor y menor avance global?
grafica_avance_dependencia <- function(d) {
  d <- d[!is.na(d$AVANCE_GLOBAL), ]
  if (nrow(d) == 0) return(NULL)
  resumen <- aggregate(AVANCE_GLOBAL ~ DEPENDENCIA_CORTA, data = d, FUN = mean)
  resumen$DEPENDENCIA_CORTA <- reorder(resumen$DEPENDENCIA_CORTA, resumen$AVANCE_GLOBAL)

  ggplot2::ggplot(resumen, ggplot2::aes(x = AVANCE_GLOBAL, y = DEPENDENCIA_CORTA)) +
    ggplot2::geom_col(fill = COLORES$principal, width = 0.7) +
    ggplot2::geom_text(ggplot2::aes(label = formato_pct(AVANCE_GLOBAL)),
                       hjust = -0.1, size = 3.2, color = COLORES$texto) +
    ggplot2::scale_x_continuous(labels = function(x) formato_pct(x, 0),
                                limits = c(0, 1.25), breaks = seq(0, 1, 0.25)) +
    ggplot2::labs(x = "Avance global promedio", y = NULL) +
    tema_dashboard()
}

# Gráfica de dona reutilizable. 'conteo' tiene columnas categoria y n.
grafica_dona <- function(conteo, texto_centro) {
  conteo <- conteo[conteo$n > 0, ]
  if (nrow(conteo) == 0) return(NULL)
  total <- sum(conteo$n)
  colores <- rep(PALETA, length.out = nrow(conteo))

  ggplot2::ggplot(conteo, ggplot2::aes(x = 2, y = n, fill = categoria)) +
    ggplot2::geom_col(width = 1, color = "white") +
    ggplot2::coord_polar(theta = "y") +
    ggplot2::xlim(0.5, 2.5) +
    ggplot2::annotate("text", x = 0.5, y = 0,
                      label = paste0(formato_entero(total), "\n", texto_centro),
                      size = 4.5, fontface = "bold", lineheight = 0.9, color = COLORES$texto) +
    ggplot2::scale_fill_manual(values = colores, name = NULL,
                               labels = paste0(conteo$categoria, " (", conteo$n, ")")) +
    ggplot2::guides(fill = ggplot2::guide_legend(ncol = 1)) +
    ggplot2::theme_void(base_size = 12) +
    ggplot2::theme(legend.position = "bottom")
}

contar <- function(x) {
  tabla <- table(x)
  # factor con los niveles en el orden de la tabla, para que la leyenda lo respete
  data.frame(categoria = factor(names(tabla), levels = names(tabla)), n = as.integer(tabla))
}

# Pregunta: ¿en qué etapa de captura están los programas?
grafica_estatus <- function(d) grafica_dona(contar(d$ESTATUS_ETIQUETA), "programas")

# Pregunta: ¿qué tipos de programa predominan?
grafica_tipo <- function(d) grafica_dona(contar(d$TIPO_ETIQUETA), "programas")

# Pregunta: ¿mejoró o empeoró el avance de un año a otro?
grafica_comparativo_anio <- function(d) {
  if (nrow(d) == 0) return(NULL)
  indicadores <- c(
    AVANCE_PROGRAMA = "Avance programa",
    AVANCE_APOYOS   = "Avance apoyos",
    AVANCE_GLOBAL   = "Avance global"
  )
  filas <- list()
  for (anio in sort(unique(d$ANIO))) {
    for (columna in names(indicadores)) {
      filas[[length(filas) + 1]] <- data.frame(
        anio = as.character(anio),
        indicador = indicadores[[columna]],
        valor = promedio(d[[columna]][d$ANIO == anio])
      )
    }
  }
  resumen <- do.call(rbind, filas)
  resumen <- resumen[!is.na(resumen$valor), ]
  if (nrow(resumen) == 0) return(NULL)
  resumen$indicador <- factor(resumen$indicador, levels = indicadores)

  ggplot2::ggplot(resumen, ggplot2::aes(x = indicador, y = valor, fill = anio)) +
    ggplot2::geom_col(position = ggplot2::position_dodge(width = 0.8), width = 0.7) +
    ggplot2::geom_text(ggplot2::aes(label = formato_pct(valor)),
                       position = ggplot2::position_dodge(width = 0.8),
                       vjust = -0.4, size = 3.3, color = COLORES$texto) +
    ggplot2::scale_fill_manual(values = rep(c(COLORES$claro, COLORES$oscuro, COLORES$principal),
                                            length.out = length(unique(resumen$anio))),
                               name = "Año") +
    ggplot2::scale_y_continuous(labels = function(x) formato_pct(x, 0),
                                limits = c(0, 1.12), breaks = seq(0, 1, 0.25)) +
    ggplot2::labs(x = NULL, y = NULL) +
    tema_dashboard() +
    ggplot2::theme(panel.grid.major.x = ggplot2::element_blank(),
                   panel.grid.major.y = ggplot2::element_line(color = "#e5e9ec"))
}

# Pregunta: ¿qué dependencias concentran más programas?
grafica_top_dependencias <- function(d, n = 10) {
  if (nrow(d) == 0) return(NULL)
  conteo <- contar(d$DEPENDENCIA_CORTA)
  conteo <- head(conteo[order(-conteo$n), ], n)
  conteo$categoria <- reorder(conteo$categoria, conteo$n)

  ggplot2::ggplot(conteo, ggplot2::aes(x = n, y = categoria)) +
    ggplot2::geom_col(fill = COLORES$principal, width = 0.7) +
    ggplot2::geom_text(ggplot2::aes(label = n), hjust = -0.3, size = 3.5, color = COLORES$texto) +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0, 0.12))) +
    ggplot2::labs(x = "Número de programas", y = NULL) +
    tema_dashboard()
}

# Pregunta: ¿cuántos programas no tienen responsable asignado?
grafica_responsables <- function(d) {
  if (nrow(d) == 0) return(NULL)
  faltantes <- data.frame(
    responsable = c("Titular RP faltante", "Informante faltante"),
    n = c(sum(is.na(d$TITULAR_RP)), sum(is.na(d$INFORMANTE)))
  )
  faltantes$responsable <- factor(faltantes$responsable, levels = faltantes$responsable)

  ggplot2::ggplot(faltantes, ggplot2::aes(x = responsable, y = n)) +
    ggplot2::geom_col(fill = COLORES$principal, width = 0.55) +
    ggplot2::geom_text(ggplot2::aes(label = n), vjust = -0.4, size = 5,
                       fontface = "bold", color = COLORES$texto) +
    ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0, 0.15))) +
    ggplot2::labs(x = NULL, y = "Programas") +
    tema_dashboard() +
    ggplot2::theme(panel.grid.major.x = ggplot2::element_blank(),
                   panel.grid.major.y = ggplot2::element_line(color = "#e5e9ec"))
}
