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

    // Get all installed apps
    fun getInstalledApps(): List<Map<String, Any>> {
        val packageManager = context.packageManager
        val apps = mutableListOf<Map<String, Any>>()

        val packages = packageManager.getInstalledApplications(PackageManager.GET_META_DATA)

        for (packageInfo in packages) {
            // Skip our own app
            if (packageInfo.packageName == context.packageName) continue

            val appName = packageManager.getApplicationLabel(packageInfo).toString()
            val packageName = packageInfo.packageName
            val isSystemApp = (packageInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0

            // Get app icon as byte array
            val icon = try {
                val drawable = packageManager.getApplicationIcon(packageInfo)
                drawableToByteArray(drawable)
            } catch (e: Exception) {
                null
            }

            val appMap: Map<String, Any> = mapOf(
                "packageName" to packageName,
                "appName" to appName,
                "isSystemApp" to isSystemApp,
                "icon" to (icon ?: byteArrayOf())
            )

            apps.add(appMap)
        }

        // Sort by app name
        return apps.sortedBy { it["appName"] as String }
    }

    // Convert Drawable to ByteArray
    private fun drawableToByteArray(drawable: Drawable): ByteArray? {
        val bitmap = if (drawable is BitmapDrawable) {
            drawable.bitmap
        } else {
            // Create bitmap from drawable
            val bitmap = Bitmap.createBitmap(
                drawable.intrinsicWidth,
                drawable.intrinsicHeight,
                Bitmap.Config.ARGB_8888
            )
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
            bitmap
        }

        // Compress bitmap to reduce size
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
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
}
