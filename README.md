---
title: "Proyecto: Curso de R → Dashboard dinámico"
lang: es
---

# Curso de R: de la instalación al dashboard dinámico

Proyecto educativo que enseña R desde la instalación hasta la construcción de un dashboard interactivo con los datos de `datos/datos.xlsx`, siguiendo el diseño de referencia `manual/recursos/dashboard.png`.

## Inicio rápido (Windows)

En **PowerShell**, dentro de esta carpeta:

```powershell
# 1. Instalar R, RStudio, Pandoc y los paquetes (una sola vez)
powershell -ExecutionPolicy Bypass -File .\instalar_entorno.ps1

# 2. Validar los datos
Rscript scripts/validar_datos.R

# 3. Generar el manual, las demos y los informes en HTML
Rscript scripts/generar_documentacion.R

# 4. Generar salidas/dashboard.html e iniciar el dashboard interactivo
#    (se abre en el navegador; Ctrl + C para detenerlo)
Rscript scripts/generar_dashboard.R
#    Solo el HTML, sin iniciar el servidor:
Rscript scripts/generar_dashboard.R --solo-html
```

Si `Rscript` no se reconoce, usa la ruta completa (`& "C:\Program Files\R\R-4.x.x\bin\Rscript.exe"`) o agrega esa carpeta al PATH (ver el módulo 0 del manual).

En **RStudio**: abre `proyecto_r.Rproj` y ejecuta en la consola:

```r
source("requirements.R")                  # paquetes
source("scripts/generar_documentacion.R") # HTML
shiny::runApp("dashboard")                # dashboard
```

## Estructura

| Ruta | Contenido |
|---|---|
| `proyecto_r.Rproj` | Proyecto de RStudio (fija la carpeta de trabajo) |
| `instalar_entorno.ps1` | Instala R, RStudio y Pandoc con winget, y luego los paquetes |
| `requirements.R` | Lista central de paquetes: instala los faltantes y registra versiones |
| `datos/datos.xlsx` | Copia de los datos originales (no se modifica) |
| `manual/index.Rmd` | Manual completo; genera `manual/index.html` |
| `manual/modulos/*.Rmd` | Contenido de cada módulo (lo usan el manual y las demos) |
| `manual/estilos.css`, `manual/recursos/` | Estilos, buscador del menú (JS) e imagen de referencia |
| `ejemplos/*.R` | Scripts por tema, ejecutables con `Rscript` |
| `demos/0*.Rmd` | Una demo HTML por módulo |
| `demos/informe_parametrizado.Rmd` | Informe con parámetro `anio` (ejemplo completo de R Markdown) |
| `dashboard/app.R` | Dashboard Shiny (UI y servidor) |
| `dashboard/graficas.R` | Indicadores y gráficas (ggplot2), reutilizables fuera de Shiny |
| `dashboard/estilos.css` | Diseño del dashboard (CSS Grid adaptable) |
| `dashboard/dashboard_estatico.Rmd`, `estilos_estatico.css` | Versión HTML fija del dashboard; genera `salidas/dashboard.html` |
| `scripts/validar_datos.R` | Lectura, limpieza y validación del Excel |
| `scripts/generar_documentacion.R` | Genera todos los HTML |
| `scripts/generar_dashboard.R` | Genera `salidas/dashboard.html` e inicia el dashboard |
| `salidas/` | Archivos generados: demos, informes, CSV y gráficas |

## Temario

0. Instalación y configuración (PowerShell, RStudio, paquetes, errores frecuentes)
1. Fundamentos de R
2. Estructuras de datos e importación de Excel
3. RStudio y productividad (incluye una tabla de atajos para Windows y macOS)
4. Markdown y R Markdown
5. HTML, CSS y contenido dinámico
6. Análisis y visualización con ggplot2
7. Dashboard dinámico

## Dependencias

| Componente | Versión mínima | Uso |
|---|---|---|
| R | 4.2.0 | UTF-8 nativo en Windows. Versión en winget al 11/11/2026: 4.6.2 (`RProject.R`) |
| RStudio Desktop | cualquiera reciente | Editor (winget: `Posit.RStudio`) |
| Pandoc | 1.12.3 | Genera HTML (incluido en RStudio; winget: `JohnMacFarlane.Pandoc`) |
| readxl, ggplot2, rmarkdown, knitr, shiny, bslib | las de CRAN vigentes | Ver `requirements.R` |

`requirements.R` guarda las versiones instaladas en `salidas/versiones.csv`.

**Necesitan Internet:** la instalación (winget y CRAN) y nada más. El manual, las demos y el dashboard funcionan sin conexión. El dashboard carga los iconos de Font Awesome desde el paquete `shiny`, sin Internet.

## Interactividad: qué funciona sin R

| Salida | Tipo | ¿Necesita R en ejecución? |
|---|---|---|
| `manual/index.html` | HTML estático con navegación (menú, buscador, soluciones plegables) | No |
| `salidas/demos/*.html`, `salidas/informe_*.html` | HTML estático | No |
| `salidas/dashboard.html` | HTML autónomo (~1 MB) con el mismo diseño: KPI, 6 gráficas y tabla. **Sin filtros**: pestañas fijas "Todos los años", 2024 y 2025 calculadas al generarlo | No |
| Dashboard (`dashboard/app.R`) | Interactivo: los filtros recalculan KPI, gráficas y tabla | **Sí** (servidor Shiny local) |

## Datos: hallazgos y supuestos

Diagnóstico de `datos.xlsx`, hoja `Exportar Hoja de Trabajo` (250 programas, 17 columnas, 19 dependencias, años 2024 y 2025):

- Los avances (`AVANCE_*`) y `TOTAL_APOYOS` están guardados como **texto** y se convierten a número. Las celdas vacías (`" "`) se convierten en `NA`.
- `AVANCE_GLOBAL` es el promedio de `AVANCE_PROGRAMA` y `AVANCE_APOYOS`, según la hoja `SQL`. Se verificó en los 231 programas que tienen ambos valores.
- 19 programas no tienen avance de apoyos ni avance global; se excluyen de los promedios (no se cuentan como 0).
- `TITULAR_RP` falta en 79 programas; `INFORMANTE`, en 2.
- No hay claves duplicadas por año y `TIPO` coincide siempre con el tercer carácter de `CLAVE`.

**Definiciones confirmadas y supuestos:**

| Tema | Definición | Estado | Dónde se cambia |
|---|---|---|---|
| `ESTATUS` | 0 Sin ingreso o captura · 1 Pendiente · 2 Liberado Informante · 3 Liberado Titular RP · 4 Liberado Titular AE (el 4 no aparece en este Excel) | Confirmado | `ETIQUETAS_ESTATUS` en `scripts/validar_datos.R` |
| `TIPO` | B Provisión de bienes públicos · E Prestación de servicios públicos · S Sujetos a reglas de operación · U Otros subsidios | Confirmado | `ETIQUETAS_TIPO` en `scripts/validar_datos.R` |
| Escala de avances | Proporción: 1 = 100 % | Confirmado | — |
| Programa completo | Avance global = 100 % | Confirmado | `cargar_datos()` |
| Programa con avance | 0 % < avance global < 100 % (no incluye los completos) | Supuesto | `cargar_datos()` |
| Total de apoyos | Suma de `TOTAL_APOYOS` | `calcular_kpis()` en `dashboard/graficas.R` |
| Avances (KPI) | Promedio simple entre programas | `calcular_kpis()` |

## Diferencias con la imagen de referencia

- Las cifras de la imagen (258 programas, etc.) son de otra extracción. El dashboard calcula todo a partir de `datos.xlsx`.
- Se respetaron la distribución (fila de 7 KPI, filtros a la izquierda, cuadrícula de 6 gráficas), los tipos de gráfica y la paleta turquesa. Los iconos son equivalentes de Font Awesome.
- El filtro de año usa casillas, como en la imagen. Dependencia y tipo usan listas desplegables con la opción "Todas/Todos".
- Se agregó una tabla de detalle debajo de las gráficas, que también responde a los filtros.

## Limitaciones conocidas

- El dashboard necesita R en ejecución. Para publicarlo en la web haría falta un servidor (por ejemplo, Shiny Server o Posit Connect), que no forma parte de este proyecto.
- Los nombres largos de dependencias se abrevian en las gráficas (sigla entre paréntesis o 34 caracteres).
- El buscador del manual filtra los títulos del menú. Para buscar en el texto completo se usa `Ctrl + F`.

## Estado de las pruebas

Pruebas realizadas el 11/11/2026 en Windows 11 con R 4.6.2, Pandoc 3.13, readxl 1.6.0, ggplot2 4.0.3, rmarkdown 2.32, knitr 1.52, shiny 1.14.0 y bslib 0.12.0:

| Prueba | Resultado |
|---|---|
| `Rscript requirements.R` | OK. Instala en la librería personal si `C:\Program Files\R` no admite escritura |
| `Rscript scripts/validar_datos.R` | Las 11 revisiones salen `OK` |
| `Rscript ejemplos/01…05_*.R` | Los 5 terminan sin errores; generan `salidas/programas_limpios.csv` y `salidas/graficas/*.png` |
| `Rscript scripts/generar_documentacion.R` | Los 9 documentos salen `OK`: manual, 5 demos, 2 informes y README |
| Lógica del dashboard (`shiny::testServer`) | Los KPI coinciden con los valores esperados; los filtros de año, dependencia y tipo recalculan; sin años aparece el mensaje de estado vacío; las 6 gráficas y la tabla se generan |
| Dashboard en el navegador (Edge sin interfaz) | Se revisó la distribución a 1700 px (3 columnas) y a 600 px (1 columna) |
| `Rscript scripts/generar_dashboard.R --solo-html` | Genera `salidas/dashboard.html`; KPI de "Todos los años" iguales a los del dashboard Shiny; revisado en Edge a 1700 px y 600 px |

**No probado:**

- La instalación de RStudio con `instalar_entorno.ps1`: R y Pandoc se instalaron con winget, pero RStudio no.
- Los clics reales sobre los controles en un navegador: los filtros se probaron con `testServer`.
- La ejecución con macOS o Linux.

Valores con todos los filtros activos: 250 programas, 170 completos, 61 con avance, 770 apoyos, avance programa 93.5 %, avance apoyos 95.0 %, avance global 97.2 %.
