import Flutter
import UIKit
import GoogleMaps

/// iOS app delegate for Flutter app startup and Google Maps key setup.
@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    var mapsKey = ""
    // First try to read the key from Info.plist.
    if let key = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String {
      mapsKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    // If the value is still a placeholder variable, treat it as empty.
    if mapsKey.hasPrefix("$(") {
      mapsKey = ""
    }
    // Fallback to environment variable for development/runtime injection.
    if mapsKey.isEmpty || mapsKey.contains("YOUR_") {
      mapsKey = ProcessInfo.processInfo.environment["GOOGLE_MAPS_API_KEY"] ?? ""
    }
    // Initialize Maps SDK only when a real key is available.
    if !mapsKey.isEmpty {
      GMSServices.provideAPIKey(mapsKey)
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
