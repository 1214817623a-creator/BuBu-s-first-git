package com.bubu.bubu_kitchen

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class KitchenAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra("id", 0)
        if (!context.getSharedPreferences("kitchen_alarms", Context.MODE_PRIVATE).getBoolean(id.toString(), false)) return
        val title = intent.getStringExtra("title") ?: "厨房计时"
        val body = intent.getStringExtra("body") ?: "请检查锅内状态"
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= 26) {
            manager.createNotificationChannel(NotificationChannel("kitchen_timers", "做菜计时与看锅提醒", NotificationManager.IMPORTANCE_HIGH).apply {
                description = "计时结束和定时查看水量、火力"; enableVibration(true)
            })
        }
        val launch = PendingIntent.getActivity(context, id, Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, "kitchen_timers") else Notification.Builder(context)
        val notification = builder.setSmallIcon(R.drawable.ic_notification).setContentTitle(title)
            .setContentText(body).setStyle(Notification.BigTextStyle().bigText(body))
            .setContentIntent(launch).setAutoCancel(true).setCategory(Notification.CATEGORY_ALARM)
            .setPriority(Notification.PRIORITY_HIGH).setDefaults(Notification.DEFAULT_ALL).build()
        try { manager.notify(id, notification) } catch (_: SecurityException) { }
        val interval = intent.getLongExtra("interval", 0L)
        val until = intent.getLongExtra("until", 0L)
        val next = System.currentTimeMillis() + interval
        if (interval > 0 && next < until) schedule(context, id, next, title, body, interval, until)
    }
    companion object {
        private fun pending(context: Context, id: Int, intent: Intent) = PendingIntent.getBroadcast(context, id, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        fun schedule(context: Context, id: Int, at: Long, title: String, body: String, interval: Long, until: Long) {
            val intent = Intent(context, KitchenAlarmReceiver::class.java).putExtra("id", id)
                .putExtra("title", title).putExtra("body", body).putExtra("interval", interval).putExtra("until", until)
            context.getSharedPreferences("kitchen_alarms", Context.MODE_PRIVATE).edit().putBoolean(id.toString(), true).apply()
            val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val operation = pending(context, id, intent)
            try {
                if (Build.VERSION.SDK_INT < 31 || manager.canScheduleExactAlarms()) manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, operation)
                else manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, operation)
            } catch (_: SecurityException) { manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, operation) }
        }
        fun cancel(context: Context, id: Int) {
            context.getSharedPreferences("kitchen_alarms", Context.MODE_PRIVATE).edit().putBoolean(id.toString(), false).apply()
            (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(pending(context, id, Intent(context, KitchenAlarmReceiver::class.java)))
            (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).cancel(id)
        }
    }
}
