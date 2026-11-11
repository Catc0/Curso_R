# ============================================================
# instalar_entorno.ps1
# Instala R, RStudio Desktop y Pandoc en Windows con winget
# y después instala los paquetes de R del proyecto.
#
# Cómo ejecutarlo (PowerShell, dentro de la carpeta proyecto_r):
#   powershell -ExecutionPolicy Bypass -File .\instalar_entorno.ps1
#
# Requisitos: Windows 10/11 con winget (App Installer) e Internet.
# Algunos instaladores pueden pedir permisos de administrador.
# ============================================================

$ErrorActionPreference = "Stop"

function Escribir-Paso($texto) {
    Write-Host ""
    Write-Host "==> $texto" -ForegroundColor Cyan
}

# 1. Verificar winget ----------------------------------------
Escribir-Paso "Verificando winget"
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "No se encontró winget. Instala 'App Installer' desde Microsoft Store y vuelve a ejecutar este script." -ForegroundColor Red
    exit 1
}
winget --version

# 2. Instalar programas ---------------------------------------
$programas = @(
    @{ Id = "RProject.R";            Nombre = "R" },
    @{ Id = "Posit.RStudio";         Nombre = "RStudio Desktop" },
    @{ Id = "JohnMacFarlane.Pandoc"; Nombre = "Pandoc (para generar HTML desde PowerShell)" }
)

foreach ($p in $programas) {
    Escribir-Paso "Instalando $($p.Nombre)"
    $instalado = winget list --id $p.Id --exact --accept-source-agreements | Select-String $p.Id
    if ($instalado) {
        Write-Host "$($p.Nombre) ya está instalado."
    } else {
        winget install --id $p.Id --exact --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) {
            Write-Host "winget devolvió el código $LASTEXITCODE al instalar $($p.Nombre)." -ForegroundColor Yellow
        }
    }
}

# 3. Localizar Rscript ----------------------------------------
# El instalador de R no agrega R al PATH, así que lo buscamos.
Escribir-Paso "Buscando Rscript.exe"
$rscript = Get-Command Rscript -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
if (-not $rscript) {
    $rscript = Get-ChildItem "C:\Program Files\R\R-*\bin\Rscript.exe", "$env:LOCALAPPDATA\Programs\R\R-*\bin\Rscript.exe" -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending | Select-Object -First 1 -ExpandProperty FullName
}
if (-not $rscript) {
    Write-Host "No se encontró Rscript.exe. Cierra y abre PowerShell, o revisa que R se instaló en C:\Program Files\R." -ForegroundColor Red
    exit 1
}
Write-Host "Rscript encontrado en: $rscript"

# Agregar R al PATH solo para esta sesión de PowerShell.
$env:Path = (Split-Path $rscript) + ";" + $env:Path

# 4. Verificar versiones --------------------------------------
Escribir-Paso "Versiones instaladas"
& $rscript --version
if (Get-Command pandoc -ErrorAction SilentlyContinue) { pandoc --version | Select-Object -First 1 }
else { Write-Host "Pandoc aún no está en el PATH de esta sesión; abre una nueva ventana de PowerShell." -ForegroundColor Yellow }

# 5. Instalar paquetes de R -----------------------------------
Escribir-Paso "Instalando paquetes de R (requirements.R)"
Set-Location $PSScriptRoot
& $rscript requirements.R
if ($LASTEXITCODE -ne 0) {
    Write-Host "Falló la instalación de paquetes. Revisa los mensajes anteriores." -ForegroundColor Red
    exit 1
}

# 6. Validar datos ---------------------------------------------
Escribir-Paso "Validando datos/datos.xlsx"
& $rscript scripts/validar_datos.R

Escribir-Paso "Listo"
Write-Host "Siguiente paso: abre proyecto_r.Rproj en RStudio, o ejecuta:"
Write-Host "  Rscript scripts/generar_documentacion.R   # genera el manual y las demos en HTML"
Write-Host "  Rscript scripts/generar_dashboard.R       # inicia el dashboard"
Write-Host ""
Write-Host "Para usar Rscript en cualquier ventana, agrega esta carpeta al PATH de usuario:"
Write-Host "  $(Split-Path $rscript)"
