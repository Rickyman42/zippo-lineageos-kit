# 5. Trampas conocidas

Todo lo de aquí pasó de verdad, en octubre de 2026, haciendo este proceso en un Z6 Pro. Si solo vas a leer
una página de este repositorio, lee esta.

---

## 1. Android borra `Android/media/<aplicación>` al instalar esa aplicación

**Qué pasa:** devuelves el multimedia de WhatsApp al móvil, Seedvault instala WhatsApp, y el multimedia
desaparece. Sin avisar, sin error. También lo borra `pm clear`.

**Por qué:** esa carpeta pertenece a la aplicación. Android la considera parte de su instalación y la limpia
cuando la aplicación se instala o se le borran los datos.

**Qué hacer:** devolver el multimedia **después** de que las aplicaciones estén instaladas y **antes** de
abrirlas. Y nunca `adb shell pm clear com.whatsapp`: borra también las copias locales de los chats que
WhatsApp guarda en el móvil.

**Nos pasó dos veces.**

---

## 2. Empaquetar la copia en un `tar` por el cable miente

**Qué pasa:** el comando termina **con éxito** (código 0) y el archivo está cortado a mitad de un vídeo.

**Por qué:** el flujo por `adb exec-out` se puede truncar sin que ninguno de los dos extremos lo note.

**Qué hacer:** `adb pull` carpeta por carpeta, y después **verificar**: pedir al móvil la lista de archivos
con sus tamaños y comprobarlos uno a uno contra el PC. Es lo que hace `copiar-y-verificar.ps1`.

**Nos pasó dos veces, con la misma copia.**

---

## 3. Si cortas la red mientras WhatsApp restaura, pierdes la restauración

**Qué pasa:** WhatsApp estaba restaurando, se queda la red sin conexión o se reinicia el móvil, y la
aplicación **se salta la restauración** y abre la cuenta vacía. No vuelve a ofrecerla.

**Qué hacer:** dejar que termine. Cuesta minutos si la memoria del móvil está libre; si acabas de restaurar
130 aplicaciones, está saturada y va lentísimo. Haz `am kill-all` antes y ten paciencia.

---

## 4. No hacer una copia final justo antes de formatear

**Qué pasa:** todo lo que ocurre entre tu última copia y el formateo no está en ninguna parte. Mensajes de
esa tarde, SMS, fotos. Se pierde para siempre.

**Qué hacer:** repetir la copia de WhatsApp y la de archivos **inmediatamente antes** de formatear, y luego
no tocar el móvil. Ver [la regla de oro](02-copia-de-seguridad.md#la-regla-de-oro).

**Esto nos costó unas cinco horas de mensajes.** Es el fallo más caro de todos y el más fácil de evitar.

---

## 5. Windows no ve el móvil en modo fastboot

**Qué pasa:** `adb devices` funciona, `fastboot devices` no devuelve nada, y en el Administrador de
dispositivos hay un "Android" con triángulo amarillo.

**Por qué:** en fastboot el móvil se identifica como `USB\VID_18D1&PID_D00D`, y el controlador oficial de
Google no lista ese identificador, así que Windows no lo asigna solo.

**Qué hacer:** `scripts\driver-fastboot-windows.ps1` como administrador. Hay que repetirlo en cada PC nuevo.

---

## 6. `fastboot reboot recovery` no entra en recovery

**Qué pasa:** el comando se acepta y el móvil se queda en el bootloader o arranca Android.

**Qué hacer:** elegir *Recovery* con los botones de volumen en la pantalla del bootloader, o
`adb reboot recovery` desde Android.

---

## 7. Las propiedades del bootloader mienten en las ROMs personalizadas

**Qué pasa:** `ro.boot.flash.locked` devuelve `1` y `ro.boot.verifiedbootstate` devuelve `green`, como si el
bootloader estuviese bloqueado, cuando no lo está.

**Por qué:** algunas ROMs lo falsean a propósito para que las aplicaciones bancarias no se bloqueen.

**Qué hacer:** fiarse de la pantalla de arranque y de `fastboot getvar unlocked`, no de las propiedades.

---

## 8. La cámara no abre después de restaurar con Seedvault

**Qué pasa:** la aplicación de cámara (Aperture, la de LineageOS) se cierra al abrirse. Otras aplicaciones
sí pueden hacer fotos, así que **no es el hardware**.

**Por qué:** los ajustes restaurados por Seedvault hacen caer el controlador de cámara de Qualcomm
(`AdvancedCameraUsecase::Initialize`, SIGSEGV en los registros).

**Qué hacer:** borrar sus ajustes y devolverle los permisos. **No pierdes ninguna foto**:

```bash
adb shell pm clear org.lineageos.aperture
adb shell pm grant org.lineageos.aperture android.permission.CAMERA
adb shell pm grant org.lineageos.aperture android.permission.RECORD_AUDIO
```

---

## 9. Después de cada reinicio, el PC no lee el almacenamiento

**Qué pasa:** `adb` conecta, pero `ls /sdcard` sale vacío y los scripts fallan.

**Por qué:** Android cifra el almacenamiento hasta el primer desbloqueo. Hasta que no metas el PIN, no hay
nada que leer.

**Qué hacer:** desbloquear el móvil. Y para que no se apague la pantalla a mitad de una copia larga:

```bash
adb shell svc power stayon usb
```

---

## 10. `Android/data` no se puede copiar, y no hace falta

**Qué pasa:** la copia se detiene con errores de nombre de archivo.

**Por qué:** Android no deja leer casi nada de ahí, y algunas aplicaciones usan nombres con caracteres como
`:` o `|` que Windows no admite.

**Qué hacer:** excluirla. Es caché de aplicaciones; lo que importa está en `Android/media`.

---

## 11. El móvil se apaga solo durante la copia

**Qué pasa:** reinicios repentinos (en los registros, `hard_rst`) mientras se hacen varias cosas pesadas a
la vez.

**Por qué (hipótesis, no confirmado):** batería degradada. Nos pasó dos veces con la batería al 56 % y con
copia + Seedvault + carga a la vez. En un móvil de 2019, la batería suele estar cerca del 50 % de su
capacidad original.

**Qué hacer:** una tarea pesada a la vez, enchufado, y por encima del 80 % de batería antes de instalar.

---

## 12. "76 GB usados" no son 76 GB que copiar

El espacio que marca Ajustes incluye el sistema y los datos internos de las aplicaciones. Lo que de verdad
se copia al PC (almacenamiento compartido + `Android/media` + Seedvault) fue **unos 21 GB** en un móvil que
decía 76 GB usados.

---

## Lo que sigue sin estar claro

Honestidad: estas cosas las vimos pero no tenemos la causa confirmada.

- **Por qué WhatsApp reorganiza su carpeta al restaurar** y deja vídeos y notas de voz fuera de sitio.
- **Por qué la primera pantalla de restauración de WhatsApp anunció 8,6 GB** cuando la copia de Drive era de
  3,3 GB. La hipótesis es que contaba los archivos locales que ya estaban en el móvil.
- **Si el micrófono por Bluetooth en llamada funciona bien.** El sistema lo declara y negocia voz de banda
  ancha, pero medirlo requiere una llamada real.

Siguiente: [6. Si algo sale mal](06-si-algo-sale-mal.md)
