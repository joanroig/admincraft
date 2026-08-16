package com.joanroig.admincraft

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "admincraft/server-widget"
        ).setMethodCallHandler { call, result ->
            if (call.method != "update") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val preferences = getSharedPreferences(
                ServerStatusWidget.PREFERENCES,
                Context.MODE_PRIVATE
            )
            preferences.edit()
                .putString("alias", call.argument<String>("alias") ?: "Server")
                .putInt("players", call.argument<Int>("players") ?: -1)
                .putInt("limit", call.argument<Int>("limit") ?: -1)
                .putLong("updatedAt", System.currentTimeMillis())
                .apply()
            ServerStatusWidget.updateAll(this)
            result.success(null)
        }
    }
}
