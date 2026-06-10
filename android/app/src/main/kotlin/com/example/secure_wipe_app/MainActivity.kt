package com.example.secure_wipe_app

import android.os.Process
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.secure_wipe_app/security"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {

                // ── Detección de USB Debugging ────────────────────────────
                // Consulta Settings.Global.ADB_ENABLED directamente desde
                // la API nativa de Android. Es la fuente más confiable.
                "isUsbDebuggingEnabled" -> {
                    val adbEnabled = Settings.Global.getInt(
                        contentResolver,
                        Settings.Global.ADB_ENABLED,
                        0  // valor por defecto: 0 = desactivado
                    )
                    result.success(adbEnabled == 1)
                }

                // ── FLAG_SECURE (captura de pantalla) ─────────────────────
                "enableSecureFlag" -> {
                    window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success("FLAG_SECURE activado")
                }

                "disableSecureFlag" -> {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success("FLAG_SECURE desactivado")
                }

                // ── Cierre limpio de la app ───────────────────────────────
                "exitApp" -> {
                    result.success(null)
                    finishAffinity()
                    android.os.Process.killProcess(android.os.Process.myPid())
                }

                else -> result.notImplemented()
            }
        }
    }
}
