#include "include/wifi/wifi_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar.h>
#include <flutter/standard_method_codec.h>

#include <atomic>
#include <cstdio>
#include <memory>
#include <string>
#include <thread>

struct _FlWifiPlugin {
  GObject parent_instance;

  FlMethodChannel* channel = nullptr;
  std::thread* monitor_thread = nullptr;
  std::atomic<bool> should_stop{false};
  std::string current_ssid;
};

G_DEFINE_TYPE(FlWifiPlugin, fl_wifi_plugin, G_TYPE_OBJECT)

static std::string get_ssid() {
  FILE* fp = popen("nmcli -t -f active,ssid dev wifi 2>/dev/null", "r");
  if (!fp) return "";

  char buf[256];
  std::string result;
  while (fgets(buf, sizeof(buf), fp)) {
    std::string line(buf);
    if (line.rfind("yes:", 0) == 0) {
      result = line.substr(4);
      if (!result.empty() && result.back() == '\n') result.pop_back();
      break;
    }
  }
  pclose(fp);
  return result;
}

static void monitor_thread_func(FlWifiPlugin* self) {
  while (!self->should_stop.load()) {
    std::this_thread::sleep_for(std::chrono::seconds(3));
    std::string ssid = get_ssid();
    if (ssid != self->current_ssid) {
      self->current_ssid = ssid;
      g_main_context_invoke(
          nullptr,
          [](gpointer data) -> gboolean {
            auto* plugin = static_cast<FlWifiPlugin*>(data);
            const auto& sid = plugin->current_ssid;
            g_autoptr(FlValue) val = sid.empty()
                ? fl_value_new_null()
                : fl_value_new_string(sid.c_str());
            fl_method_channel_invoke_method(
                plugin->channel, "ssidChanged", val, nullptr, nullptr, nullptr);
            return FALSE;
          },
          self);
    }
  }
}

static void wifi_plugin_handle_method_call(
    FlWifiPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;
  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "getCurrentSsid") == 0) {
    std::string ssid = get_ssid();
    self->current_ssid = ssid;
    response = ssid.empty()
        ? FL_METHOD_RESPONSE(fl_method_success_response(fl_value_new_null()))
        : FL_METHOD_RESPONSE(fl_method_success_response(
              fl_value_new_string(ssid.c_str())));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response());
  }

  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond(method_call, response, &error)) {
    g_warning("Failed to send response: %s", error->message);
  }
}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  wifi_plugin_handle_method_call(
      static_cast<FlWifiPlugin*>(user_data), method_call);
}

static void fl_wifi_plugin_dispose(GObject* object) {
  FlWifiPlugin* self = FL_WIFI_PLUGIN(object);

  self->should_stop.store(true);
  if (self->monitor_thread) {
    if (self->monitor_thread->joinable()) {
      self->monitor_thread->join();
    }
    delete self->monitor_thread;
    self->monitor_thread = nullptr;
  }

  g_clear_object(&self->channel);
  G_OBJECT_CLASS(fl_wifi_plugin_parent_class)->dispose(object);
}

static void fl_wifi_plugin_class_init(FlWifiPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_wifi_plugin_dispose;
}

static void fl_wifi_plugin_init(FlWifiPlugin* self) {}

void fl_wifi_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  FlWifiPlugin* plugin =
      FL_WIFI_PLUGIN(g_object_new(fl_wifi_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  plugin->channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "com.follow.clash/wifi",
      FL_METHOD_CODEC(codec));

  fl_method_channel_set_method_call_handler(
      plugin->channel, method_call_cb, plugin, nullptr);

  plugin->current_ssid = get_ssid();
  plugin->monitor_thread = new std::thread(monitor_thread_func, plugin);
}
