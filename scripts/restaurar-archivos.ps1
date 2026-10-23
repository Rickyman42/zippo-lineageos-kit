# Devuelve al movil los archivos de una copia hecha con copiar-y-verificar.ps1.
#
# CUANDO: con el sistema ya instalado, el movil desbloqueado, las aplicaciones YA INSTALADAS por Seedvault
# y ANTES de abrir WhatsApp por primera vez.
# Por que ese momento: Android borra Android/media/<app> cuando la aplicacion se instala.
#
# Uso:  powershell -ExecutionPolicy Bypass -File restaurar-archivos.ps1 [-Copia <carpeta>] [-Verificar]
param(
    [string]$Copia,
    [switch]$Verificar,
    [string]$Adb
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
. (Join-Path $PSScriptRoot '_comun.ps1')
$adb = Buscar-Adb $Adb

if (-not $Copia) {
    $puntero = Join-Path (Split-Path $PSScriptRoot -Parent) 'copias\ULTIMA-COPIA.txt'
    if (-not (Test-Path $puntero)) { throw "No se que copia usar. Pasala con -Copia <carpeta>." }
    $Copia = (Get-Content $puntero -Raw).Trim()
}
$root = "$Copia\almacenamiento-compartido\sdcard"
if (-not (Test-Path $root)) { throw "No existe la copia: $root" }
Comprobar-Zippo $adb

$log = "$Copia\restauracion-log.txt"
& $adb -d shell svc power stayon usb | Out-Null

foreach ($i in Get-ChildItem $root -Force) {
    if ($i.Name -eq 'Android') { continue }
    Write-Host "  $($i.Name)"
    "=== $($i.Name) $(Get-Date -Format HH:mm:ss)" | Add-Content $log
    (& $adb -d push $i.FullName '/sdcard/' 2>&1) | Select-Object -Last 2 | Add-Content $log
}

& $adb -d shell 'mkdir -p /sdcard/Android/media'
foreach ($p in Get-ChildItem "$root\Android\media" -Directory -ErrorAction SilentlyContinue) {
    Write-Host "  Android/media/$($p.Name)"
    "=== Android/media/$($p.Name) $(Get-Date -Format HH:mm:ss)" | Add-Content $log
    (& $adb -d push $p.FullName '/sdcard/Android/media/' 2>&1) | Select-Object -Last 2 | Add-Content $log
}

# Para que la galeria vea las fotos devueltas.
& $adb -d shell 'am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/DCIM' | Out-Null

# Comprobacion opcional: que cada archivo del PC esta en el movil con el mismo tamano.
# Util sobre todo DESPUES de que WhatsApp restaure, porque reorganiza su carpeta y deja archivos fuera.
if ($Verificar) {
    Write-Host "Verificando lo que hay ahora en el movil..."
    & $adb -d shell "cd /sdcard && find . -type f -not -path './Android/data/*' -exec stat -c '%s|%n' {} + > /data/local/tmp/lista2.txt"
    & $adb -d pull /data/local/tmp/lista2.txt "$Copia\lista-movil-tras-restaurar.txt" | Out-Null
    & $adb -d shell rm /data/local/tmp/lista2.txt
    $phone = @{}
    Get-Content "$Copia\lista-movil-tras-restaurar.txt" -Encoding utf8 | ForEach-Object {
        $i = $_.IndexOf('|')
        if ($i -gt 0) { $phone[$_.Substring($i + 3).Normalize()] = [int64]$_.Substring(0, $i) }
    }
    $faltan = @()
    Get-ChildItem $root -Recurse -File -Force | ForEach-Object {
        $rel = $_.FullName.Substring($root.Length + 1).Replace('\', '/').Normalize()
        if (-not $phone.ContainsKey($rel) -or $phone[$rel] -ne $_.Length) { $faltan += $rel }
    }
    if ($faltan.Count) {
        $faltan | Set-Content "$Copia\faltan-en-el-movil.txt" -Encoding utf8
        Write-Host "FALTAN O NO COINCIDEN $($faltan.Count) archivos. Lista en $Copia\faltan-en-el-movil.txt" -ForegroundColor Yellow
        Write-Host "Vuelve a enviarlos con adb push; en este punto la aplicacion ya no los borra."
    } else {
        Write-Host "Todo coincide con la copia." -ForegroundColor Green
    }
}

Get-Content $log -Tail 10
Write-Host "`nARCHIVOS DEVUELTOS. Log: $log" -ForegroundColor Green
Write-Host "Ahora si: abre WhatsApp, verifica el numero y elige Restaurar. No cortes la red."
