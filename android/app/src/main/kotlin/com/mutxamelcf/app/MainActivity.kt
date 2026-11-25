package com.mutxamelcf.app

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.mutxamelcf.app/ajustes")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "abrirAjustesNotificaciones" -> {
                        val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                            .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                        abrir(intent, result)
                    }
                    "abrirAjustesApp" -> {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                            .setData(Uri.fromParts("package", packageName, null))
                        abrir(intent, result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun abrir(intent: Intent, result: MethodChannel.Result) {
        try {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            result.success(null)
        } catch (e: Exception) {
            result.error("ajustes", e.message, null)
        }
    }
}
