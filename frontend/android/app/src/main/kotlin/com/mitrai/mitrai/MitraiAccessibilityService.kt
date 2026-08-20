package com.mitrai.mitrai

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.LinearLayout
import android.widget.TextView

class MitraiAccessibilityService : AccessibilityService() {

    companion object {
        const val TAG = "MitraiAccessibility"
        var isServiceRunning = false

        val SUPPORTED_COMMERCE_PACKAGES = setOf(
            "in.amazon.mShop.android.shopping", // Amazon India
            "com.amazon.mShop.android.shopping",
            "com.flipkart.android",             // Flipkart
            "com.grofers.customerapp",          // Blinkit
            "com.zeptocookbook.android",        // Zepto
            "in.swiggy.android",                // Swiggy & Instamart
            "com.application.zomato",           // Zomato
            "com.myntra.android",               // Myntra
            "com.fsn.nykaa",                    // Nykaa
            "com.tatadigital.tcp",              // Tata Neu
            "com.meesho.supply",                // Meesho
            "com.bigbasket.mobileapp",          // BigBasket
            "com.ril.ajio"                      // Ajio
        )
    }

    private var windowManager: WindowManager? = null
    private var floatingView: View? = null
    private var isOverlayShowing = false
    private var currentPackage: String = ""
    private var lastExtractedText: String = ""

    override fun onServiceConnected() {
        super.onServiceConnected()
        isServiceRunning = true
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        Log.d(TAG, "Mitrai Accessibility Service Connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        val pkgName = event.packageName?.toString() ?: return

        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED ||
            event.eventType == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED) {
            
            if (SUPPORTED_COMMERCE_PACKAGES.contains(pkgName)) {
                currentPackage = pkgName
                extractScreenContent(rootInActiveWindow)
                showFloatingAssistantButton(pkgName)
            } else {
                if (pkgName != packageName && !pkgName.contains("launcher", ignoreCase = true)) {
                    hideFloatingAssistantButton()
                }
            }
        }
    }

    private fun extractScreenContent(node: AccessibilityNodeInfo?) {
        if (node == null) return
        try {
            val text = node.text?.toString()
            if (!text.isNullOrBlank() && text.length > 4 && !text.equals(lastExtractedText, ignoreCase = true)) {
                lastExtractedText = text
            }
            for (i in 0 until node.childCount) {
                extractScreenContent(node.getChild(i))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing accessibility tree: ${e.message}")
        }
    }

    private fun showFloatingAssistantButton(targetPackage: String) {
        if (isOverlayShowing || !Settings.canDrawOverlays(this)) return

        Handler(Looper.getMainLooper()).post {
            try {
                if (floatingView != null) return@post

                val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    @Suppress("DEPRECATION")
                    WindowManager.LayoutParams.TYPE_PHONE
                }

                val params = WindowManager.LayoutParams(
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    layoutType,
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                    PixelFormat.TRANSLUCENT
                ).apply {
                    gravity = Gravity.TOP or Gravity.END
                    x = 24
                    y = 360
                }

                // Create sleek floating pill container
                val pill = LinearLayout(this).apply {
                    orientation = LinearLayout.HORIZONTAL
                    gravity = Gravity.CENTER_VERTICAL
                    setPadding(32, 20, 36, 20)

                    val background = GradientDrawable().apply {
                        shape = GradientDrawable.RECTANGLE
                        cornerRadius = 50f
                        setColor(Color.parseColor("#1B1F38")) // BrikTheme.brandNavy
                        setStroke(3, Color.parseColor("#3A416F"))
                    }
                    this.background = background
                    elevation = 20f

                    val iconView = TextView(this@MitraiAccessibilityService).apply {
                        text = "⚡"
                        textSize = 15f
                        setPadding(0, 0, 12, 0)
                    }

                    val textView = TextView(this@MitraiAccessibilityService).apply {
                        text = "Mitrai AI"
                        setTextColor(Color.WHITE)
                        textSize = 13.5f
                        paint.isFakeBoldText = true
                    }

                    addView(iconView)
                    addView(textView)
                }

                // Touch & Drag handler
                var initialX = 0
                var initialY = 0
                var initialTouchX = 0f
                var initialTouchY = 0f
                var isClick = true

                pill.setOnTouchListener { _, event ->
                    when (event.action) {
                        MotionEvent.ACTION_DOWN -> {
                            initialX = params.x
                            initialY = params.y
                            initialTouchX = event.rawX
                            initialTouchY = event.rawY
                            isClick = true
                            true
                        }
                        MotionEvent.ACTION_MOVE -> {
                            val dx = (event.rawX - initialTouchX).toInt()
                            val dy = (event.rawY - initialTouchY).toInt()
                            if (Math.abs(dx) > 10 || Math.abs(dy) > 10) {
                                isClick = false
                            }
                            params.x = initialX - dx
                            params.y = initialY + dy
                            windowManager?.updateViewLayout(pill, params)
                            true
                        }
                        MotionEvent.ACTION_UP -> {
                            if (isClick) {
                                openShoppingAssistantSheet()
                            }
                            true
                        }
                        else -> false
                    }
                }

                floatingView = pill
                windowManager?.addView(floatingView, params)
                isOverlayShowing = true
                Log.d(TAG, "Floating Mitrai button displayed for $targetPackage")
            } catch (e: Exception) {
                Log.e(TAG, "Error displaying floating assistant: ${e.message}")
            }
        }
    }

    private fun openShoppingAssistantSheet() {
        try {
            // Launch main app with active e-commerce query context
            val intent = Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                putExtra("action", "OPEN_SHOPPING_AGENT")
                putExtra("detected_package", currentPackage)
                putExtra("detected_context", lastExtractedText)
            }
            startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error launching shopping assistant: ${e.message}")
        }
    }

    private fun hideFloatingAssistantButton() {
        if (!isOverlayShowing || floatingView == null) return

        Handler(Looper.getMainLooper()).post {
            try {
                if (floatingView != null) {
                    windowManager?.removeView(floatingView)
                    floatingView = null
                    isOverlayShowing = false
                    Log.d(TAG, "Floating Mitrai button hidden")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error removing floating view: ${e.message}")
            }
        }
    }

    override fun onInterrupt() {
        hideFloatingAssistantButton()
        isServiceRunning = false
        Log.d(TAG, "Mitrai Accessibility Service Interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        hideFloatingAssistantButton()
        isServiceRunning = false
    }
}
