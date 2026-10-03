package com.bubu.bubu_kitchen

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var notificationResult: MethodChannel.Result? = null
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 41) {
            notificationResult?.success(null)
            notificationResult = null
        }
    }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.bubu.kitchen/assistant")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "keepAwake" -> {
                        if (call.argument<Boolean>("enabled") == true) window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        else window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        result.success(null)
                    }
                    "status" -> {
                        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
                        val allowed = (Build.VERSION.SDK_INT < 33 || checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) && manager.areNotificationsEnabled()
                        val alarms = getSystemService(ALARM_SERVICE) as AlarmManager
                        result.success(mapOf("notifications" to allowed, "exact" to (Build.VERSION.SDK_INT < 31 || alarms.canScheduleExactAlarms())))
                    }
                    "requestNotifications" -> {
                        if (Build.VERSION.SDK_INT >= 33 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                            if (notificationResult != null) { result.success(null); return@setMethodCallHandler }
                            notificationResult = result
                            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 41)
                        } else {
                            val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
                            if (!manager.areNotificationsEnabled()) startActivity(Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, packageName))
                        }
                        if (notificationResult == null) result.success(null)
                    }
                    "requestExact" -> {
                        if (Build.VERSION.SDK_INT >= 31) {
                            val alarms = getSystemService(ALARM_SERVICE) as AlarmManager
                            if (!alarms.canScheduleExactAlarms()) startActivity(Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, Uri.parse("package:$packageName")))
                        }
                        result.success(null)
                    }
                    "schedule" -> {
                        val id = call.argument<Number>("id")!!.toInt()
                        KitchenAlarmReceiver.schedule(this, id, call.argument<Number>("at")!!.toLong(),
                            call.argument<String>("title") ?: "厨房计时",
                            call.argument<String>("body") ?: "请回灶边检查状态",
                            call.argument<Number>("interval")?.toLong() ?: 0L,
                            call.argument<Number>("until")?.toLong() ?: 0L)
                        result.success(null)
                    }
                    "cancel" -> { KitchenAlarmReceiver.cancel(this, call.argument<Number>("id")!!.toInt()); result.success(null) }
                    else -> result.notImplemented()
                }
            }
    }
}
