package com.moslah.my_manager

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val channelName = "com.moslah.my_manager/downloads"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            if (call.method == "saveToDownloads") {
                val fileName = call.argument<String>("fileName")
                val bytes = call.argument<ByteArray>("bytes")
                val mimeType = call.argument<String>("mimeType")

                if (fileName == null || bytes == null) {
                    result.error("INVALID_ARGS", "fileName and bytes cannot be null", null)
                    return@setMethodCallHandler
                }

                try {
                    val savedLocation = saveFileToDownloads(fileName, bytes, mimeType ?: "application/octet-stream")
                    result.success(savedLocation)
                } catch (e: Exception) {
                    result.error("SAVE_FAILED", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun saveFileToDownloads(fileName: String, bytes: ByteArray, mimeType: String): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val contentValues = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            }

            val resolver = context.contentResolver
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
                ?: throw Exception("Could not create MediaStore entry for $fileName")

            resolver.openOutputStream(uri)?.use { outputStream ->
                outputStream.write(bytes)
                outputStream.flush()
            } ?: throw Exception("Could not open output stream for $uri")

            "Downloads/$fileName"
        } else {
            val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            if (!downloadsDir.exists()) {
                downloadsDir.mkdirs()
            }
            val targetFile = File(downloadsDir, fileName)
            FileOutputStream(targetFile).use { outputStream ->
                outputStream.write(bytes)
                outputStream.flush()
            }
            targetFile.absolutePath
        }
    }
}
