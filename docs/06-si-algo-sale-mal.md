# 6. Si algo sale mal

## El móvil no arranca después de instalar

El bootloader está desbloqueado, así que **siempre puedes volver a entrar en fastboot**: apagado (mantén
Encendido 15 segundos) + Volumen abajo + Encendido. Desde ahí se puede reinstalar.

Orden de cosas a probar, de menos a más agresiva:

1. **Esperar.** El primer arranque puede llevar 15 minutos. No lo interrumpas.
2. **Formatear y reinstalar.** `Format data` en el recovery y repetir ROM + Google Apps en el mismo paso,
   sin reiniciar entre medias. La causa más común de arranques fallidos es haber arrancado antes de instalar
   las Google Apps, o haber mezclado versiones (Google Apps de Android 16 con ROM de Android 17).
3. **Instalar una compilación anterior.** En <https://download.lineageos.org/devices/zippo/builds> hay varias
   fechas. Si la última falla, prueba la anterior, o la rama 23.2 (Android 16).
4. **Volver al sistema de fábrica.** Lenovo distribuía el firmware oficial (ZUI) y la herramienta
   *Lenovo Software Fix* para restaurarlo. Hoy las descargas oficiales son difíciles de encontrar; si lo
   necesitas, pregunta en el foro del dispositivo. Ten en cuenta que **ese firmware es de 2021, sin parches
   de seguridad desde entonces**.

## Me quedé sin el código de 12 palabras de Seedvault

La copia no se puede descifrar. No hay forma de recuperarla. Las aplicaciones habrá que reinstalarlas desde
Play Store y sus datos se han perdido; los archivos del PC siguen estando bien.

## WhatsApp abrió vacío

Si la restauración se interrumpió, WhatsApp no la vuelve a ofrecer para esa sesión. Opciones:

- Cerrar sesión y volver a registrar el número: cuando detecta una copia en Drive más reciente que lo que hay
  en el móvil, vuelve a ofrecer restaurarla. Funciona, pero cada reintento gasta códigos de verificación y
  WhatsApp los limita.
- Los chats que ya no estén en ninguna copia **no vuelven**. Lo único que queda es pedir a la otra persona
  que reenvíe lo importante; su copia de la conversación sigue en su móvil.

## Faltan fotos o vídeos después de restaurar

Compara otra vez con la copia del PC y vuelve a enviar lo que falte:

```bash
adb push "<copia>\almacenamiento-compartido\sdcard\DCIM" /sdcard/
```

Si la galería no los ve, avisa al sistema:

```bash
adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/DCIM
```

## El PC no ve el móvil

| Síntoma | Causa habitual |
|---|---|
| `adb devices` vacío | Depuración USB desactivada, o no has aceptado el aviso en el móvil |
| `adb devices` dice `unauthorized` | Falta aceptar el aviso; prueba **Revocar autorizaciones** en Opciones de desarrollador y vuelve a conectar |
| `fastboot devices` vacío | Falta el controlador: `scripts\driver-fastboot-windows.ps1` como administrador |
| Se desconecta a mitad de la copia | Cable de solo carga, o concentrador USB. Cable directo al PC |
| `/sdcard` vacío | El móvil está sin desbloquear después de un reinicio |

## Un comando que no sabes qué hace

No lo ejecutes. En particular, desconfía de cualquier guía que te pida bloquear el bootloader
(`fastboot flashing lock`) con un sistema no oficial instalado: puede dejar el móvil sin arrancar.

## Dónde preguntar

- Foro del dispositivo (busca "zippo" + "LineageOS" en XDA)
- Wiki oficial de LineageOS: <https://wiki.lineageos.org/devices/zippo/>

Este repositorio no da soporte. Si abres una incidencia, cuenta **qué versión instalaste, qué comando
ejecutaste y qué dijo exactamente**: sin eso no se puede ayudar.
