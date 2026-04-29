package com.example.presensi_mobile

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.database.Cursor
import android.location.Location
import android.location.LocationManager
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "presensi/device"
    private val pickDocumentRequest = 4100
    private var pendingPickResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "deviceInfo" -> result.success(deviceInfo())
                "getLocation" -> currentLocation(result)
                "saveValue" -> {
                    val key = call.argument<String>("key") ?: return@setMethodCallHandler result.error("invalid_key", "Key kosong", null)
                    val value = call.argument<String>("value")
                    preferences().edit().putString(key, value).apply()
                    result.success(true)
                }
                "readValue" -> {
                    val key = call.argument<String>("key") ?: return@setMethodCallHandler result.error("invalid_key", "Key kosong", null)
                    result.success(preferences().getString(key, null))
                }
                "clearValue" -> {
                    val key = call.argument<String>("key") ?: return@setMethodCallHandler result.error("invalid_key", "Key kosong", null)
                    preferences().edit().remove(key).apply()
                    result.success(true)
                }
                "pickDocument" -> pickDocument(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun preferences() = getSharedPreferences("presensi_mobile", Context.MODE_PRIVATE)

    private fun deviceInfo(): Map<String, Any?> {
        val androidId = Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID) ?: "unknown"
        return mapOf(
            "device_id" to androidId,
            "device_name" to "${Build.MANUFACTURER} ${Build.MODEL}",
            "platform" to "android"
        )
    }

    @SuppressLint("MissingPermission")
    private fun currentLocation(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED &&
            checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION), 7001)
            result.error("permission_denied", "Izin lokasi belum diberikan", null)
            return
        }

        val manager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val providers = listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)
        val location = providers.mapNotNull { provider ->
            runCatching { manager.getLastKnownLocation(provider) }.getOrNull()
        }.maxByOrNull { it.time }

        if (location == null) {
            result.error("location_unavailable", "Lokasi belum tersedia. Aktifkan GPS lalu coba lagi.", null)
            return
        }

        result.success(locationMap(location))
    }

    private fun locationMap(location: Location): Map<String, Any?> {
        @Suppress("DEPRECATION")
        val mocked = location.isFromMockProvider
        return mapOf(
            "latitude" to location.latitude,
            "longitude" to location.longitude,
            "accuracy" to location.accuracy.toInt(),
            "mocked_location" to mocked,
            "timestamp" to location.time
        )
    }

    private fun pickDocument(result: MethodChannel.Result) {
        if (pendingPickResult != null) {
            result.error("busy", "Pemilihan dokumen masih berjalan", null)
            return
        }

        pendingPickResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
        }
        startActivityForResult(intent, pickDocumentRequest)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != pickDocumentRequest) return

        val result = pendingPickResult
        pendingPickResult = null

        val uri = data?.data
        if (resultCode != RESULT_OK || uri == null) {
            result?.success(null)
            return
        }

        try {
            contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        } catch (_: SecurityException) {
        }

        val bytes = contentResolver.openInputStream(uri)?.use { it.readBytes() }
        if (bytes == null) {
            result?.error("read_failed", "Dokumen tidak bisa dibaca", null)
            return
        }

        result?.success(mapOf(
            "name" to displayName(uri),
            "mime_type" to contentResolver.getType(uri),
            "size" to bytes.size,
            "bytes" to bytes
        ))
    }

    private fun displayName(uri: Uri): String {
        var name = "dokumen"
        val cursor: Cursor? = contentResolver.query(uri, null, null, null, null)
        cursor?.use {
            val index = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (index >= 0 && it.moveToFirst()) {
                name = it.getString(index)
            }
        }
        return name
    }
}
