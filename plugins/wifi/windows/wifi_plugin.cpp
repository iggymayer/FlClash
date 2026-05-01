#include "wifi_plugin.h"

#include <windows.h>
#include <wlanapi.h>

#include <memory>
#include <string>

#pragma comment(lib, "wlanapi.lib")

namespace wifi {

static void WlanNotificationCallback(PWLAN_NOTIFICATION_DATA data, PVOID context) {
  if (data == nullptr || context == nullptr) return;

  auto* plugin = static_cast<WifiPlugin*>(context);
  if (data->NotificationSource != WLAN_NOTIFICATION_SOURCE_ACM) return;

  switch (data->NotificationCode) {
    case wlan_notification_acm_connection_complete:
    case wlan_notification_acm_disconnected:
    case wlan_notification_acm_connection_attempt_fail: {
      auto ssid = plugin->GetCurrentSsid();
      if (ssid.empty()) {
        plugin->channel_->InvokeMethod(
            "ssidChanged",
            std::make_unique<flutter::EncodableValue>(flutter::EncodableValue()));
      } else {
        plugin->channel_->InvokeMethod(
            "ssidChanged",
            std::make_unique<flutter::EncodableValue>(flutter::EncodableValue(ssid)));
      }
      break;
    }
    default:
      break;
  }
}

std::string WifiPlugin::GetCurrentSsid() {
  HANDLE handle = nullptr;
  DWORD negotiatedVersion = 0;
  if (WlanOpenHandle(2, nullptr, &negotiatedVersion, &handle) != ERROR_SUCCESS) return "";

  PWLAN_INTERFACE_INFO_LIST ifList = nullptr;
  if (WlanEnumInterfaces(handle, nullptr, &ifList) != ERROR_SUCCESS) {
    WlanCloseHandle(handle, nullptr);
    return "";
  }

  std::string ssid;
  for (DWORD i = 0; i < ifList->dwNumberOfItems; i++) {
    if (ifList->InterfaceInfo[i].isState != wlan_interface_state_connected) continue;

    PWLAN_CONNECTION_ATTRIBUTES connAttr = nullptr;
    DWORD dataSize = sizeof(WLAN_CONNECTION_ATTRIBUTES);
    if (WlanQueryInterface(handle, &ifList->InterfaceInfo[i].InterfaceGuid,
                           wlan_intf_opcode_current_connection, nullptr,
                           &dataSize, (PVOID*)&connAttr, nullptr) == ERROR_SUCCESS &&
        connAttr != nullptr) {
      ssid.assign(reinterpret_cast<const char*>(connAttr->dot11Ssid.ucSSID),
                  connAttr->dot11Ssid.uSSIDLength);
      WlanFreeMemory(connAttr);
      break;
    }
  }

  WlanFreeMemory(ifList);
  WlanCloseHandle(handle, nullptr);
  return ssid;
}

void WifiPlugin::StartMonitoring() {
  HANDLE handle = nullptr;
  DWORD negotiatedVersion = 0;
  if (WlanOpenHandle(2, nullptr, &negotiatedVersion, &handle) != ERROR_SUCCESS) return;

  DWORD prevNotif = 0;
  if (WlanRegisterNotification(handle, WLAN_NOTIFICATION_SOURCE_ACM, TRUE,
                                (WLAN_NOTIFICATION_CALLBACK)WlanNotificationCallback,
                                this, nullptr, &prevNotif) != ERROR_SUCCESS) {
    WlanCloseHandle(handle, nullptr);
    return;
  }

  while (!should_stop_.load()) {
    Sleep(1000);
  }

  WlanRegisterNotification(handle, WLAN_NOTIFICATION_SOURCE_NONE, TRUE,
                           nullptr, nullptr, nullptr, nullptr);
  WlanCloseHandle(handle, nullptr);
}

void WifiPlugin::StopMonitoring() {
  should_stop_.store(true);
  if (monitor_thread_.joinable()) {
    monitor_thread_.join();
  }
}

void WifiPlugin::RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "com.follow.clash/wifi",
      &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<WifiPlugin>(registrar);
  plugin->channel_ = std::move(channel);

  auto* plugin_ptr = plugin.get();
  plugin_ptr->channel_->SetMethodCallHandler(
      [plugin_ptr](const auto& call, auto result) {
        plugin_ptr->HandleMethodCall(call, std::move(result));
      });

  plugin->StartMonitoring();
  registrar->AddPlugin(std::move(plugin));
}

WifiPlugin::WifiPlugin(flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar) {}

WifiPlugin::~WifiPlugin() {
  StopMonitoring();
}

void WifiPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("getCurrentSsid") == 0) {
    auto ssid = GetCurrentSsid();
    if (ssid.empty()) {
      result->Success(flutter::EncodableValue());
    } else {
      result->Success(flutter::EncodableValue(ssid));
    }
  } else {
    result->NotImplemented();
  }
}

}  // namespace wifi
