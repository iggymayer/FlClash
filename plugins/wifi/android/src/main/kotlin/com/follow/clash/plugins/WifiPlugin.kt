package com.follow.clash.plugins

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.wifi.WifiManager
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class WifiPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private var channel: MethodChannel? = null
    private var wifiManager: WifiManager? = null
    private var connectivityManager: ConnectivityManager? = null
    private var currentSsid: String? = null

    private val networkCallback = object : ConnectivityManager.NetworkCallback() {
        override fun onCapabilitiesChanged(network: Network, caps: NetworkCapabilities) {
            val ssid = getWifiSsid()
            if (ssid != currentSsid) {
                currentSsid = ssid
                channel?.invokeMethod("ssidChanged", ssid)
            }
        }

        override fun onLost(network: Network) {
            if (currentSsid != null) {
                currentSsid = null
                channel?.invokeMethod("ssidChanged", null)
            }
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val ctx = binding.applicationContext
        wifiManager = ctx.getSystemService(Context.WIFI_SERVICE) as WifiManager
        connectivityManager = ctx.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

        channel = MethodChannel(binding.binaryMessenger, "com.follow.clash/wifi")
        channel?.setMethodCallHandler(this)

        connectivityManager?.registerNetworkCallback(
            NetworkRequest.Builder().addTransportType(NetworkCapabilities.TRANSPORT_WIFI).build(),
            networkCallback
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        try { connectivityManager?.unregisterNetworkCallback(networkCallback) } catch (_: Exception) {}
        connectivityManager = null
        wifiManager = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getCurrentSsid" -> {
                val ssid = getWifiSsid()
                currentSsid = ssid
                result.success(ssid)
            }
            else -> result.notImplemented()
        }
    }

    private fun getWifiSsid(): String? {
        val manager = wifiManager ?: return null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val caps = connectivityManager?.getNetworkCapabilities(
                connectivityManager?.activeNetwork
            )
            if (caps == null || !caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) {
                return null
            }
        }
        var ssid = manager.connectionInfo.ssid ?: return null
        if (ssid == "<unknown ssid>") return null
        if (ssid.startsWith("\"") && ssid.endsWith("\"")) {
            ssid = ssid.substring(1, ssid.length - 1)
        }
        return ssid
    }
}
