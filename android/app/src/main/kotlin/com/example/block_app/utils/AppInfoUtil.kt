package com.example.block_app.utils

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import java.io.ByteArrayOutputStream

class AppInfoUtil(private val context: Context) {
    
    companion object {
        private val iconCache = mutableMapOf<String, ByteArray>()
        private var appsCache: List<Map<String, Any>>? = null
        private var lastAppsCacheTime = 0L
        private const val CACHE_DURATION = 300000L // 5 minutes
    }

    // Get all installed apps
    fun getInstalledApps(includeIcons: Boolean = true): List<Map<String, Any>> {
        val currentTime = System.currentTimeMillis()
        if (appsCache != null && (currentTime - lastAppsCacheTime) < CACHE_DURATION) {
            return appsCache!!
        }

        val packageManager = context.packageManager
        val apps = mutableListOf<Map<String, Any>>()

        // Use GET_META_DATA only if needed
        val packages = packageManager.getInstalledApplications(PackageManager.GET_META_DATA)

        for (packageInfo in packages) {
            // Skip our own app
            if (packageInfo.packageName == context.packageName) continue

            // Only include launchable apps to reduce count and noise
            if (packageManager.getLaunchIntentForPackage(packageInfo.packageName) == null) continue

            val appName = packageManager.getApplicationLabel(packageInfo).toString()
            val packageName = packageInfo.packageName
            val isSystemApp = (packageInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0

            // Get app icon (with caching)
            var icon: ByteArray? = null
            if (includeIcons) {
                icon = iconCache[packageName]
                if (icon == null) {
                    icon = try {
                        val drawable = packageManager.getApplicationIcon(packageInfo)
                        drawableToByteArray(drawable)
                    } catch (e: Exception) {
                        null
                    }
                    if (icon != null) {
                        iconCache[packageName] = icon
                    }
                }
            }

            val appMap: Map<String, Any> = mapOf(
                "packageName" to packageName,
                "appName" to appName,
                "isSystemApp" to isSystemApp,
                "icon" to (icon ?: byteArrayOf())
            )

            apps.add(appMap)
        }

        val result = apps.sortedBy { it["appName"] as String }
        appsCache = result
        lastAppsCacheTime = currentTime
        return result
    }

    // Convert Drawable to ByteArray with optimization
    private fun drawableToByteArray(drawable: Drawable): ByteArray? {
        val bitmap = if (drawable is BitmapDrawable) {
            drawable.bitmap
        } else {
            // Use fixed smaller size for icons to save memory and processing time
            val width = if (drawable.intrinsicWidth > 0) Math.min(drawable.intrinsicWidth, 128) else 128
            val height = if (drawable.intrinsicHeight > 0) Math.min(drawable.intrinsicHeight, 128) else 128
            
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
            bitmap
        }

        val stream = ByteArrayOutputStream()
        // Compression quality 80 is enough for app icons
        bitmap.compress(Bitmap.CompressFormat.PNG, 80, stream)
        return stream.toByteArray()
    }

    // Get app name from package name
    fun getAppName(packageName: String): String {
        return try {
            val packageManager = context.packageManager
            val appInfo = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(appInfo).toString()
        } catch (e: PackageManager.NameNotFoundException) {
            packageName
        }
    }

    // Get app icon from package name
    fun getAppIcon(packageName: String): Drawable? {
        return try {
            val packageManager = context.packageManager
            packageManager.getApplicationIcon(packageName)
        } catch (e: PackageManager.NameNotFoundException) {
            null
        }
    }
}
