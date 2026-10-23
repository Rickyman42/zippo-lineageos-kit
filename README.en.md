# Lenovo Z6 Pro (zippo) → LineageOS 24 / Android 17, without losing data

Guide and helper scripts to take a **Lenovo Z6 Pro (L78051, codename `zippo`)** from stock ZUI
(Android 10/11) to **LineageOS 24 (Android 17)** with Google Apps, **keeping** photos, messages, WhatsApp
and apps.

Written after actually doing it, with the phone on the desk, in October 2026. It includes **the mistakes we
made and how to avoid them**, which is the part nobody documents.

> **Not official LineageOS or Lenovo software, and unsupported.** It is the diary of a process that worked
> on one specific device. Read [AVISO.md](AVISO.md) (risk warning, Spanish) first.

**The full guide is in Spanish**, in [`docs/`](docs/). This page is the summary in English.

## What this repo does not contain

**No ROM, no recovery, no Google Apps, no Lenovo firmware.** They are not ours to redistribute, and
downloading system images from a random third party is exactly how a tampered system ends up on your phone.

Instead, `scripts\descargar-oficial.ps1` fetches them from their official sources and **verifies the
SHA-256 that LineageOS publishes** for every file:

- ROM and recovery: <https://download.lineageos.org/devices/zippo/builds>
- Google Apps: <https://wiki.lineageos.org/gapps/> → MindTheGapps 17.0.0 arm64
- Official device guide: <https://wiki.lineageos.org/devices/zippo/install>

## The process

```
1. Verified backup  ──►  2. FINAL backup right before wiping
3. fastboot flash recovery  ──►  4. Format data  ──►  5. sideload ROM
6. sideload Google Apps (without booting first)  ──►  7. First boot
8. Push files back  ──►  9. Restore apps (Seedvault)  ──►  10. WhatsApp
```

## Scripts (Windows PowerShell)

```bash
powershell -ExecutionPolicy Bypass -File scripts\descargar-oficial.ps1
```

| Script | What it does |
|---|---|
| `descargar-oficial.ps1` | Downloads the latest LineageOS build, recovery and MindTheGapps from official sources; verifies SHA-256 |
| `comprobar-dispositivo.ps1` | Read-only: ROM, bootloader state, battery, free space, what would be backed up |
| `copiar-y-verificar.ps1` | Pulls shared storage to the PC **and checks every file by name and size** |
| `restaurar-archivos.ps1` | Pushes those files back; `-Verificar` re-checks afterwards |
| `driver-fastboot-windows.ps1` | Fixes Windows not seeing the phone in fastboot mode |

## The traps that cost data (full list in `docs/05-trampas.md`)

1. **No final backup right before wiping.** Everything created between your last backup and the wipe is
   gone for good. The most expensive mistake, and the easiest to make.
2. **Pushing WhatsApp media back before the apps are installed.** Android deletes
   `Android/media/<package>` when that app is installed, silently. Push media *after* Seedvault installs the
   apps and *before* opening them. Never `pm clear com.whatsapp` — it wipes the local chat backups too.
3. **Interrupting WhatsApp's restore.** Lose network mid-restore and the app *skips* the restore and opens
   an empty account. It will not offer it again for that session.
4. **Streaming the backup through `tar` over adb.** It truncated mid-video **and exited 0**, twice. Use
   `adb pull` per folder, then verify.
5. **Windows can't see the phone in fastboot.** In fastboot it enumerates as `USB\VID_18D1&PID_D00D`, which
   Google's INF does not list, so Windows never binds a driver. Run `driver-fastboot-windows.ps1` as admin.
6. **`fastboot reboot recovery` does nothing here.** Use the volume keys in the bootloader menu, or
   `adb reboot recovery` from Android.
7. **Bootloader properties lie on custom ROMs.** `ro.boot.flash.locked=1` and `verifiedbootstate=green` are
   spoofed. Trust the boot screen and `fastboot getvar unlocked`.
8. **Camera crashes after a Seedvault restore.** Restored settings crash Qualcomm's camera HAL. Fix:
   `pm clear org.lineageos.aperture` plus re-granting CAMERA and RECORD_AUDIO. No photos are lost.
9. **Storage unreadable after every reboot** until you unlock the phone with the PIN.
10. **Google Apps must be sideloaded before the first boot**, in the same recovery session as the ROM, or
    you have to factory reset and start over. This is official LineageOS guidance.

## License

[MIT](LICENSE). No warranty. Reports of what happened on your own Z6 Pro are welcome; there is no support.
