import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

class Wifi {
  static Wifi? _instance;
  late MethodChannel methodChannel;
  final _ssidController = StreamController<String?>.broadcast();

  Timer? _pollTimer;
  String? _lastSsid;

  Wifi._internal() {
    methodChannel = const MethodChannel('com.follow.clash/wifi');
    methodChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'ssidChanged':
          final ssid = call.arguments as String?;
          _lastSsid = ssid;
          _ssidController.add(ssid);
          break;
        default:
          throw MissingPluginException();
      }
    });
  }

  factory Wifi() {
    _instance ??= Wifi._internal();
    return _instance!;
  }

  Stream<String?> get onSsidChanged => _ssidController.stream;

  String? get currentSsid => _lastSsid;

  Future<String?> getCurrentSsid() async {
    try {
      final ssid = await methodChannel.invokeMethod<String>('getCurrentSsid');
      _lastSsid = ssid;
      return ssid;
    } on MissingPluginException {
      return _getLinuxSsid();
    }
  }

  void startLinuxPolling() {
    if (_pollTimer != null) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final ssid = await _getLinuxSsid();
      if (ssid != _lastSsid) {
        _lastSsid = ssid;
        _ssidController.add(ssid);
      }
    });
  }

  Future<String?> _getLinuxSsid() async {
    if (!Platform.isLinux) return null;
    try {
      final result = await Process.run('nmcli', [
        '-t', '-f', 'active,ssid', 'dev', 'wifi',
      ]);
      if (result.exitCode != 0) return null;
      for (final line in result.stdout.toString().trim().split('\n')) {
        if (line.startsWith('yes:')) {
          return line.substring(4);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _pollTimer?.cancel();
    _ssidController.close();
  }
}

final wifi = Wifi();
