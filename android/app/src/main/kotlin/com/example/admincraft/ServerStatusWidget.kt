package com.joanroig.admincraft

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import java.text.DateFormat
import java.util.Date

class ServerStatusWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { update(context, manager, it) }
    }

    companion object {
        const val PREFERENCES = "admincraft_server_widget"

        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, ServerStatusWidget::class.java)
            manager.getAppWidgetIds(component).forEach { update(context, manager, it) }
        }

        private fun update(context: Context, manager: AppWidgetManager, id: Int) {
            val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            val alias = preferences.getString("alias", "Admincraft") ?: "Admincraft"
            val players = preferences.getInt("players", -1)
            val limit = preferences.getInt("limit", -1)
            val updatedAt = preferences.getLong("updatedAt", 0)
            val count = when {
                players < 0 -> "—"
                limit < 0 -> players.toString()
                else -> "$players / $limit"
            }
            val updated = if (updatedAt == 0L) {
                context.getString(R.string.widget_open_to_refresh)
            } else {
                context.getString(
                    R.string.widget_updated,
                    DateFormat.getTimeInstance(DateFormat.SHORT).format(Date(updatedAt))
                )
            }
            val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
                ?: Intent(context, MainActivity::class.java)
            val pending = PendingIntent.getActivity(
                context, 0, launch,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val views = RemoteViews(context.packageName, R.layout.server_status_widget)
            views.setTextViewText(R.id.widget_server_alias, alias)
            views.setTextViewText(R.id.widget_player_count, count)
            views.setTextViewText(R.id.widget_updated, updated)
            views.setOnClickPendingIntent(R.id.widget_root, pending)
            manager.updateAppWidget(id, views)
        }
    }
}
