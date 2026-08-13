import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Provide default API key (will be overridden by fetched key from backend)
    GMSServices.provideAPIKey("AIzaSyDbBK9qmNgAVBK0-t0tEN3tRE-XhDdS4_8")

    GeneratedPluginRegistrant.register(with: self)

    // Setup method channel to handle API key updates from Dart
    setupMethodChannels()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Setup method channels to communicate with Flutter
  private func setupMethodChannels() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }

    let methodChannel = FlutterMethodChannel(
      name: "com.zenfoo.partner/google_maps",
      binaryMessenger: controller.binaryMessenger
    )

    methodChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "updateGoogleApiKey":
        if let args = call.arguments as? [String: Any],
           let apiKey = args["apiKey"] as? String {
          // Update Google Maps API key
          GMSServices.provideAPIKey(apiKey)
          debugPrint("✅ Google Maps API Key updated: \(apiKey)")
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "API key not provided", details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
