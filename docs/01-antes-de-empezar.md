# 1. Antes de empezar

## Comprueba que es tu móvil

El nombre en clave del Lenovo Z6 Pro es **`zippo`**. Todos los archivos que instales deben llevarlo en el
nombre. Para confirmarlo, con el móvil conectado y la depuración USB activada:

```bash
adb shell getprop ro.product.device
```

Debe responder `zippo`. Si responde otra cosa, **nada de este repositorio sirve para tu móvil**.

El script `comprobar-dispositivo.ps1` hace esta y otras comprobaciones de una vez, sin cambiar nada.

## Qué necesitas

- Un PC con Windows (los scripts son de PowerShell; en Linux o macOS la guía vale igual, los comandos `adb`
  son los mismos).
- Un cable USB **de datos** que funcione. Un cable de solo carga da fallos raros e intermitentes.
- `adb` y `fastboot` (las *platform-tools* de Google). `descargar-oficial.ps1` las baja si no las tienes:
  <https://developer.android.com/studio/releases/platform-tools>
- Espacio libre en el PC: cuenta unos **25 GB** para la copia de un móvil de 128 GB bastante lleno.

## Activar la depuración USB

En el móvil: **Ajustes → Información del teléfono → pulsa 7 veces en "Número de compilación"**. Aparece
"Opciones de desarrollador" en Ajustes → Sistema. Dentro, activa **Depuración USB**. Al conectar el cable el
móvil pregunta si autorizas al PC: acepta.

Si los 7 toques no hacen nada, estás en la pantalla equivocada: tiene que ser sobre "Número de compilación",
no sobre "Versión de Android".

## El bootloader

Para instalar otro sistema hace falta el bootloader **desbloqueado**. Dos formas de saberlo:

- **La pantalla de arranque lo dice.** Si al encender aparece un aviso tipo *"The boot loader is unlocked"*,
  ya lo está.
- **Preguntándoselo**, con el móvil en modo fastboot (`adb reboot bootloader`):

```bash
fastboot getvar unlocked
```

Debe responder `unlocked: yes`.

> **Cuidado con las propiedades del sistema.** En algunas ROMs personalizadas, `ro.boot.flash.locked`
> devuelve `1` y `ro.boot.verifiedbootstate` devuelve `green` aunque el bootloader esté desbloqueado: lo
> falsean para que las aplicaciones bancarias no se quejen. **No te fíes de esas propiedades**; fíate de la
> pantalla de arranque y de `fastboot getvar unlocked`.

Si **no** está desbloqueado, tendrás que desbloquearlo primero, y eso ya borra el teléfono. El método del
Z6 Pro pasaba por una web de Lenovo que hoy no funciona; busca el estado actual en el foro de tu
dispositivo. Esta guía da por hecho que ya lo tienes desbloqueado.

## Windows no ve el móvil en modo fastboot

Esto pasa casi siempre, y despista mucho: `adb devices` funciona perfectamente, pero al reiniciar en
fastboot, `fastboot devices` no devuelve nada y en el Administrador de dispositivos aparece un "Android"
con un triángulo amarillo.

**Causa:** Windows no tiene controlador para el móvil en ese modo. El dispositivo en fastboot se identifica
como `USB\VID_18D1&PID_D00D`, y el controlador oficial de Google no lista ese identificador, así que Windows
no lo asocia solo.

**Solución:** `scripts\driver-fastboot-windows.ps1`, **como administrador**. Descarga el controlador USB
oficial de Google, lo registra y lo asigna a mano al dispositivo. Después, `fastboot devices` ya responde.

Hazlo **antes** de empezar la instalación, no en medio.

## Entrar en cada modo

| Modo | Cómo |
|---|---|
| Fastboot (bootloader) | `adb reboot bootloader`, o apagado + Volumen abajo + Encendido |
| Recovery | `adb reboot recovery`, o desde fastboot elegir *Recovery* con los botones de volumen y confirmar con Encendido |

> En este móvil, **`fastboot reboot recovery` no entra en recovery**. Después de instalar el recovery, usa
> los botones de volumen para elegir *Recovery* en la pantalla del bootloader, o `adb reboot recovery` desde
> Android.

## Qué versión instalar

LineageOS publica compilaciones **nightly** (una por semana aproximadamente) en
<https://download.lineageos.org/devices/zippo/builds>. No hay versiones "estables" aparte: las nightly son
lo normal y funcionan.

La rama **24.0** es Android 17. La **23.2** es Android 16, por si prefieres algo más rodado.

Las Google Apps tienen que ser de **la misma versión de Android que la ROM**: para LineageOS 24, MindTheGapps
**17.0.0 arm64**. Mezclar versiones provoca cierres constantes.

Siguiente: [2. Copia de seguridad](02-copia-de-seguridad.md)
