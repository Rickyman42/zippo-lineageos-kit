# Lenovo Z6 Pro (zippo) → LineageOS 24 / Android 17, sin perder datos

> ## ⚠️ ESTO BORRA EL MÓVIL POR COMPLETO Y NO TIENE MARCHA ATRÁS
>
> Si tu copia de seguridad está incompleta, pierdes tus datos para siempre. Nadie te los puede devolver.
> **Lee [AVISO.md](AVISO.md) antes de ejecutar nada.** Sin prisa, con el móvil cargado, y con la copia hecha
> hoy mismo y comprobada.
>
> Esto no es software oficial de LineageOS ni de Lenovo, **no tiene soporte y no tiene garantía**. Es el
> diario de un proceso que funcionó en un dispositivo concreto, publicado por si le sirve a alguien más.

Guía y utilidades para llevar un **Lenovo Z6 Pro (L78051, nombre en clave `zippo`)** desde la ROM de fábrica
(ZUI, Android 10/11) hasta **LineageOS 24 (Android 17)** con Google Apps, **conservando** fotos, mensajes,
WhatsApp y aplicaciones.

Está escrito después de hacerlo de verdad, con el móvil delante, en octubre de 2026. Incluye **los fallos
cometidos y cómo evitarlos**, que es la parte que no suele estar documentada en ningún sitio.

---

## ¿Por qué existe esto?

Este móvil estuvo a punto de acabar en la basura.

Lenovo lo dejó en Android 11 y ahí se quedó. El problema no fue quedarse sin novedades: fue que las
**aplicaciones del banco** empezaron a pedir una versión de Android más nueva para seguir funcionando. Un
teléfono perfectamente bueno, con un Snapdragon 855 que todavía va rápido, convertido en inservible porque
el fabricante decidió dejar de actualizarlo.

Buscando en los foros aparece que **sí se puede**: la comunidad mantiene compilaciones oficiales de
LineageOS para este modelo, con los parches de seguridad al día. Lo que no aparece en ninguna parte es el
camino completo sin perder nada: qué copiar, en qué orden, y dónde están las trampas que te borran las fotos
sin avisar.

Eso es lo que hay aquí, gratis y para cualquiera. Si a alguien le sirve para no tirar un móvil que funciona,
ha valido la pena.

**El problema no es instalar LineageOS. El problema es no perder nada en el camino**, y ahí es donde la
gente se deja los datos.

## Qué hay aquí

| Carpeta | Contenido |
|---|---|
| [`docs/`](docs/) | La guía, paso a paso, en el orden que funciona |
| [`scripts/`](scripts/) | Utilidades para Windows (PowerShell): descargar lo oficial, copiar, verificar y devolver los datos |

### La guía

1. [**Antes de empezar**](docs/01-antes-de-empezar.md) — qué necesitas, bootloader, controlador USB de Windows
2. [**Copia de seguridad**](docs/02-copia-de-seguridad.md) — qué se copia, qué no se puede copiar y cómo verificarlo
3. [**Instalar**](docs/03-instalar.md) — recovery, formateo, ROM y Google Apps
4. [**Recuperar tus datos**](docs/04-recuperar.md) — orden correcto: archivos, aplicaciones, WhatsApp
5. [**Trampas conocidas**](docs/05-trampas.md) — **lee esto aunque no leas el resto**
6. [**Si algo sale mal**](docs/06-si-algo-sale-mal.md) — volver atrás

### Los scripts

Todos son de PowerShell, para Windows, y no requieren instalar nada (salvo lo que ellos mismos descargan
de fuentes oficiales). Se ejecutan así:

```bash
powershell -ExecutionPolicy Bypass -File scripts\descargar-oficial.ps1
```

| Script | Qué hace |
|---|---|
| `descargar-oficial.ps1` | Descarga la última ROM + recovery de LineageOS y MindTheGapps **desde las fuentes oficiales** y comprueba el SHA-256 de cada archivo |
| `comprobar-dispositivo.ps1` | Solo lectura: dice qué ROM tienes, si el bootloader está desbloqueado, batería, espacio libre |
| `copiar-y-verificar.ps1` | Copia el almacenamiento del móvil al PC **y comprueba archivo a archivo** que llegó todo |
| `restaurar-archivos.ps1` | Devuelve esos archivos al móvil después de instalar |
| `driver-fastboot-windows.ps1` | Arregla que Windows no vea el móvil en modo fastboot |

## Lo que este repositorio NO contiene

**Ni la ROM, ni el recovery, ni las Google Apps, ni el firmware de Lenovo.** No son nuestros y no se pueden
redistribuir. Además, bajarlos de un tercero es exactamente como se cuela un sistema manipulado en tu móvil.

En su lugar, `descargar-oficial.ps1` los baja de donde los publican sus autores y **verifica el SHA-256**
que el propio LineageOS firma. Es más seguro y siempre te da la versión actual, no una congelada:

- ROM y recovery: <https://download.lineageos.org/devices/zippo/builds>
- Google Apps: <https://wiki.lineageos.org/gapps/> → MindTheGapps 17.0.0 arm64
- Guía oficial del dispositivo: <https://wiki.lineageos.org/devices/zippo/install>

## Resumen del proceso

```
1. Copia de seguridad verificada  ──►  2. Copia FINAL justo antes de formatear
                                              │
3. fastboot flash recovery  ──►  4. Format data  ──►  5. sideload ROM
                                              │
6. sideload Google Apps (SIN reiniciar antes)  ──►  7. Primer arranque
                                              │
8. Devolver archivos  ──►  9. Restaurar apps  ──►  10. WhatsApp
```

Con todo preparado y sin errores, son **2-3 horas**, de las que la mayor parte es esperar.

## Las tres cosas que más datos cuestan

1. **No hacer una copia final inmediatamente antes de formatear.** Todo lo que pase entre tu última copia y
   el formateo se pierde para siempre. Es el error más caro y el más fácil de cometer.
2. **Devolver el multimedia de WhatsApp antes de instalar las apps.** Android borra `Android/media/<app>`
   cuando la aplicación se instala. Lo borra sin avisar.
3. **Cortar la red mientras WhatsApp restaura.** La aplicación se salta la restauración y te deja la cuenta
   vacía, sin segunda oportunidad desde esa copia.

Los tres están explicados en [docs/05-trampas.md](docs/05-trampas.md).

## Licencia

[MIT](LICENSE) para los scripts y la documentación. Haz lo que quieras con ellos; no hay garantía de nada.

## Soporte: no hay

Hay que decirlo claro, por respeto al que llega:

- **Esto no es un producto y nadie está de guardia.** Se publica por si ayuda. Se mantiene en ratos libres,
  cuando se puede, y puede dejar de mantenerse sin avisar.
- **Nadie va a rescatarte a mitad del proceso.** Si formateas sin copia, los datos no vuelven: ni con este
  repositorio, ni con otro, ni pagando.
- **Lo que decides hacer con tu móvil es tuyo.** Lee el [AVISO](AVISO.md), decide con calma, y si no lo ves
  claro, no lo hagas. No pasa nada por seguir con el Android que tienes.

## Contribuir

Lo que **sí** es útil y se incorpora: lo que te pasó a ti con tu Z6 Pro, contado con detalle. Qué versión
instalaste, qué comando ejecutaste, qué dijo exactamente. Eso mejora la guía para el siguiente.

Lo que no se puede atender: "no me funciona", peticiones de ayuda urgente, o recuperar datos perdidos.
Al abrir una incidencia se te pedirá confirmar que leíste el aviso y que tenías una copia verificada.
