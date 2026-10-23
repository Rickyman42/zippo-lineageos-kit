# 4. Recuperar tus datos

**El orden importa.** Hacerlo en otro orden es lo que borra el multimedia de WhatsApp.

```
1. Seedvault: restaurar las aplicaciones   (las instala, tarda ~1 h)
2. Devolver los archivos del PC            (fotos, documentos, Android/media)
3. Abrir WhatsApp y restaurar              (y solo entonces)
```

El motivo está en [trampas](05-trampas.md): **Android borra `Android/media/<aplicación>` cuando esa
aplicación se instala**. Si devuelves el multimedia antes de que Seedvault instale WhatsApp, Seedvault lo
borra al instalarla.

## Paso 1 — Restaurar las aplicaciones con Seedvault

1. Devuelve la copia de Seedvault al móvil:

   ```bash
   adb push "<carpeta de la copia>\.SeedVaultAndroidBackup" /sdcard/
   ```

2. En el móvil: **Ajustes → Sistema → Copia de seguridad → Cambiar proveedor → Seedvault → Restaurar →
   almacenamiento del teléfono**, y escribe las **12 palabras**.

3. Empieza a reinstalar las aplicaciones de la Z a la A, una cada 20 segundos aproximadamente. Con 130
   aplicaciones son **cerca de una hora**. Después restaura sus datos, unos 15 minutos más.

4. Al final pregunta si quieres "reutilizar la copia" y si quieres "restaurar archivos (beta)": puedes
   omitir las dos. La restauración de archivos de Seedvault no es fiable todavía — en nuestra prueba
   anunció 2,9 GB y bajó 1,7 MB. Los archivos los devuelves tú desde el PC, que sí se verifica.

5. Cuando acabe, la memoria del móvil está al límite y todo va lento. Déjalo respirar:

   ```bash
   adb shell am kill-all
   ```

**No abras WhatsApp todavía.**

## Paso 2 — Devolver los archivos

Con las aplicaciones ya instaladas y **antes de abrir WhatsApp**:

```bash
powershell -ExecutionPolicy Bypass -File scripts\restaurar-archivos.ps1 -BackupPath "<carpeta de la copia>"
```

Devuelve las carpetas del almacenamiento compartido (DCIM, Download, Documents…) y el contenido de
`Android/media` de cada aplicación, y avisa a la galería para que vea las fotos.

Comprueba en el móvil que están tus fotos antes de seguir.

## Paso 3 — WhatsApp

1. Abre WhatsApp y **verifica tu número**.
   - Si el SMS no llega o dice "inténtalo más tarde", usa la opción de **llamada perdida**. Funciona, pero
     hay que **conceder el permiso de teléfono** a WhatsApp para que la detecte.
   - Si has pedido muchos códigos, WhatsApp te hace esperar. No insistas: empeora.
2. Cuando ofrezca **Restaurar** la copia de Google Drive, acéptala. **No crees una copia nueva antes**: la
   sobrescribirías.
3. **No toques nada hasta que termine.** No cortes el Wi-Fi, no reinicies, no cierres la aplicación. Si se
   interrumpe, WhatsApp **se salta la restauración** y te deja la cuenta vacía, y ya no hay vuelta atrás
   desde esa copia. Con la memoria libre son 5-10 minutos.
4. Repite con **WhatsApp Business** si lo usas.

### Comprueba el multimedia después de restaurar

WhatsApp **reorganiza su carpeta** al restaurar. En nuestra prueba, después de restaurar faltaban 398
vídeos (3,75 GB) de `WhatsApp Video/Private/` y `Sent/`, y 647 notas de voz se habían quedado en 0 bytes.
Los originales estaban intactos en el PC y se devolvieron uno a uno.

Así que: cuando WhatsApp termine, **compara otra vez** con tu copia del PC. Si falta algo, vuelve a enviar
esos archivos con `adb push`. La aplicación ya no los borra en ese punto.

## Paso 4 — El resto de las cuentas

Esto es manual y no hay forma de evitarlo. Prepárate para volver a entrar en:

- Correo, Telegram, redes sociales, aplicaciones de trabajo.
- Banca y carteras de criptomonedas: piden verificación por SMS o reinstalar el dispositivo de confianza.
- Verificación en dos pasos: si tenías la copia en la nube activada, la aplicación los recupera al iniciar
  sesión en Google. Si no, hay que reconfigurar cada servicio uno a uno.

## Paso 5 — Comprobar que todo funciona

Antes de dar por bueno el móvil:

- [ ] Llamadas (hablar y que te oigan), SMS, datos móviles, Wi-Fi
- [ ] Bluetooth, **incluido el micrófono en una llamada real** con auriculares
- [ ] Cámaras (todas), micrófono, altavoz, auricular
- [ ] Huella, NFC si lo usas, carga
- [ ] Que tus fotos y tus chats están donde deben

**No vuelvas a bloquear el bootloader.** Con otro sistema instalado, bloquearlo puede dejar el móvil sin
arrancar.

Siguiente: [5. Trampas conocidas](05-trampas.md)
