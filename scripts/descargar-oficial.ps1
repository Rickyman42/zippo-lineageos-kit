# Descarga, desde las fuentes OFICIALES, todo lo necesario para instalar LineageOS en el Lenovo Z6 Pro
# (zippo), y verifica el SHA-256 de cada archivo contra el que publica LineageOS.
#
# Este repositorio no redistribuye la ROM ni las Google Apps: las baja de sus autores.
#
# Uso:  powershell -ExecutionPolicy Bypass -File descargar-oficial.ps1 [-Destino .\descargas] [-Rama 24.0]
param(
    [string]$Destino = (Join-Path (Split-Path $PSScriptRoot -Parent) 'descargas'),
    [string]$Rama = '24.0',
    [switch]$SinGapps,
    [switch]$SinPlatformTools
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'   # Invoke-WebRequest es muchisimo mas rapido sin la barra
New-Item -ItemType Directory -Force $Destino | Out-Null
$ua = @{ 'User-Agent' = 'zippo-lineageos-kit' }

function Bajar($url, $ruta, $shaEsperado) {
    $nombre = Split-Path $ruta -Leaf
    if (Test-Path $ruta) {
        Write-Host "  ya estaba: $nombre"
    } else {
        Write-Host "  bajando  : $nombre"
        Invoke-WebRequest -Uri $url -OutFile "$ruta.parcial" -Headers $ua -UseBasicParsing
        Move-Item "$ruta.parcial" $ruta -Force
    }
    $sha = (Get-FileHash $ruta -Algorithm SHA256).Hash.ToLowerInvariant()
    $mb = [math]::Round((Get-Item $ruta).Length / 1MB, 1)
    if ($shaEsperado) {
        if ($sha -ne $shaEsperado.ToLowerInvariant()) {
            throw "SHA-256 NO COINCIDE en $nombre.`n  esperado: $shaEsperado`n  obtenido: $sha`nNO INSTALES este archivo. Borralo y vuelve a bajarlo."
        }
        Write-Host "  SHA-256 OK ($mb MB)" -ForegroundColor Green
    } else {
        Write-Host "  SHA-256 (sin referencia oficial publicada): $sha  ($mb MB)" -ForegroundColor Yellow
    }
}

# ---------------------------------------------------------------- 1. ROM y recovery de LineageOS
# La API v2 de LineageOS da, por cada compilacion, el tamano y el SHA-256 de cada archivo.
Write-Host "`n== LineageOS para zippo (rama $Rama)"
$builds = Invoke-RestMethod 'https://download.lineageos.org/api/v2/devices/zippo/builds' -Headers $ua
$build = $builds | Where-Object { $_.version -eq $Rama } | Sort-Object date | Select-Object -Last 1
if (-not $build) {
    $hay = ($builds | Select-Object -ExpandProperty version -Unique) -join ', '
    throw "No hay compilaciones de la rama $Rama. Disponibles ahora mismo: $hay"
}
Write-Host "   compilacion $($build.date)  (LineageOS $($build.version))"

foreach ($f in $build.files) {
    $nombre = Split-Path $f.filepath -Leaf
    if ($nombre -notmatch '^(lineage-.*-zippo-signed\.zip|recovery\.img)$') { continue }
    Bajar "https://mirrorbits.lineageos.org$($f.filepath)" (Join-Path $Destino $nombre) $f.sha256
}

# ---------------------------------------------------------------- 2. MindTheGapps
# Fuente oficial segun el wiki de LineageOS: https://wiki.lineageos.org/gapps/
# Tienen que ser de la MISMA version de Android que la ROM. LineageOS 24 = Android 17 = MindTheGapps 17.0.0.
if (-not $SinGapps) {
    $androidPorRama = @{ '24.0' = '17.0.0'; '23.2' = '16.0.0'; '23.1' = '16.0.0'; '23.0' = '16.0.0'; '22.2' = '15.0.0'; '22.1' = '15.0.0'; '21.0' = '14.0.0' }
    $verGapps = $androidPorRama[$Rama]
    if (-not $verGapps) {
        Write-Host "`n== MindTheGapps: no se que version de Android es LineageOS $Rama. Bajalas a mano desde https://wiki.lineageos.org/gapps/" -ForegroundColor Yellow
    } else {
        Write-Host "`n== MindTheGapps $verGapps arm64"
        $rel = Invoke-RestMethod "https://api.github.com/repos/MindTheGapps/$verGapps-arm64/releases/latest" -Headers $ua
        $zip = $rel.assets | Where-Object { $_.name -like '*.zip' } | Select-Object -First 1
        if (-not $zip) { throw "La release $($rel.tag_name) de MindTheGapps no publica ningun .zip" }
        # Si publican un fichero de hash junto al zip, lo usamos; si no, solo mostramos el calculado.
        $shaAsset = $rel.assets | Where-Object { $_.name -like "$($zip.name)*sha256*" -or $_.name -eq "$($zip.name).sha256" } | Select-Object -First 1
        $shaRef = $null
        if ($shaAsset) {
            # Ojo: con -UseBasicParsing, .Content puede venir como array de bytes y no como texto.
            $crudo = (Invoke-WebRequest $shaAsset.browser_download_url -Headers $ua -UseBasicParsing).Content
            if ($crudo -is [byte[]]) { $crudo = [Text.Encoding]::ASCII.GetString($crudo) }
            $shaRef = ("$crudo".Trim() -split '\s+')[0]
        }
        Bajar $zip.browser_download_url (Join-Path $Destino $zip.name) $shaRef
        if (-not $shaRef) {
            Write-Host "   MindTheGapps no publica un hash de referencia. Compara el valor de arriba con el que" -ForegroundColor Yellow
            Write-Host "   indiquen en su pagina de releases antes de instalarlo." -ForegroundColor Yellow
        }
    }
}

# ---------------------------------------------------------------- 3. adb y fastboot (Google)
if (-not $SinPlatformTools) {
    $pt = Join-Path $Destino 'platform-tools'
    if (Test-Path (Join-Path $pt 'adb.exe')) {
        Write-Host "`n== platform-tools: ya estaban en $pt"
    } else {
        Write-Host "`n== platform-tools (adb y fastboot, de Google)"
        $z = Join-Path $Destino 'platform-tools-latest-windows.zip'
        Bajar 'https://dl.google.com/android/repository/platform-tools-latest-windows.zip' $z $null
        Expand-Archive $z -DestinationPath $Destino -Force
        Write-Host "   adb y fastboot en: $pt"
    }
}

# ---------------------------------------------------------------- Resumen
Write-Host "`n== Listo. Archivos en $Destino" -ForegroundColor Green
Get-ChildItem $Destino -File | Select-Object Name, @{n = 'MB'; e = { [math]::Round($_.Length / 1MB, 1) } } | Format-Table -AutoSize
@"
Antes de instalar, comprueba a ojo:
  - el nombre de la ROM lleva 'zippo'
  - la version de MindTheGapps corresponde a la rama de LineageOS que vas a instalar
  - arriba dice 'SHA-256 OK' en la ROM y en el recovery

Siguiente paso: docs\03-instalar.md
"@
