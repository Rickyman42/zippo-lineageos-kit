# Hace que Windows vea el Lenovo Z6 Pro en modo FASTBOOT.
#
# El problema: en fastboot el movil se identifica como USB\VID_18D1&PID_D00D, y el INF del controlador
# oficial de Google no lista ese identificador. Windows no lo asigna solo y 'fastboot devices' sale vacio.
# La solucion: registrar el controlador de Google y asignarle a mano el modelo "Android Bootloader
# Interface", que es lo que hace el Administrador de dispositivos con "Usar disco" -> "Elegir modelo".
#
# REQUIERE EJECUTARSE COMO ADMINISTRADOR, con el movil YA en fastboot (adb reboot bootloader).
# Uso:  powershell -ExecutionPolicy Bypass -File driver-fastboot-windows.ps1

$ErrorActionPreference = 'Stop'
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Ejecuta este script como administrador (clic derecho en PowerShell -> Ejecutar como administrador).'
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'
$base = Join-Path (Split-Path $PSScriptRoot -Parent) 'descargas\google-usb-driver'
$inf = Join-Path $base 'usb_driver\android_winusb.inf'

# 1. Controlador USB oficial de Google (firmado por Google; Windows lo acepta sin desactivar nada).
if (-not (Test-Path $inf)) {
    New-Item -ItemType Directory -Force $base | Out-Null
    $zip = Join-Path $base 'usb_driver-windows.zip'
    Write-Host 'Bajando el controlador USB de Google...'
    Invoke-WebRequest 'https://dl.google.com/android/repository/usb_driver_r13-windows.zip' -OutFile $zip -UseBasicParsing
    Write-Host ('  SHA-256: ' + (Get-FileHash $zip -Algorithm SHA256).Hash.ToLowerInvariant())
    Write-Host '  (la version r13 que usamos daba 360b01d3dfb6c41621a3a64ae570dfac2c9a40cca1b5a1f136ae90d02f5e9e0b;'
    Write-Host '   si Google publica otra version, el hash cambiara y eso es normal)'
    Expand-Archive $zip -DestinationPath $base -Force
}
if (-not (Test-Path $inf)) { throw "No encuentro el INF del controlador en $inf" }

# 2. Registrarlo en el almacen de controladores de Windows.
pnputil /add-driver $inf | Write-Host

# 3. Asignarlo a mano al dispositivo en fastboot.
Add-Type -TypeDefinition @'
using System; using System.Runtime.InteropServices;
public static class DrvForce {
  [StructLayout(LayoutKind.Sequential)] public struct DEVINFO { public uint cbSize; public Guid ClassGuid; public uint DevInst; public IntPtr Reserved; }
  [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)] public struct INSTPARAMS { public uint cbSize; public uint Flags; public uint FlagsEx; public IntPtr hwndParent; public IntPtr MsgHandler; public IntPtr MsgCtx; public IntPtr FileQueue; public UIntPtr ClassReserved; public uint Reserved; [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)] public string DriverPath; }
  [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)] public struct DRVINFO { public uint cbSize; public uint DriverType; public UIntPtr Reserved; [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)] public string Description; [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)] public string MfgName; [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)] public string ProviderName; public long DriverDate; public ulong DriverVersion; }
  [DllImport("setupapi.dll", CharSet = CharSet.Unicode, SetLastError = true)] static extern IntPtr SetupDiGetClassDevsW(IntPtr cls, string enumr, IntPtr hwnd, uint flags);
  [DllImport("setupapi.dll", SetLastError = true)] static extern bool SetupDiEnumDeviceInfo(IntPtr set, uint i, ref DEVINFO d);
  [DllImport("setupapi.dll", CharSet = CharSet.Unicode, SetLastError = true)] static extern bool SetupDiGetDeviceInstanceIdW(IntPtr set, ref DEVINFO d, System.Text.StringBuilder id, int size, out int req);
  [DllImport("setupapi.dll", CharSet = CharSet.Unicode, SetLastError = true)] static extern bool SetupDiGetDeviceInstallParamsW(IntPtr set, ref DEVINFO d, ref INSTPARAMS p);
  [DllImport("setupapi.dll", CharSet = CharSet.Unicode, SetLastError = true)] static extern bool SetupDiSetDeviceInstallParamsW(IntPtr set, ref DEVINFO d, ref INSTPARAMS p);
  [DllImport("setupapi.dll", SetLastError = true)] static extern bool SetupDiBuildDriverInfoList(IntPtr set, ref DEVINFO d, uint type);
  [DllImport("setupapi.dll", CharSet = CharSet.Unicode, SetLastError = true)] static extern bool SetupDiEnumDriverInfoW(IntPtr set, ref DEVINFO d, uint type, uint i, ref DRVINFO di);
  [DllImport("setupapi.dll", CharSet = CharSet.Unicode, SetLastError = true)] static extern bool SetupDiSetSelectedDriverW(IntPtr set, ref DEVINFO d, ref DRVINFO di);
  [DllImport("setupapi.dll", SetLastError = true)] static extern bool SetupDiDestroyDeviceInfoList(IntPtr set);
  [DllImport("newdev.dll", SetLastError = true)] static extern bool DiInstallDevice(IntPtr hwnd, IntPtr set, ref DEVINFO d, ref DRVINFO di, uint flags, out bool reboot);
  public static string Run(string inf, string idPart, string model) {
    IntPtr set = SetupDiGetClassDevsW(IntPtr.Zero, "USB", IntPtr.Zero, 0x2 | 0x4);
    try {
      for (uint i = 0; ; i++) {
        var d = new DEVINFO(); d.cbSize = (uint)Marshal.SizeOf(typeof(DEVINFO));
        if (!SetupDiEnumDeviceInfo(set, i, ref d)) return "No se encontro el dispositivo " + idPart + ". ¿Esta el movil en fastboot y conectado?";
        var sb = new System.Text.StringBuilder(512); int req;
        SetupDiGetDeviceInstanceIdW(set, ref d, sb, sb.Capacity, out req);
        if (sb.ToString().IndexOf(idPart, StringComparison.OrdinalIgnoreCase) < 0) continue;
        var p = new INSTPARAMS(); p.cbSize = (uint)Marshal.SizeOf(typeof(INSTPARAMS));
        if (!SetupDiGetDeviceInstallParamsW(set, ref d, ref p)) return "GetInstallParams error " + Marshal.GetLastWin32Error();
        p.DriverPath = inf; p.Flags |= 0x00010000; p.FlagsEx |= 0x00000800;
        if (!SetupDiSetDeviceInstallParamsW(set, ref d, ref p)) return "SetInstallParams error " + Marshal.GetLastWin32Error();
        if (!SetupDiBuildDriverInfoList(set, ref d, 1)) return "BuildDriverInfoList error " + Marshal.GetLastWin32Error();
        string seen = "";
        for (uint j = 0; ; j++) {
          var di = new DRVINFO(); di.cbSize = (uint)Marshal.SizeOf(typeof(DRVINFO));
          if (!SetupDiEnumDriverInfoW(set, ref d, 1, j, ref di)) return "Modelo no encontrado en el INF. Vistos: " + seen;
          seen += di.Description + "; ";
          if (di.Description != model) continue;
          if (!SetupDiSetSelectedDriverW(set, ref d, ref di)) return "SetSelectedDriver error " + Marshal.GetLastWin32Error();
          bool reboot;
          if (!DiInstallDevice(IntPtr.Zero, set, ref d, ref di, 0, out reboot)) return "DiInstallDevice error " + Marshal.GetLastWin32Error();
          return "OK: instalado '" + model + "' en " + sb + (reboot ? " (pide reiniciar el PC)" : "");
        }
      }
    } finally { SetupDiDestroyDeviceInfoList(set); }
  }
}
'@
[DrvForce]::Run($inf, 'VID_18D1&PID_D00D', 'Android Bootloader Interface') | Write-Host

Write-Host "`nComprueba ahora:  fastboot devices   (debe aparecer un dispositivo)"
