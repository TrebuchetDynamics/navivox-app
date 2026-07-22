import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private static let hostCommandChannelName =
    "com.trebuchetdynamics.hermes.wing/desktop_host_commands"
  private var hostCommandChannel: FlutterMethodChannel?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
    guard let controller = mainFlutterWindow?.contentViewController as? FlutterViewController else {
      return
    }
    hostCommandChannel = FlutterMethodChannel(
      name: Self.hostCommandChannelName,
      binaryMessenger: controller.engine.binaryMessenger
    )
  }

  @IBAction func openSettings(_ sender: Any?) {
    mainFlutterWindow?.makeKeyAndOrderFront(sender)
    NSApp.activate(ignoringOtherApps: true)
    hostCommandChannel?.invokeMethod("openSettings", arguments: nil)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
