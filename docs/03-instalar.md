# 3. Instalar LineageOS 24 + Google Apps

Guía oficial del dispositivo, por si quieres contrastar:
<https://wiki.lineageos.org/devices/zippo/install>

**Antes:** batería por encima del 80 % y enchufado. El Z6 Pro con la batería gastada se apaga solo si se le
exige mucho, y un apagón a mitad de una instalación es el peor momento posible.

## Paso 0 — Descargar y verificar

```bash
powershell -ExecutionPolicy Bypass -File scripts\descargar-oficial.ps1
```

Baja de las fuentes oficiales la última ROM de `zippo`, su `recovery.img` y MindTheGapps 17.0.0 arm64, y
**comprueba el SHA-256** de la ROM y el recovery contra el que publica LineageOS. Si un archivo no cuadra,
se para: no lo instales.

Comprueba a ojo que los nombres llevan `zippo` y que la versión de MindTheGapps es `17.0.0`.

## Paso 1 — Instalar el recovery de LineageOS

```bash
adb reboot bootloader
fastboot devices
fastboot getvar unlocked
fastboot flash recovery descargas\recovery.img
```

- `fastboot devices` tiene que mostrar **un** dispositivo. Si no muestra nada, te falta el controlador:
  [ver 01-antes-de-empezar](01-antes-de-empezar.md#windows-no-ve-el-móvil-en-modo-fastboot).
- `fastboot getvar unlocked` tiene que decir `yes`.
- Útil para dejar constancia de en qué estado partías: `fastboot getvar all > estado-fastboot.txt`.

Comprueba también la versión del firmware base (bootloader y banda base). El Z6 Pro suele llevar el
firmware de la última ZUI oficial, de 2021 (Android 11). LineageOS 24 funciona sobre él, pero conviene
saberlo: **si tu firmware base es muy distinto del esperado por la compilación, párate** y lee el hilo del
dispositivo antes de seguir.

## Paso 2 — Entrar en el recovery

**No arranques el sistema todavía.** En la pantalla del bootloader, con los botones de **volumen** elige
**Recovery** y confirma con **Encendido**.

> `fastboot reboot recovery` **no funciona** en este móvil: se queda en el bootloader o arranca Android.

## Paso 3 — Formatear

En el recovery de LineageOS: **Factory reset → Format data/factory reset → Format data**.

Esto es el punto sin retorno. Aquí desaparece todo, incluida la copia de Seedvault si no la sacaste al PC.

## Paso 4 — Instalar la ROM

En el recovery: **Apply update → Apply from ADB**. Después, en el PC:

```bash
adb sideload descargas\lineage-24.0-AAAAMMDD-nightly-zippo-signed.zip
```

Tarda unos minutos. Que el porcentaje se quede clavado en 47 % es normal: `adb` deja de informar antes de
que el móvil termine. Espera a que el móvil diga que acabó.

## Paso 5 — Instalar las Google Apps, SIN reiniciar antes

Vuelve a **Apply update → Apply from ADB** y, sin reiniciar el sistema:

```bash
adb sideload descargas\MindTheGapps-17.0.0-arm64-AAAAMMDD.zip
```

El móvil avisa de que la firma no se puede verificar (*"Signature verification failed — Install anyway?"*).
Es normal en los paquetes de Google Apps: confirma **Yes** en la pantalla del móvil.

> **Esto es obligatorio hacerlo ahora.** El wiki de LineageOS lo advierte: si arrancas LineageOS antes de
> instalar las Google Apps, tendrás que formatear otra vez y empezar de nuevo, o la cosa se cierra sin
> parar.

## Paso 6 — Reiniciar

**Reboot system now**. El primer arranque puede llevar hasta 15 minutos: está preparando las aplicaciones.
Si pasa de ahí, mira [si algo sale mal](06-si-algo-sale-mal.md); no vuelvas a instalar cosas al azar.

## Paso 7 — El asistente inicial

- Elige **Configurar sin conexión** o salta la red si el asistente se atasca.
- La pantalla **"Copiar aplicaciones y datos de otro dispositivo"** no avanza si no tienes otro móvil al
  lado: dale a **atrás** y sigue.
- Si el Wi-Fi no conecta, lo más probable es que la contraseña esté mal escrita. Es la causa habitual.
- Inicia sesión en Google cuando te lo pida: así vuelven contactos, calendario y contraseñas.
- Pon el PIN o el patrón. **Hasta que no desbloquees el móvil después de cada reinicio, el PC no puede leer
  su almacenamiento**, así que los scripts fallarán con "no es legible".
- Vuelve a activar la **depuración USB** (7 toques en Número de compilación) y acepta el aviso del PC.

Siguiente: [4. Recuperar tus datos](04-recuperar.md)
