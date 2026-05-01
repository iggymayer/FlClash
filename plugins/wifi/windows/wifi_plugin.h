#ifndef FLUTTER_PLUGIN_WIFI_PLUGIN_H_
#define FLUTTER_PLUGIN_WIFI_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <atomic>
#include <memory>
#include <string>
#include <thread>

namespace wifi {

class WifiPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  WifiPlugin(flutter::PluginRegistrarWindows *registrar);
  virtual ~WifiPlugin();

  WifiPlugin(const WifiPlugin&) = delete;
  WifiPlugin& operator=(const WifiPlugin&) = delete;

  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  std::string GetCurrentSsid();

 private:
  void StartMonitoring();
  void StopMonitoring();

  flutter::PluginRegistrarWindows *registrar_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  std::thread monitor_thread_;
  std::atomic<bool> should_stop_{false};
};

}  // namespace wifi

#endif  // FLUTTER_PLUGIN_WIFI_PLUGIN_H_
