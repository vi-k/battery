import 'dart:async';

import 'package:flutter/services.dart';

enum BatteryChargePlugged { no, usb, ac, wireless }

enum BatteryHealth {
  unknown,
  good,
  overheat,
  dead,
  overVoltage,
  unspecifiedFailure,
  cold
}

String _enumName(Object value) {
  final str = value.toString();
  return str.substring(str.indexOf('.') + 1);
}

extension BatteryChargePluggedExt on BatteryChargePlugged {
  String get name => _enumName(this);
}

extension BatteryHealthExt on BatteryHealth {
  String get name => _enumName(this);
}

/// Статус батареи.
class BatteryStatus {
  BatteryStatus({
    required this.level,
    required this.isCharging,
    required this.chargePlugged,
    required this.health,
    required this.temperature,
    required this.voltage,
    required this.technology,
  });

  final int level;
  final bool isCharging;
  final BatteryChargePlugged chargePlugged;
  final BatteryHealth health;
  final int temperature;
  final int voltage;
  final String technology;

  @override
  String toString() => 'BatteryStatus:\n'
      '    level: $level\n'
      '    isCharging: $isCharging\n'
      '    chargePlugged: $chargePlugged\n'
      '    health: $health\n'
      '    temperature: $temperature\n'
      '    voltage: $voltage\n'
      '    technology: $technology';
}

class Battery {
  static const MethodChannel _channel = const MethodChannel('battery');
  static const String getBatteryStatusMethod = 'getBatteryStatus';
  static const String onBatteryStatusChangedMethod = 'onBatteryStatusChanged';
  static const String setBatteryListenerMethod = 'setBatteryListener';
  static const String removeBatteryListenerMethod = 'removeBatteryListener';

  Battery() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == onBatteryStatusChangedMethod) {
        final status = call.arguments as List?;
        if (status != null) {
          _listener?.call(await _statusFromList(status));
        }
      }
    });
  }

  void Function(BatteryStatus)? _listener;
  bool get hasListener => _listener != null;

  static Future<BatteryStatus?> get status async {
    final List? result = await _channel.invokeMethod(getBatteryStatusMethod);
    if (result == null) return null;

    return _statusFromList(result);
  }

  static Future<BatteryStatus> _statusFromList(List list) async {
    return BatteryStatus(
      level: list[0],
      isCharging: list[1],
      chargePlugged: BatteryChargePlugged.values[list[2]],
      health: BatteryHealth.values[list[3]],
      temperature: list[4],
      voltage: list[5],
      technology: list[6],
    );
  }

  Future<void> setListener(void Function(BatteryStatus) listener) async {
    _listener = listener;
    await _channel.invokeMethod(setBatteryListenerMethod);
  }

  Future<void> removeListener() async {
    _listener = null;
    await _channel.invokeMethod(removeBatteryListenerMethod);
  }

  Future<void> pause() async {
    await _channel.invokeMethod(removeBatteryListenerMethod);
  }

  Future<void> resume() async {
    if (_listener != null) {
      await _channel.invokeMethod(setBatteryListenerMethod);
    }
  }
}
