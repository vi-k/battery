import 'dart:async';
import 'package:flutter/material.dart';

import 'package:battery/battery.dart';

/// Пример работы с плагином Battery.
void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

/// Вспомогательный класс для анимации изменённых значений.
class AnimatedValue<T> extends ValueNotifier<T> {
  AnimatedValue(T value) : super(value);

  bool _isNew = false;
  bool get isNew => _isNew;

  @override
  set value(T v) {
    _isNew = true;
    super.value = v;

    Future<void>.delayed(const Duration(milliseconds: 100), () {
      _isNew = false;
      notifyListeners();
    });
  }
}

// ignore: prefer_mixin
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final _batteryLevel = AnimatedValue<int?>(null);
  late final _batteryIsCharging = AnimatedValue<bool?>(null);
  late final _batteryChargePlugged = AnimatedValue<BatteryChargePlugged?>(null);
  late final _batteryHealth = AnimatedValue<BatteryHealth?>(null);
  late final _batteryTemperature = AnimatedValue<int?>(null);
  late final _batteryVoltage = AnimatedValue<int?>(null);
  late final _batteryTechnology = AnimatedValue<String?>(null);
  late final _listen = ValueNotifier<bool>(false);
  final battery = Battery();

  @override
  void initState() {
    WidgetsBinding.instance!.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    _batteryLevel.dispose();
    _batteryIsCharging.dispose();
    _batteryChargePlugged.dispose();
    _batteryHealth.dispose();
    _batteryTemperature.dispose();
    _batteryVoltage.dispose();
    _batteryTechnology.dispose();
    _listen.dispose();
    battery.removeListener();
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('$state');
    if (state == AppLifecycleState.paused) {
      battery.pause();
    } else if (state == AppLifecycleState.resumed) {
      battery.resume();
    }

    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Battery plugin example app'),
          ),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildValue<int?>(
                  'Battery level',
                  _batteryLevel,
                  (value) => '${value ?? '-'}',
                ),
                _buildValue<bool?>(
                  'Is charging',
                  _batteryIsCharging,
                  (value) => '${value ?? '-'}',
                ),
                _buildValue<BatteryChargePlugged?>(
                  'Charge plugged',
                  _batteryChargePlugged,
                  (value) => value?.name ?? '-',
                ),
                _buildValue<BatteryHealth?>(
                  'Health',
                  _batteryHealth,
                  (value) => value?.name ?? '-',
                ),
                _buildValue<int?>(
                  'Temperature',
                  _batteryTemperature,
                  (value) => '${value ?? '-'}',
                ),
                _buildValue<int?>(
                  'Voltage',
                  _batteryVoltage,
                  (value) => '${value ?? '-'}',
                ),
                _buildValue<String?>(
                  'Technology',
                  _batteryTechnology,
                  (value) => value ?? '-',
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.battery_unknown),
                  label: const Text('Get battery status'),
                  onPressed: _getBatteryStatusAsync,
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: _listen,
                  builder: (context, value, child) => ElevatedButton.icon(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                          value ? Colors.orange : Colors.blue),
                    ),
                    icon: Icon(value ? Icons.mark_email_read : Icons.email),
                    label: Text(value ? 'Unsubscribe' : 'Subscribe'),
                    onPressed: _subscribe,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildValue<T>(String caption, AnimatedValue<T> value,
          String Function(T value) text) =>
      ValueListenableBuilder<T>(
        valueListenable: value,
        builder: (context, value, child) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$caption: '),
            AnimatedContainer(
              key: ValueKey(value),
              duration: const Duration(milliseconds: 500),
              color: _batteryChargePlugged.isNew
                  ? Colors.blue
                  : Colors.transparent,
              child: Text(text(value)),
            ),
          ],
        ),
      );

  Future<void> _getBatteryStatusAsync() async {
    final status = await Battery.status;
    _statusToValues(status);
  }

  void _statusToValues(BatteryStatus? status) {
    debugPrint('${DateTime.now()}: $status');
    _batteryLevel.value = status?.level;
    _batteryIsCharging.value = status?.isCharging;
    _batteryChargePlugged.value = status?.chargePlugged;
    _batteryHealth.value = status?.health;
    _batteryTemperature.value = status?.temperature;
    _batteryVoltage.value = status?.voltage;
    _batteryTechnology.value = status?.technology;
  }

  Future<void> _subscribe() async {
    if (battery.hasListener) {
      debugPrint('removeListener');
      await battery.removeListener();
    } else {
      debugPrint('setListener');
      await battery.setListener(_statusToValues);
    }

    _listen.value = battery.hasListener;
  }
}
