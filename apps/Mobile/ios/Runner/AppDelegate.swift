import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    var mapsKey = ""
    if let key = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String {
      mapsKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    if mapsKey.hasPrefix("$(") {
      mapsKey = ""
    }
    if mapsKey.isEmpty || mapsKey.contains("YOUR_") {
      mapsKey = ProcessInfo.processInfo.environment["GOOGLE_MAPS_API_KEY"] ?? ""
    }
    if !mapsKey.isEmpty {
      GMSServices.provideAPIKey(mapsKey)
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
