#include "wifi/wifi_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "wifi_plugin.h"

void WifiPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  wifi::WifiPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
