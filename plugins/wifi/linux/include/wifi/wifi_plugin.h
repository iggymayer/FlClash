#ifndef FLUTTER_PLUGIN_WIFI_PLUGIN_H_
#define FLUTTER_PLUGIN_WIFI_PLUGIN_H_

#include <flutter_linux/flutter_linux.h>

G_DECLARE_FINAL_TYPE(FlWifiPlugin, fl_wifi_plugin, FL, WIFI_PLUGIN, GObject)

void fl_wifi_plugin_register_with_registrar(FlPluginRegistrar* registrar);

#endif  // FLUTTER_PLUGIN_WIFI_PLUGIN_H_
