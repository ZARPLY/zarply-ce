import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func didInitializeImplicitFlutterEngine() {
    GeneratedPluginRegistrant.register(with: self)
  }
}
