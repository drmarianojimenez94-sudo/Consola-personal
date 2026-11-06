# Neon Panel

Consola tipo PlayStation para una PC con Windows conectada a una TV, con una **app de celular** (PWA) que sirve de **joystick, mouse, teclado y micr&oacute;fono**.

- **Consola (TV):** pantalla completa en Edge (modo kiosco). Orbitales que giran sobre un fondo de galaxia; cada categor&iacute;a (juegos, streaming, m&uacute;sica, mensajes, asistentes, nube, rendimiento, sistema) abre su propia &oacute;rbita. Datos en vivo: sistema, descargas de Steam, finanzas (d&oacute;lar, real, BTC, ETH) y clima.
- **App del celular (`phone/`):** se abre desde el navegador del tel&eacute;fono y se puede agregar a la pantalla de inicio.
  - **Joystick:** cruceta, palanca virtual, A/B/X/Y, LB/RB, START/BACK.
  - **Mouse:** touchpad (mover, clic, clic derecho, scroll).
  - **Voz:** dictado del tel&eacute;fono; frases como &ldquo;reproduc&iacute; Frozen 2 en Disney&rdquo;, &ldquo;abrime YouTube videos de Ghibli&rdquo;, &ldquo;abr&iacute; Left 4 Dead&rdquo;, &ldquo;modo consola&rdquo;.
  - **Teclado:** escribir en la PC, teclas, volumen y multimedia.
- **Conexi&oacute;n: Wi-Fi.** El tel&eacute;fono y la PC deben estar en la misma red.

## Requisitos
Windows 10/11, Microsoft Edge, PowerShell 5.1 (viene con Windows). Opcional: Steam, NVIDIA (`nvidia-smi`) para mostrar temperatura/uso.

## Instalaci&oacute;n
```powershell
git clone <este repo>
cd neon-panel
.\install\install.ps1
```
Se inicia solo al abrir sesi&oacute;n. La primera vez Windows pide permiso de firewall para PowerShell: elegir **Redes privadas**.

## Vincular el tel&eacute;fono
1. En la TV, arriba a la derecha, aparece `TEL: <ip>:8443  PIN <6 d&iacute;gitos>`.
2. En el celular abr&iacute; `https://<ip>:8443`. El certificado es auto-firmado: aceptar la advertencia.
3. Ingres&aacute; el PIN. Queda guardado en el tel&eacute;fono.
4. Opcional: &ldquo;Agregar a pantalla de inicio&rdquo; para usarla como app.

## Bluetooth
Una web app no puede actuar como mando Bluetooth de una PC (Web Bluetooth solo habla con dispositivos BLE, no emula un teclado/mouse). Por eso la v1 usa Wi-Fi. Un mando Bluetooth real (HID) requerir&iacute;a una app nativa de Android o parear el celular como teclado Bluetooth con una app de terceros.

## Seguridad (leer)
- El control del mouse/teclado de la PC est&aacute; protegido por **PIN de 6 d&iacute;gitos**, bloqueo de 60 s tras 5 fallos por IP, solo IPs de red local y TLS 1.2. Es adecuado para una red dom&eacute;stica de confianza; **no lo expongas a Internet**.
- El servidor local (`127.0.0.1:8777`) rechaza peticiones de otros or&iacute;genes y solo lanza apps/sitios de listas blancas.
- Pendientes conocidos: token por sesi&oacute;n en el puerto local, tarea que relance los procesos si caen, mostrar el PIN solo a pedido.

## Estructura
```
pc/       servidor local, recolector de datos, servidor HTTPS del tel&eacute;fono y la consola (index.html)
phone/    app del celular (PWA): index.html, manifest, service worker, icono
install/  install.ps1 / uninstall.ps1
```

## Personalizaci&oacute;n
- `pc/rates.json` (se crea desde `rates.example.json`): tu TNA de Mercado Pago (no tiene API p&uacute;blica) y la ciudad del clima.
- Categor&iacute;as y accesos: arreglo `CATS` en `pc/index.html`.
- Plataformas de b&uacute;squeda por voz: tabla `$search` en `pc/server.ps1`.

## Ajustes opcionales
- `pc/data/settings.json`: `{"kioskGpu": true}` activa la aceleración por GPU del panel (por defecto está desactivada para reducir carga y riesgo de cuelgues).
- Categorías RECIENTES (automática), HOSPITAL y PACIENTES usan carpetas locales `Hospital` y `Pacientes` del perfil de usuario (no se suben al repositorio).
