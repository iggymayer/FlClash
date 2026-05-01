import Cocoa
import CoreWLAN
import FlutterMacOS

public class WifiPlugin: NSObject, FlutterPlugin {
    private var channel: FlutterMethodChannel?
    private var currentSsid: String?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.follow.clash/wifi",
            binaryMessenger: registrar.messenger
        )
        let instance = WifiPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)

        instance.startObserving()
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getCurrentSsid":
            let ssid = getCurrentSsid()
            currentSsid = ssid
            result(ssid)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func startObserving() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(wifiStateChanged),
            name: NSNotification.Name.CWSSIDDidChange,
            object: nil
        )
    }

    private func getCurrentSsid() -> String? {
        guard let interface = CWWiFiClient.shared().interface() else { return nil }
        return interface.ssid()
    }

    @objc private func wifiStateChanged() {
        let ssid = getCurrentSsid()
        if ssid != currentSsid {
            currentSsid = ssid
            DispatchQueue.main.async {
                self.channel?.invokeMethod("ssidChanged", arguments: ssid)
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
