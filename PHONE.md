# Neon Remote: guía del teléfono

## Qué es
Una web app (PWA) que se abre en el navegador del celular y convierte el teléfono en **joystick, mouse, teclado y micrófono** del panel de la TV. Conexión por **Wi-Fi** (misma red que la PC).

## Cómo vincularlo (una sola vez)
1. Conectá el celular al mismo Wi-Fi que la PC.
2. En la TV, arriba a la derecha del panel, leé: `TEL: <ip>:8443  PIN <6 dígitos>`.
3. En el celular abrí `https://<ip>:8443` (la IP que muestra la TV).
4. El navegador avisará que la conexión no es privada (certificado propio de tu PC): *Avanzado → Continuar*.
5. Ingresá el PIN y tocá **Vincular**. Queda guardado en el celular.
6. Opcional: menú del navegador → *Agregar a pantalla de inicio* para usarla como app.

## Cómo se usa (una sola pantalla)
- **Cruceta:** moverse por las órbitas (mantener apretado repite).
- **Micrófono en el centro:** tocalo y hablá ("reproducí Frozen 2 en Disney", "abrime YouTube videos de Ghibli", "abrí Left 4 Dead", "mail", "clima", "volver").
- **ENTRAR / VOLVER:** abajo, botones grandes.
- **Recordarme (arriba):** mantiene el teléfono vinculado; si lo apagás, el PIN solo dura mientras la app está abierta.
- **Más (menú plegable):** touchpad de mouse, escribir en la PC, teclas y envío de ubicación del teléfono (solo mientras la app está abierta).
## Cómo funciona por dentro
`celular → HTTPS :8443 (PIN) → servidor del teléfono → panel (127.0.0.1:8777) / entradas de Windows`.
El panel consulta cada ~0,8 s las órdenes pendientes; mouse y teclas se ejecutan directo en la PC.

## Problemas frecuentes
- **No abre la página:** el celular debe estar en el mismo Wi-Fi; probá desactivar "aislamiento de clientes/AP isolation" del router.
- **Aviso de certificado:** es normal (certificado propio). Aceptalo una vez.
- **"PIN incorrecto" / bloqueo 60 s:** 5 fallos seguidos bloquean esa IP por un minuto. El PIN está en la TV y en `pc/data/pin.txt`.
- **El micrófono no responde:** permití el micrófono al navegador; si no hay dictado, usá el micrófono del teclado del celular en la pestaña Teclado.
- **Bluetooth:** una web app no puede ser un mando Bluetooth de una PC; por eso usa Wi-Fi.
- **Fuera de casa:** no está expuesto a Internet a propósito. Para eso haría falta una VPN privada (por ej. Tailscale) con tu cuenta.
