# Solo lectura: dice en que estado esta el movil. No cambia NADA.
# Uso:  powershell -ExecutionPolicy Bypass -File comprobar-dispositivo.ps1 [-Adb <ruta a adb.exe>]
param([string]$Adb)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_comun.ps1')
$adb = Buscar-Adb $Adb
Comprobar-Zippo $adb -SinAlmacenamiento

function Prop($p) { "$(& $adb -d shell getprop $p)".Trim() }

$sdcard = "$(& $adb -d shell 'ls /sdcard | head -1')".Trim()
$bat = "$(& $adb -d shell 'dumpsys battery | grep -E "level|status"')" -replace '\s+', ' '
$espacio = @(& $adb -d shell 'df -h /data | tail -1') -join ' '

[pscustomobject][ordered]@{
    'Modelo'                  = Prop ro.product.model
    'Nombre en clave'         = Prop ro.product.device
    'Android'                 = Prop ro.build.version.release
    'Compilacion'             = Prop ro.build.display.id
    'Parche de seguridad'     = Prop ro.build.version.security_patch
    'LineageOS'               = (Prop ro.lineage.version)
    'Firmware base (vendor)'  = (Prop ro.vendor.build.version.release) + ' / ' + (Prop ro.vendor.build.security_patch)
    'Almacenamiento legible'  = $(if ($sdcard) { 'si' } else { 'NO (desbloquea el movil)' })
    'Bateria'                 = $bat.Trim()
    'Espacio en /data'        = $espacio
} | Format-List

Write-Host "== Bootloader" -ForegroundColor Cyan
Write-Host "Las propiedades del sistema MIENTEN en muchas ROMs personalizadas. Esto es solo informativo:"
Write-Host ("  ro.boot.flash.locked      = " + (Prop ro.boot.flash.locked))
Write-Host ("  ro.boot.verifiedbootstate = " + (Prop ro.boot.verifiedbootstate))
Write-Host "Para saberlo de verdad: mira si la pantalla de arranque dice 'The boot loader is unlocked', o"
Write-Host "reinicia en fastboot (adb reboot bootloader) y ejecuta:  fastboot getvar unlocked"

Write-Host "`n== Copias de seguridad" -ForegroundColor Cyan
$sv = "$(& $adb -d shell 'ls -d /sdcard/.SeedVaultAndroidBackup 2>/dev/null')".Trim()
Write-Host ("  Carpeta de Seedvault en el movil: " + $(if ($sv) { 'si (acuerdate de sacarla al PC)' } else { 'no' }))
$apps = @(& $adb -d shell 'pm list packages -3').Count
Write-Host "  Aplicaciones instaladas por ti: $apps"
$arch = "$(& $adb -d shell "find /sdcard -type f -not -path '/sdcard/Android/data/*' -not -path '/sdcard/.SeedVaultAndroidBackup/*' | wc -l")".Trim()
Write-Host "  Archivos que se copiarian al PC: $arch"
