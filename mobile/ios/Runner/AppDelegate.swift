import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let screenSecurityChannel = "com.anbu.matrimony/screen_security"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    GeneratedPluginRegistrant.register(with: self)
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return result
    }

    let channel = FlutterMethodChannel(
      name: screenSecurityChannel,
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { call, reply in
      guard call.method == "setSecure" else {
        reply(FlutterMethodNotImplemented)
        return
      }
      // iOS does not provide a supported API to prevent screenshots.
      // Treat the request as a no-op; use capture-state detection only as a deterrent.
      reply(nil)
    }
    return result
  }
}
