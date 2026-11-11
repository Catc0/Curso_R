# ============================================================
# dashboard/app.R
# Dashboard interactivo de avance de programas (Shiny + bslib).
#
# Cómo iniciarlo (con proyecto_r como directorio de trabajo):
#   - En R / RStudio:  shiny::runApp("dashboard")
#   - En PowerShell:   Rscript scripts/generar_dashboard.R
#
# Shiny ejecuta este código en R (servidor) y envía HTML/CSS/JS
# al navegador. Cada vez que cambias un filtro, el navegador avisa
# a R, R recalcula y devuelve los indicadores y gráficas nuevos.
# ============================================================

library(shiny)
library(bslib)
library(ggplot2)

# runApp("dashboard") fija el directorio de trabajo en dashboard/,
# por eso las rutas suben un nivel con "..".
source(file.path("..", "scripts", "validar_datos.R"), encoding = "UTF-8")
source("graficas.R", encoding = "UTF-8")

programas <- cargar_datos(file.path("..", "datos", "datos.xlsx"))

anios <- sort(unique(programas$ANIO))
dependencias <- sort(unique(programas$DEPENDENCIA))
tipos <- levels(programas$TIPO_ETIQUETA)
fecha_corte <- format(max(programas$ULTIMA_MODIFICACION, na.rm = TRUE), "%d/%m/%Y")

MENSAJE_VACIO <- "No hay programas que cumplan los filtros seleccionados."

# Tarjeta de indicador (KPI): icono + título + valor.
tarjeta_kpi <- function(id, titulo, icono) {
  div(
    class = "kpi",
    div(class = "kpi-icono", icon(icono)),
    div(
      class = "kpi-texto",
      div(class = "kpi-titulo", titulo),
      div(class = "kpi-valor", textOutput(id, inline = TRUE))
    )
  )
}

# Tarjeta para una gráfica.
tarjeta_grafica <- function(titulo, id, alto = "300px") {
  card(
    class = "tarjeta",
    card_header(titulo),
    card_body(plotOutput(id, height = alto))
  )
}

# 1. INTERFAZ (UI) --------------------------------------------
ui <- page_fluid(
  theme = bs_theme(
    version = 5,
    primary = COLORES$principal,
    bg = "#ffffff",   # fondo de tarjetas; el de la página está en estilos.css
    fg = COLORES$texto,
    base_font = font_collection("Segoe UI", "Roboto", "Arial", "sans-serif")
  ),
  title = "Dashboard de avance de programas",
  tags$head(includeCSS("estilos.css")),

  div(
    class = "encabezado",
    h1("Avance de programas"),
    span(class = "corte", paste("Última modificación registrada:", fecha_corte))
  ),

  # Fila de indicadores
  div(
    class = "fila-kpi",
    tarjeta_kpi("kpi_total", "Total programas", "list"),
    tarjeta_kpi("kpi_completos", "Programas completos", "circle-check"),
    tarjeta_kpi("kpi_avance", "Programas con avance", "chart-line"),
    tarjeta_kpi("kpi_apoyos", "Total apoyos", "hand-holding-heart"),
    tarjeta_kpi("kpi_av_programa", "Avance programa", "percent"),
    tarjeta_kpi("kpi_av_apoyos", "Avance apoyos", "percent"),
    tarjeta_kpi("kpi_av_global", "Avance global", "percent")
  ),

  div(
    class = "contenido",

    # Panel de filtros
    div(
      class = "filtros",
      h2(icon("filter"), "Filtros"),
      checkboxGroupInput("anio", "Año", choices = anios, selected = anios),
      selectInput("dependencia", "Dependencia",
                  choices = c("Todas", dependencias)),
      selectInput("tipo", "Tipo de programa",
                  choices = c("Todos", tipos)),
      actionButton("limpiar", "Limpiar filtros", icon = icon("rotate-left"),
                   class = "btn-primary w-100"),
      div(class = "conteo-filtro", textOutput("texto_filtro"))
    ),

    # Cuadrícula de gráficas
    div(
      class = "graficas",
      tarjeta_grafica("Avance global por dependencia", "g_avance_dep", "360px"),
      tarjeta_grafica("Distribución por estatus", "g_estatus", "360px"),
      tarjeta_grafica("Programas por tipo", "g_tipo", "360px"),
      tarjeta_grafica("Comparativo por año", "g_anio"),
      tarjeta_grafica("Top 10 dependencias con más programas", "g_top"),
      tarjeta_grafica("Responsables sin asignar", "g_responsables"),
      card(
        class = "tarjeta tarjeta-tabla",
        card_header("Detalle de programas"),
        card_body(div(class = "tabla-scroll", tableOutput("tabla")))
      )
    )
  )
)

# 2. SERVIDOR -------------------------------------------------
server <- function(input, output, session) {

  # Datos filtrados: se recalculan cuando cambia cualquier filtro.
  datos_filtrados <- reactive({
    d <- programas
    d <- d[d$ANIO %in% as.integer(input$anio), ]
    if (!is.null(input$dependencia) && input$dependencia != "Todas") {
      d <- d[d$DEPENDENCIA == input$dependencia, ]
    }
    if (!is.null(input$tipo) && input$tipo != "Todos") {
      d <- d[as.character(d$TIPO_ETIQUETA) == input$tipo, ]
    }
    d
  })

  kpis <- reactive(calcular_kpis(datos_filtrados()))

  observeEvent(input$limpiar, {
    updateCheckboxGroupInput(session, "anio", selected = anios)
    updateSelectInput(session, "dependencia", selected = "Todas")
    updateSelectInput(session, "tipo", selected = "Todos")
  })

  output$texto_filtro <- renderText({
    paste(nrow(datos_filtrados()), "de", nrow(programas), "programas")
  })

  # Indicadores
  output$kpi_total       <- renderText(formato_entero(kpis()$total_programas))
  output$kpi_completos   <- renderText(formato_entero(kpis()$completos))
  output$kpi_avance      <- renderText(formato_entero(kpis()$con_avance))
  output$kpi_apoyos      <- renderText(formato_entero(kpis()$total_apoyos))
  output$kpi_av_programa <- renderText(formato_pct(kpis()$avance_programa))
  output$kpi_av_apoyos   <- renderText(formato_pct(kpis()$avance_apoyos))
  output$kpi_av_global   <- renderText(formato_pct(kpis()$avance_global))

  # Dibuja una gráfica o muestra un mensaje si no hay datos.
  dibujar <- function(funcion) {
    renderPlot({
      d <- datos_filtrados()
      validate(need(nrow(d) > 0, MENSAJE_VACIO))
      grafica <- funcion(d)
      validate(need(!is.null(grafica), "No hay datos suficientes para esta gráfica."))
      grafica
    }, res = 96)
  }

  output$g_avance_dep    <- dibujar(grafica_avance_dependencia)
  output$g_estatus       <- dibujar(grafica_estatus)
  output$g_tipo          <- dibujar(grafica_tipo)
  output$g_anio          <- dibujar(grafica_comparativo_anio)
  output$g_top           <- dibujar(grafica_top_dependencias)
  output$g_responsables  <- dibujar(grafica_responsables)

  output$tabla <- renderTable({
    d <- datos_filtrados()
    validate(need(nrow(d) > 0, MENSAJE_VACIO))
    d <- d[order(d$DEPENDENCIA, d$CLAVE), ]
    data.frame(
      Clave = d$CLAVE,
      Programa = d$PROGRAMA,
      Dependencia = d$DEPENDENCIA_CORTA,
      `Año` = as.character(d$ANIO),
      Estatus = as.character(d$ESTATUS_ETIQUETA),
      `Avance global` = formato_pct(d$AVANCE_GLOBAL),
      `Titular RP` = ifelse(is.na(d$TITULAR_RP), "Sin asignar", d$TITULAR_RP),
      check.names = FALSE
    )
  }, striped = TRUE, hover = TRUE, spacing = "s", width = "100%")
}

shinyApp(ui, server)
