package com.example.battery

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result


/**
 * Android-часть плагина Battery.
 *
 * Работает через MethodChannel.
 */
class BatteryPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var binding: FlutterPlugin.FlutterPluginBinding
    private var batteryReceiver: BroadcastReceiver? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, methodChannel)
        channel.setMethodCallHandler(this)
        binding = flutterPluginBinding
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            // Текущее состояние батареи.
            getBatteryStatusMethod -> {
                result.success(getBatteryStatus())
            }
            // Запуск прослушивания.
            startListeningMethod -> {
                createAndRegisterReceiver()
                result.success(true)
            }
            // Остановка прослушивания.
            stopListeningMethod -> {
                unregisterReceiver()
                result.success(true)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        unregisterReceiver()
    }

    private fun getBatteryStatus(): List<Any>? {
        val batteryStatus: Intent = registerReceiver(null) ?: return null
        return getBatteryStatusFromIntent(batteryStatus)
    }

    private fun getBatteryStatusFromIntent(batteryStatus: Intent): List<Any> {
        val level = batteryStatus.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) * 100 /
                batteryStatus.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
        val status = batteryStatus.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
        val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING
                || status == BatteryManager.BATTERY_STATUS_FULL
        val chargePlugged = batteryStatus.getIntExtra(BatteryManager.EXTRA_PLUGGED, -1)
        val health = batteryStatus.getIntExtra(BatteryManager.EXTRA_HEALTH, -1)
        val temperature = batteryStatus.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1)
        val voltage = batteryStatus.getIntExtra(BatteryManager.EXTRA_VOLTAGE, -1)
        val technology = batteryStatus.getStringExtra(BatteryManager.EXTRA_TECHNOLOGY) ?: "unknown"

        return listOf<Any>(
                level,
                isCharging,
                when (chargePlugged) {
                    BatteryManager.BATTERY_PLUGGED_USB -> 1
                    BatteryManager.BATTERY_PLUGGED_AC -> 2
                    BatteryManager.BATTERY_PLUGGED_WIRELESS -> 3
                    else -> 0
                },
                when (health) {
                    BatteryManager.BATTERY_HEALTH_GOOD -> 1
                    BatteryManager.BATTERY_HEALTH_OVERHEAT -> 2
                    BatteryManager.BATTERY_HEALTH_DEAD -> 3
                    BatteryManager.BATTERY_HEALTH_OVER_VOLTAGE -> 4
                    BatteryManager.BATTERY_HEALTH_UNSPECIFIED_FAILURE -> 5
                    BatteryManager.BATTERY_HEALTH_COLD -> 6
                    else -> 0
                },
                temperature,
                voltage,
                technology
        )
    }

    private fun createAndRegisterReceiver() {
        unregisterReceiver()
        batteryReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent) {
                val status = getBatteryStatusFromIntent(intent)
                channel.invokeMethod(onBatteryChangedMethod, status)
            }
        }
        registerReceiver(batteryReceiver)
    }

    private fun registerReceiver(batteryReceiver: BroadcastReceiver?): Intent? {
        return IntentFilter(Intent.ACTION_BATTERY_CHANGED).let {
            binding.applicationContext.registerReceiver(batteryReceiver, it)
        }
    }

    private fun unregisterReceiver() {
        if (batteryReceiver != null) {
            binding.applicationContext.unregisterReceiver(batteryReceiver)
            batteryReceiver = null
        }
    }

    companion object {
        const val methodChannel: String = "battery"
        const val getBatteryStatusMethod: String = "getBatteryStatus"
        const val onBatteryChangedMethod: String = "onBatteryChanged"
        const val startListeningMethod: String = "startListening"
        const val stopListeningMethod: String = "stopListening"
    }
}
