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

/// Плагин для получения информации о состоянии батареи.
///
/// Battery.status - текущее состояние батареи (без создания экземпляра класса).
/// setListener - установка слушателя.
/// removeListener - удаление слушателя.
/// pause - ставит прослушивание на паузу.
/// resume - снимает прослушивание с паузы.
class Battery {
  static const MethodChannel _channel = const MethodChannel('battery');
  static const String getBatteryStatusMethod = 'getBatteryStatus';
  static const String onBatteryChangedMethod = 'onBatteryChanged';
  static const String startListeningMethod = 'startListening';
  static const String stopListeningMethod = 'stopListening';

  Battery() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == onBatteryChangedMethod) {
        final status = call.arguments as List?;
        if (status != null) {
          _listener?.call(await _statusFromList(status));
        }
      }
    });
  }

  void Function(BatteryStatus)? _listener;

  /// Установлен ли слушатель?
  bool get hasListener => _listener != null;

  /// Текущее состояние батареи.
  ///
  /// Статический геттер. Не нуждается в создании экземпляра класса.
  static Future<BatteryStatus?> get status async {
    final List? result = await _channel.invokeMethod(getBatteryStatusMethod);
    if (result == null) return null;

    return _statusFromList(result);
  }

  // Преобразует данные (список значений) с натива в структуру BatteryStatus.
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

  /// Устанавливает слушателя.
  ///
  /// В одном экземпляре класса можеть буть только один слушатель.
  Future<void> setListener(void Function(BatteryStatus) listener) async {
    _listener = listener;
    await _channel.invokeMethod(startListeningMethod);
  }

  /// Удаляет слушателя.
  Future<void> removeListener() async {
    _listener = null;
    await _channel.invokeMethod(stopListeningMethod);
  }

  /// Ставит прослушивание на паузу.
  ///
  /// Слушатель при этом не удаляется.
  Future<void> pause() async {
    await _channel.invokeMethod(stopListeningMethod);
  }

  /// Восстанавливает прослушивание после паузы, если слушатель установлен.
  Future<void> resume() async {
    if (_listener != null) {
      await _channel.invokeMethod(startListeningMethod);
    }
  }
}
