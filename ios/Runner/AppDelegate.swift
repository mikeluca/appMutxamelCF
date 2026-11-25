import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Abrir los ajustes de la app (sustituye al plugin app_settings).
    let canal = FlutterMethodChannel(
      name: "com.mutxamelcf.app/ajustes",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    canal.setMethodCallHandler { call, result in
      switch call.method {
      case "abrirAjustesNotificaciones", "abrirAjustesApp":
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
          result(nil)
          return
        }
        DispatchQueue.main.async {
          UIApplication.shared.open(url, options: [:], completionHandler: nil)
          result(nil)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
