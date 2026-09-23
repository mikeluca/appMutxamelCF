# Puesta a punto de iOS — Mutxamel CF App

Guía paso a paso para dejar la app funcionando en un iPhone físico. Pensada
para retomarla en cualquier momento sin perder el hilo: cada parte es
independiente y puedes marcar las casillas según avances.

## Ya hecho en el repo (no hace falta repetirlo)

- [x] `ios/Runner/Runner.entitlements` creado y enlazado en el proyecto Xcode
      (capability Push Notifications / `aps-environment`).
- [x] `ios/Runner/Info.plist`: añadido `UIBackgroundModes` con
      `remote-notification` (para que las push lleguen en segundo plano).
- [x] `ios/Runner/Info.plist`: añadida excepción de App Transport Security
      (`NSAllowsArbitraryLoads`) porque el backend todavía se sirve por
      `http://` sin TLS. **Quitar esta excepción en cuanto el backend tenga
      HTTPS.**
- [x] El código Dart ya inicializa Firebase correctamente
      (`main.dart` → `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`)
      y ya pide permiso de notificaciones (`push_notification_service.dart`).

## Pendiente (bundle id real + registro en Apple/Firebase)

Esto no se pudo hacer sin acceso a las cuentas de Apple Developer / Firebase,
así que queda para hacerlo desde el Mac. Todo el resto de este documento
son los pasos para completarlo.

---

## Parte 1 — Instalar herramientas en el Mac

- [ ] **Xcode** (App Store). Al terminar, ábrelo una vez, acepta la licencia
      y deja que instale los "Additional Components" si lo pide.
- [ ] **Command Line Tools** (Terminal):
  ```
  xcode-select --install
  sudo xcodebuild -license accept
  ```
- [ ] **Homebrew** (si no lo tienes):
  ```
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ```
- [ ] **Flutter SDK**: https://docs.flutter.dev/get-started/install/macos
      (añadir `flutter` al PATH).
- [ ] **CocoaPods**: `brew install cocoapods`
- [ ] **Node.js** (hace falta para el Firebase CLI): `brew install node`
- [ ] **Firebase CLI**:
  ```
  npm install -g firebase-tools
  firebase login
  ```
- [ ] **FlutterFire CLI**:
  ```
  dart pub global activate flutterfire_cli
  ```
  Si el terminal no encuentra luego el comando `flutterfire`, añade a tu
  `~/.zshrc`:
  ```
  export PATH="$PATH:$HOME/.pub-cache/bin"
  ```
  y abre una terminal nueva.
- [ ] Trae el proyecto al Mac (clónalo o cópialo) y, desde la carpeta
      `appMutxamelCF`:
  ```
  flutter pub get
  flutter doctor
  ```
  Resuelve cualquier `✗` que salga.

---

## Parte 2 — Cuenta de Apple Developer

Decisión importante antes de seguir:

| | Apple ID gratuito | Apple Developer Program (99 $/año) |
|---|---|---|
| Instalar en tu propio iPhone por cable | Sí | Sí |
| Caduca la app en el dispositivo | A los 7 días (hay que reinstalar) | No caduca |
| Notificaciones push reales (APNs) | **No funcionan** | Sí |
| Subir a TestFlight / App Store | No | Sí |

Como las notificaciones push son parte central de la app, conviene dar de
alta la cuenta de pago cuanto antes:

- [ ] Ir a https://developer.apple.com → "Enroll" → pagar → esperar
      aprobación (a veces instantánea, a veces hasta 48h).

---

## Parte 3 — Bundle ID real + reconectar con Firebase

El proyecto usa ahora mismo el bundle id de plantilla `com.example.appmtx`
para iOS. Hay que pasarlo a uno real, igual que ya tiene Android:
`com.mutxamelcf.app`.

- [ ] En **developer.apple.com** → Certificates, Identifiers & Profiles →
      Identifiers → **+** → App IDs → App → Bundle ID explícito
      `com.mutxamelcf.app` → marcar la capability **Push Notifications** →
      Register.
- [ ] En **console.firebase.google.com** → proyecto `mutxamelcf-4b1dd` →
      ⚙️ Configuración del proyecto → pestaña "Tus apps" → Añadir app → iOS
      → bundle id `com.mutxamelcf.app` → Registrar app.
- [ ] En el Mac, dentro de `appMutxamelCF`:
  ```
  flutterfire configure
  ```
  Selecciona el proyecto `mutxamelcf-4b1dd`, marca la plataforma iOS (deja
  las demás como estén). Esto reescribe `lib/firebase_options.dart` con los
  valores correctos para el nuevo bundle id.
- [ ] Abre **`ios/Runner.xcworkspace`** en Xcode (a partir de aquí, nunca el
      `.xcodeproj`).
- [ ] Pestaña **Signing & Capabilities** del target Runner:
  - [ ] Cambiar "Bundle Identifier" a `com.mutxamelcf.app`.
  - [ ] "Team" → elegir tu cuenta de Apple Developer.
  - [ ] Activar "Automatically manage signing".
  - [ ] Comprobar que aparece la capability **Push Notifications** en la
        lista (ya está el entitlement metido en el proyecto; si no aparece
        sola, pulsa "+ Capability" y añádela a mano).

---

## Parte 4 — Clave APNs (para que las push funcionen de verdad)

Solo posible con cuenta de pago (Parte 2).

- [ ] developer.apple.com → Certificates, Identifiers & Profiles →
      **Keys** → **+** → marcar "Apple Push Notifications service (APNs)" →
      Continue → Register.
- [ ] Descargar el fichero `.p8` (**solo se puede descargar una vez**,
      guardarlo en un sitio seguro) y anotar el **Key ID** y el **Team ID**
      (arriba a la derecha de la web de Apple Developer).
- [ ] En Firebase console → ⚙️ Configuración del proyecto → pestaña
      **Cloud Messaging** → sección "Configuración de app de Apple" → subir
      ese `.p8` con su Key ID y Team ID.

---

## Parte 5 — Primera compilación

Desde terminal, en `appMutxamelCF`:

```
flutter clean
flutter pub get
cd ios
pod install
cd ..
```

`pod install` puede tardar varios minutos la primera vez.

---

## Parte 6 — Preparar el iPhone y ejecutar

- [ ] Revisar `lib/core/config/app_config.dart`. Ahora mismo apunta a
      `http://192.168.1.160:8080/api`. Si el backend está en otra IP cuando
      pruebes, actualízala (o descomenta la línea de la IP pública si el
      backend es accesible por ahí). El iPhone debe poder alcanzar esa
      dirección — si usas la IP local, el iPhone tiene que estar en la
      **misma red WiFi** que el servidor.
- [ ] Conectar el iPhone al Mac por cable.
- [ ] En el iPhone: **Ajustes → Privacidad y seguridad → Modo desarrollador**
      → activarlo → reiniciar cuando lo pida.
- [ ] Abrir `ios/Runner.xcworkspace` en Xcode y, en la barra superior,
      seleccionar el iPhone como destino (en vez de un simulador).
- [ ] Pulsar ▶ Run. También sirve por terminal:
  ```
  flutter devices        # para ver el ID de tu iPhone
  flutter run -d <ID>
  ```
- [ ] La primera vez fallará la instalación y aparecerá en el iPhone un
      aviso de "desarrollador no confiable": ir a **Ajustes → General →
      VPN y gestión de dispositivos**, tocar el certificado de desarrollador
      y pulsar "Confiar".
- [ ] Volver a pulsar ▶ Run.

---

## Parte 7 — Verificar que funciona

- [ ] La app arranca y puedes hacer login contra el backend.
- [ ] Al abrir la sección de notificaciones, iOS pide permiso — aceptar.
- [ ] Enviar una notificación de prueba desde el panel de administración web
      y comprobar que llega al iPhone con la app en segundo plano.
- [ ] Si algo falla, revisar la consola de Xcode (parte inferior, con el
      dispositivo conectado) — ahí salen los errores nativos que no se ven
      en `flutter run`.

---

## Notas

- **Cuenta gratuita**: todo lo de arriba funciona igual salvo la Parte 4
  (no se puede crear la clave APNs, así que las notificaciones no
  llegarán), y hay que repetir los últimos pasos de la Parte 6 cada 7 días
  cuando la app caduque en el iPhone.
- **HTTPS pendiente**: en cuanto el backend tenga certificado TLS, quitar
  el bloque `NSAppTransportSecurity` de `ios/Runner/Info.plist` y cambiar
  `apiBaseUrl` en `lib/core/config/app_config.dart` a `https://`.
