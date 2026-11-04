package com.musicare.app

import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.content.FileProvider
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest

class MainActivity : AudioServiceActivity() {
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler(::handleUpdateCall)
    }

    // Channel id and method names must match AppUpdateChannel on the Dart side.
    private fun handleUpdateCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "updatesDir" -> result.success(updatesDir().absolutePath)
            "signature" -> {
                val signature = try {
                    installedSignature()
                } catch (error: Exception) {
                    result.error("signature_failed", error.message, null)
                    return
                }
                if (signature == null) {
                    result.error("signature_failed", "No signing certificate found", null)
                } else {
                    result.success(signature)
                }
            }
            "apkInfo" -> readApkInfo(call.argument<String>("path"), result)
            "install" -> installApk(call.argument<String>("path"), result)
            else -> result.notImplemented()
        }
    }

    private fun updatesDir(): File {
        val directory = File(filesDir, "updates")
        directory.mkdirs()
        directory.listFiles()?.forEach { file ->
            // Complete APKs stay so a verified download can be reused; only
            // leftovers that cannot be installed are removed.
            if (file.isFile && !file.name.endsWith(".apk")) {
                file.delete()
            }
        }
        return directory
    }

    private fun installedSignature(): String? =
        packageCertSha256(
            packageManager.getPackageInfo(packageName, signatureFlags()),
        )

    private fun signatureFlags(): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            PackageManager.GET_SIGNING_CERTIFICATES
        } else {
            @Suppress("DEPRECATION")
            PackageManager.GET_SIGNATURES
        }

    private fun packageCertSha256(info: PackageInfo): String? {
        val certificate = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            info.signingInfo?.apkContentsSigners?.firstOrNull()
        } else {
            @Suppress("DEPRECATION")
            info.signatures?.firstOrNull()
        } ?: return null
        return MessageDigest.getInstance("SHA-256")
            .digest(certificate.toByteArray())
            .joinToString("") { "%02x".format(it) }
    }

    private fun readApkInfo(path: String?, result: MethodChannel.Result) {
        if (path == null) {
            result.error("invalid_argument", "path is required", null)
            return
        }
        Thread {
            try {
                val archive = packageManager.getPackageArchiveInfo(path, signatureFlags())
                val certificate = archive?.let { packageCertSha256(it) }
                if (archive == null || certificate == null) {
                    postError(result, "invalid_apk", "Cannot read the package signature")
                    return@Thread
                }
                val versionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    archive.longVersionCode.toInt()
                } else {
                    @Suppress("DEPRECATION")
                    archive.versionCode
                }
                val info = mapOf(
                    "packageName" to archive.packageName,
                    "versionCode" to versionCode,
                    "certSha256" to certificate,
                )
                mainHandler.post { result.success(info) }
            } catch (error: Exception) {
                postError(result, "invalid_apk", error.message)
            }
        }.start()
    }

    private fun installApk(path: String?, result: MethodChannel.Result) {
        if (path == null) {
            result.error("invalid_argument", "path is required", null)
            return
        }
        val file = File(path)
        if (!file.exists()) {
            result.error("missing_apk", "The package file does not exist", null)
            return
        }
        try {
            val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            result.success(null)
        } catch (error: Exception) {
            result.error("install_failed", error.message, null)
        }
    }

    private fun postError(result: MethodChannel.Result, code: String, message: String?) {
        mainHandler.post { result.error(code, message, null) }
    }

    companion object {
        private const val CHANNEL = "com.musicare.app_update"
    }
}
