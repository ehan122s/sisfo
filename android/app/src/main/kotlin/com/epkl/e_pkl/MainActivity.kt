package com.epkl.e_pkl

import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "anti_fake_gps"

    // Daftar paket aplikasi fake GPS yang umum
    private val knownFakeGpsPackages = listOf(
        "com.lexa.fakegps",
        "com.incorporateapps.fakegps.fre",
        "com.blogspot.newapphorizons.fakegps",
        "com.theappninjas.fakegpsgo",
        "com.gpsemulator",
        "com.fakegps.mocklocation",
        "com.fakegps.fakegps",
        "com.fake.location",
        "io.appfly.fakegps",
        "com.fakegps.go",
        "com.rosteam.fakegps",
        "com.lkr.fakegps",
        "ru.gavrikov.mockgeofix",
        "com.github.warren_bank.mock_location",
        "com.fakegps.trick",
        "com.change.location.fake.gps",
        "fakegps.fakelocation.gpschanger",
        "com.fake.gps.location.spoofer",
        "com.fakegps.location.change",
        "com.mock.location.fake.gps.go",
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isDeveloperOptionsEnabled" -> {
                        result.success(isDeveloperOptionsEnabled())
                    }
                    "getMockLocationApp" -> {
                        result.success(getMockLocationApp())
                    }
                    "getInstalledFakeGpsApps" -> {
                        result.success(getInstalledFakeGpsApps())
                    }
                    "isVpnActive" -> {
                        result.success(isVpnActive())
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /// Cek apakah Developer Options aktif
    private fun isDeveloperOptionsEnabled(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
                Settings.Global.getInt(
                    contentResolver,
                    Settings.Global.DEVELOPMENT_SETTINGS_ENABLED,
                    0
                ) == 1
            } else {
                @Suppress("DEPRECATION")
                Settings.Secure.getInt(
                    contentResolver,
                    Settings.Secure.DEVELOPMENT_SETTINGS_ENABLED,
                    0
                ) == 1
            }
        } catch (e: Exception) {
            false
        }
    }

    /// Cek aplikasi yang dipilih sebagai mock location provider (Android < 12)
    private fun getMockLocationApp(): String? {
        return try {
            // Android 12+ tidak lagi memiliki single mock location app
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
                val mockApp = Settings.Secure.getString(
                    contentResolver,
                    "mock_location"
                )
                mockApp
            } else {
                // Pada Android 12+, cek melalui app ops
                null
            }
        } catch (e: Exception) {
            null
        }
    }

    /// Cek aplikasi fake GPS yang terinstal
    private fun getInstalledFakeGpsApps(): List<String> {
        val installed = mutableListOf<String>()
        val pm = packageManager

        for (pkg in knownFakeGpsPackages) {
            try {
                pm.getPackageInfo(pkg, 0)
                installed.add(pkg)
            } catch (e: PackageManager.NameNotFoundException) {
                // Aplikasi tidak terinstal
            }
        }

        return installed
    }

    /// Cek apakah VPN aktif
    private fun isVpnActive(): Boolean {
        return try {
            // Cek melalui network interfaces
            val networkInterfaces = java.net.NetworkInterface.getNetworkInterfaces()
            while (networkInterfaces.hasMoreElements()) {
                val ni = networkInterfaces.nextElement()
                val name = ni.name
                // Interface tun0, ppp0, tap0 biasanya digunakan VPN
                if (name == "tun0" || name == "ppp0" || name == "tap0") {
                    return true
                }
            }
            false
        } catch (e: Exception) {
            false
        }
    }
}