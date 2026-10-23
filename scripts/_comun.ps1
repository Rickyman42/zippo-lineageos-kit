# Funciones compartidas por los scripts. No se ejecuta solo.

function Buscar-Adb {
    param([string]$Adb)
    $candidatos = @()
    if ($Adb) { $candidatos += $Adb }
    $candidatos += Join-Path (Split-Path $PSScriptRoot -Parent) 'descargas\platform-tools\adb.exe'
    $candidatos += "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
    foreach ($c in $candidatos) { if ($c -and (Test-Path $c)) { return (Resolve-Path $c).Path } }
    $enPath = Get-Command adb.exe -ErrorAction SilentlyContinue
    if ($enPath) { return $enPath.Source }
    throw "No encuentro adb.exe. Ejecuta primero descargar-oficial.ps1, o pasa la ruta con -Adb."
}

# Comprueba que hay UN movil conectado, que es el zippo y que su almacenamiento es legible.
function Comprobar-Zippo {
    param([string]$Adb, [switch]$SinAlmacenamiento)
    $conectados = @(& $Adb devices) | Where-Object { $_ -match "`tdevice$" }
    if ($conectados.Count -eq 0) {
        throw 'No hay ningun movil conectado. Comprueba el cable, que la depuracion USB este activada y que hayas aceptado el aviso en el movil (adb devices no deberia decir "unauthorized").'
    }
    if ($conectados.Count -gt 1) { throw "Hay $($conectados.Count) dispositivos conectados. Deja solo el movil." }
    $d = "$(& $Adb -d shell getprop ro.product.device)".Trim()
    if ($d -ne 'zippo') { throw "El dispositivo conectado no es un Z6 Pro (ro.product.device = '$d'). Estos scripts no sirven para el." }
    if (-not $SinAlmacenamiento) {
        if ("$(& $Adb -d shell 'ls /sdcard | head -1')".Trim() -eq '') {
            throw 'El almacenamiento no es legible: desbloquea el movil con el PIN y vuelve a intentarlo.'
        }
    }
}
