# Copia el almacenamiento del movil al PC y COMPRUEBA, archivo a archivo, que llego todo.
#
# Por que asi: empaquetar la copia en un tar por el cable (adb exec-out) se cortaba a mitad de un video
# DEVOLVIENDO EXITO. adb pull carpeta a carpeta, mas verificacion por nombre y tamano, es fiable.
#
# Uso:  powershell -ExecutionPolicy Bypass -File copiar-y-verificar.ps1 [-Destino D:\copias] [-IncluirSeedvault]
param(
    [string]$Destino = (Join-Path (Split-Path $PSScriptRoot -Parent) 'copias'),
    [switch]$IncluirSeedvault,
    [string]$Adb
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
. (Join-Path $PSScriptRoot '_comun.ps1')
$adb = Buscar-Adb $Adb
Comprobar-Zippo $adb

# Seedvault escribe su copia dentro del movil: si sigue trabajando, copiarla da una copia a medias.
# El texto de la notificacion depende del idioma del movil; aqui se buscan las variantes habituales.
if ($IncluirSeedvault) {
    $sv = "$(& $adb -d shell "dumpsys notification --noredact | grep -A40 'pkg=com.stevesoltys.seedvault' | grep -cE 'android.title=.*(ejecuci|Eliminando|running|Removing|Backing)'")".Trim()
    if ($sv -ne '0') { throw 'Seedvault sigue haciendo la copia. Espera a que desaparezca su notificacion.' }
}

# Que no se apague la pantalla a mitad de la copia.
& $adb -d shell svc power stayon usb | Out-Null

$dest = Join-Path $Destino (Get-Date -Format 'yyyyMMdd-HHmmss')
$root = "$dest\almacenamiento-compartido\sdcard"
New-Item -ItemType Directory "$root\Android\media", "$dest\extras" -Force | Out-Null
$log = "$dest\copia-log.txt"
Write-Host "Copiando en $dest"

# 1. Carpetas de primer nivel.
#    Android/data se excluye a proposito: es cache de aplicaciones, Android no deja leer casi nada de ahi,
#    y tiene nombres de archivo con caracteres que Windows no admite (eso rompio una copia).
$top = @(& $adb -d shell 'ls -A /sdcard') | ForEach-Object { $_.Trim() } |
    Where-Object { $_ -and $_ -notin 'Android', '.SeedVaultAndroidBackup' }
foreach ($t in $top) {
    Write-Host "  $t"
    "=== $t $(Get-Date -Format HH:mm:ss)" | Add-Content $log
    (& $adb -d pull -a "/sdcard/$t" "$root\" 2>&1) | Select-Object -Last 3 | Add-Content $log
}

# 2. Android/media: WhatsApp, WhatsApp Business, Telegram... (multimedia y copias locales de chats).
#    OJO: Android BORRA Android/media/<app> cuando esa app se instala. Al restaurar, devuelve esto
#    DESPUES de instalar las aplicaciones y ANTES de abrirlas.
$media = @(& $adb -d shell 'ls /sdcard/Android/media') | ForEach-Object { $_.Trim() } | Where-Object { $_ }
foreach ($p in $media) {
    Write-Host "  Android/media/$p"
    "=== Android/media/$p $(Get-Date -Format HH:mm:ss)" | Add-Content $log
    (& $adb -d pull -a "/sdcard/Android/media/$p" "$root\Android\media\" 2>&1) | Select-Object -Last 3 | Add-Content $log
}

# 3. Verificacion: cada archivo del movil tiene que estar en el PC con el mismo nombre y el mismo tamano.
Write-Host "Verificando..."
& $adb -d shell "cd /sdcard && find . -type f -not -path './.SeedVaultAndroidBackup*' -not -path './Android/data/*' -not -path './Android/obb/*' -exec stat -c '%s|%n' {} + > /data/local/tmp/lista.txt"
& $adb -d pull /data/local/tmp/lista.txt "$dest\lista-movil.txt" | Out-Null
& $adb -d shell rm /data/local/tmp/lista.txt
$phone = @{}
Get-Content "$dest\lista-movil.txt" -Encoding utf8 | ForEach-Object {
    $i = $_.IndexOf('|')
    # find imprime './ruta': se quitan los 2 caracteres del prefijo. Normalize() por los acentos.
    if ($i -gt 0) { $phone[$_.Substring($i + 3).Normalize()] = [int64]$_.Substring(0, $i) }
}
$pc = @{}
Get-ChildItem $root -Recurse -File -Force | ForEach-Object {
    $pc[$_.FullName.Substring($root.Length + 1).Replace('\', '/').Normalize()] = $_
}
$bad = @($phone.Keys | Where-Object { -not $pc.ContainsKey($_) -or $pc[$_].Length -ne $phone[$_] })

# 4. Manifiesto SHA-256, para poder comprobar mas adelante que la copia no se ha corrompido.
$m = @($pc.Values | ForEach-Object {
        [pscustomobject]@{
            path   = 'sdcard/' + $_.FullName.Substring($root.Length + 1).Replace('\', '/')
            bytes  = $_.Length
            sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        }
    })
ConvertTo-Json -InputObject $m -Depth 3 | Set-Content "$dest\manifest-sha256.json" -Encoding utf8

# 5. SMS, llamadas y contactos en texto. Es un archivo de consulta: la restauracion real la hace Seedvault.
foreach ($q in @(
        @('sms', 'content://sms', '_id:thread_id:address:date:date_sent:type:read:status:body'),
        @('llamadas', 'content://call_log/calls', '_id:number:date:duration:type:name:new'),
        @('contactos', 'content://com.android.contacts/raw_contacts', '_id:account_type:account_name:display_name:deleted')
    )) {
    Start-Process -FilePath $adb -ArgumentList @('-d', 'exec-out', 'content', 'query', '--uri', $q[1], '--projection', $q[2]) `
        -RedirectStandardOutput "$dest\extras\$($q[0]).txt" -RedirectStandardError "$dest\extras\$($q[0]).err" -NoNewWindow -Wait
}

# 6. Seedvault: vive DENTRO del movil, el formateo lo borra. Hay que sacarlo.
$svBad = 0
if ($IncluirSeedvault) {
    Write-Host "  .SeedVaultAndroidBackup"
    (& $adb -d pull -a /sdcard/.SeedVaultAndroidBackup "$dest\" 2>&1) | Select-Object -Last 3 | Add-Content $log
    $svPhone = [int64]"$(& $adb -d shell "find /sdcard/.SeedVaultAndroidBackup -type f -exec stat -c '%s' {} + | awk '{s+=`$1} END {print s}'")".Trim()
    $svPc = (Get-ChildItem "$dest\.SeedVaultAndroidBackup" -Recurse -File -Force | Measure-Object Length -Sum).Sum
    if ($svPhone -ne $svPc) { $svBad = 1 }
}

$res = [pscustomobject]@{
    fecha               = (Get-Date).ToString('o')
    archivosEnElMovil   = $phone.Count
    archivosEnElPC      = $pc.Count
    noCoinciden         = $bad.Count
    GiB                 = [math]::Round((($pc.Values | Measure-Object Length -Sum).Sum / 1GB), 2)
    seedvaultCopiado    = [bool]$IncluirSeedvault
    seedvaultNoCoincide = $svBad
}
$res | ConvertTo-Json | Set-Content "$dest\resultado-copia.json" -Encoding utf8
$res | Format-List

if ($bad.Count -gt 0 -or $svBad) {
    $bad | Select-Object -First 30
    throw "COPIA INCOMPLETA en $dest. NO FORMATEES el movil."
}
Set-Content (Join-Path $Destino 'ULTIMA-COPIA.txt') $dest -Encoding utf8
Write-Host "`nCOPIA OK Y VERIFICADA: $dest" -ForegroundColor Green
Write-Host "Recuerda: repite esta copia JUSTO ANTES de formatear, y luego no toques el movil."
