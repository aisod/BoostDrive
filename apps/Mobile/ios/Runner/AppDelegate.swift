import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // For iOS, the API key is typically managed via GoogleService-Info.plist
    // which should be ignored by git. If you prefer .env, you'd need a build script.
    // For now, we'll use a placeholder that reminds you to use the .env key.
    GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY_FROM_DOTENV")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
