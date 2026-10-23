# 2. Copia de seguridad

Esta es la parte importante. La instalación se puede repetir; una copia incompleta, no.

## Qué se puede copiar y qué no

| Qué | Cómo se salva | Vuelve solo |
|---|---|---|
| Fotos, vídeos, documentos, descargas | `copiar-y-verificar.ps1` (al PC) | Sí, devolviendo los archivos |
| Contactos, calendario, correo | Ya están en tu cuenta de Google | Sí, al iniciar sesión |
| Contraseñas guardadas | Gestor de contraseñas de Google | Sí, al iniciar sesión |
| Verificación en dos pasos | Copia en la nube del Authenticator | Solo si la activaste **antes** |
| SMS, registro de llamadas, ajustes, datos de apps | Seedvault | Sí, en parte (ver abajo) |
| Aplicaciones instaladas | Seedvault las reinstala | Sí |
| Chats de WhatsApp | Copia de WhatsApp en Google Drive | Sí, desde la propia app |
| Multimedia de WhatsApp/Telegram | `copiar-y-verificar.ps1` | Sí, pero con cuidado (ver trampas) |
| **Sesiones abiertas de aplicaciones** | **No se puede** | **No. Todas piden volver a entrar** |
| **Frases de recuperación de criptomonedas** | **No se puede** | **No. Apúntalas en papel** |

**Lo que nadie espera:** después de formatear, aplicaciones como Telegram, Instagram, Facebook, el banco o
el correo corporativo piden iniciar sesión de cero, con contraseña y a veces con SMS. Seedvault reinstala la
aplicación, pero no te deja dentro. Prepara esa lista antes.

## Seedvault: la copia de las aplicaciones

Seedvault es la copia de seguridad que trae LineageOS (y muchas ROMs derivadas). Guarda datos de
aplicaciones, SMS, registro de llamadas y ajustes del sistema.

**Ajustes → Sistema → Copia de seguridad** (o `adb shell am start -a com.android.settings.BACKUP_SETTINGS`)
→ elegir Seedvault → **Copia de seguridad ahora**.

Tres cosas que hay que saber:

1. **Te da un código de 12 palabras. Apúntalo en papel.** Sin él, la copia no se puede restaurar. No lo
   guardes solo en el móvil que vas a borrar.
2. **Tarda mucho**: va aplicación por aplicación y puede pasar de una hora. Espera a que desaparezca su
   notificación. No lances otras tareas pesadas a la vez.
3. **La copia se guarda DENTRO del móvil** (en `/sdcard/.SeedVaultAndroidBackup` si eliges el almacenamiento
   interno). **El formateo la borra.** Hay que sacarla al PC: es lo que hace
   `copiar-y-verificar.ps1 -IncluirSeedvault`.

No todas las aplicaciones permiten que se copien sus datos: las que lo prohíben (bancos, carteras, muchas
mensajerías) vuelven vacías aunque Seedvault las reinstale. Eso no es un fallo de Seedvault.

## WhatsApp

**Ajustes → Chats → Copia de seguridad → GUARDAR**, y esperar hasta que diga "Última copia" con la hora
de hoy.

- La copia va a **Google Drive**, no al PC, y es la única forma de recuperar los chats. No se puede restaurar
  desde el PC.
- Comprueba que te queda **espacio en Drive**. Si está lleno, la copia falla y a veces no lo dice claro.
- Si tienes el cifrado de extremo a extremo activado para la copia, necesitarás su contraseña o su clave de
  64 dígitos al restaurar. Tenla a mano.
- El **multimedia** (fotos, vídeos, notas de voz) vive en `Android/media/com.whatsapp` dentro del móvil. Eso
  sí se copia al PC y hay que devolverlo a mano. Ver [trampas](05-trampas.md).

Si usas **WhatsApp Business**, repite todo el proceso: es una aplicación distinta con su propia copia.

## La copia de los archivos al PC

```bash
powershell -ExecutionPolicy Bypass -File scripts\copiar-y-verificar.ps1 -IncluirSeedvault
```

Qué hace, y por qué así:

- Copia carpeta por carpeta con `adb pull`. Tarda entre 20 y 40 minutos, a unos 20-28 MB/s.
- **Verifica**: pide al móvil la lista de todos sus archivos con su tamaño y comprueba que cada uno llegó al
  PC con el mismo nombre y el mismo tamaño. Si falta uno, **falla y lo dice**. No se fía del "éxito" de la
  copia.
- Calcula un SHA-256 de cada archivo y lo guarda en `manifest-sha256.json`, para poder comprobar más
  adelante que nada se corrompió.
- Exporta SMS, llamadas y contactos a archivos de texto, como consulta por si Seedvault falla.
- Excluye `Android/data` (es caché de aplicaciones, Android no deja leer casi nada de ahí, y tiene nombres de
  archivo con caracteres que Windows no admite: eso rompió una copia).
- Solo escribe el puntero a "última copia buena" si **todo** cuadró.

> **No uses métodos que empaqueten todo en un `tar` por el cable.** Probado: se cortó dos veces a mitad de
> un vídeo **devolviendo éxito** (código de salida 0). Una copia que miente es peor que no tener copia.
> `adb pull` carpeta a carpeta, y verificar después.

## Cuándo puedes formatear

Solo cuando **todo** esto sea cierto:

- [ ] WhatsApp (y Business) con copia en Drive **de hoy**, vista en pantalla.
- [ ] Authenticator: dice que los códigos están guardados en tu cuenta de Google.
- [ ] Seedvault: terminó (sin notificación) y "Última copia" no dice "Nunca".
- [ ] `copiar-y-verificar.ps1` terminó con **"COPIA OK Y VERIFICADA"**.
- [ ] Frases de criptomonedas y códigos de respaldo de Google, en papel.
- [ ] Sabes cómo volver a entrar en tu cuenta de Google **sin este móvil**.

## La regla de oro

**Haz una copia final inmediatamente antes de formatear, y luego no toques el móvil.**

Todo lo que ocurra entre tu última copia y el formateo se pierde para siempre: los mensajes de esa tarde,
las fotos que hiciste, los SMS que llegaron. Es el error que más datos cuesta y el más fácil de cometer,
porque la copia "ya estaba hecha".

El orden correcto:

1. WhatsApp (y Business) → GUARDAR otra vez → ver la hora de hoy.
2. `copiar-y-verificar.ps1` otra vez (es rápido: solo cambia lo nuevo).
3. Exportar de nuevo SMS y llamadas.
4. **Dejar el móvil quieto** hasta formatear. Sin contestar mensajes, sin hacer fotos.

Siguiente: [3. Instalar](03-instalar.md)
