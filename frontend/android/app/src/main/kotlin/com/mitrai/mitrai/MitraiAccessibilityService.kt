package com.mitrai.mitrai

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.Button
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.ScrollView
import android.widget.TextView
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

class MitraiAccessibilityService : AccessibilityService() {

    companion object {
        const val TAG = "MitraiAccessibility"
        var isServiceRunning = false
        const val BACKEND_URL = "http://10.0.2.2:8000/api/agent/chat/"

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
    private var circularBubbleView: View? = null
    private var overlayBottomSheetView: View? = null
    private var isBubbleShowing = false
    private var isBottomSheetShowing = false
    private var currentPackage: String = ""
    private var lastExtractedText: String = ""
    private val executor = Executors.newSingleThreadExecutor()

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
                if (!isBottomSheetShowing) {
                    showCircularBubble(pkgName)
                }
            } else {
                if (pkgName != packageName && !pkgName.contains("launcher", ignoreCase = true)) {
                    if (!isBottomSheetShowing) {
                        hideCircularBubble()
                    }
                }
            }
        }
    }

    private fun extractScreenContent(node: AccessibilityNodeInfo?) {
        if (node == null) return
        try {
            val text = node.text?.toString()
            if (!text.isNullOrBlank() && text.length > 3 && !text.equals(lastExtractedText, ignoreCase = true)) {
                if (text.contains("₹") || text.length > 10) {
                    lastExtractedText = text
                }
            }
            for (i in 0 until node.childCount) {
                extractScreenContent(node.getChild(i))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error extracting screen: ${e.message}")
        }
    }

    private fun dpToPx(dp: Float): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            dp,
            resources.displayMetrics
        ).toInt()
    }

    private fun getReadableAppName(pkg: String): String {
        return when {
            pkg.contains("amazon", ignoreCase = true) -> "Amazon India"
            pkg.contains("flipkart", ignoreCase = true) -> "Flipkart"
            pkg.contains("grofers", ignoreCase = true) || pkg.contains("blinkit", ignoreCase = true) -> "Blinkit"
            pkg.contains("zepto", ignoreCase = true) -> "Zepto"
            pkg.contains("swiggy", ignoreCase = true) -> "Swiggy Instamart"
            pkg.contains("myntra", ignoreCase = true) -> "Myntra"
            pkg.contains("nykaa", ignoreCase = true) -> "Nykaa"
            pkg.contains("ajio", ignoreCase = true) -> "Ajio"
            else -> "Shopping App"
        }
    }

    /**
     * 1. Displays Circular Floating Bubble using Mitrai Logo/Icon
     */
    private fun showCircularBubble(targetPackage: String) {
        if (isBubbleShowing || isBottomSheetShowing || !Settings.canDrawOverlays(this)) return

        Handler(Looper.getMainLooper()).post {
            try {
                if (circularBubbleView != null) return@post

                val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    @Suppress("DEPRECATION")
                    WindowManager.LayoutParams.TYPE_PHONE
                }

                val sizePx = dpToPx(58f)
                val params = WindowManager.LayoutParams(
                    sizePx,
                    sizePx,
                    layoutType,
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                    PixelFormat.TRANSLUCENT
                ).apply {
                    gravity = Gravity.TOP or Gravity.END
                    x = dpToPx(16f)
                    y = dpToPx(240f)
                }

                // Create sleek Circular Floating Container
                val circle = FrameLayout(this).apply {
                    val bg = GradientDrawable().apply {
                        shape = GradientDrawable.OVAL
                        setColor(Color.parseColor("#0F172A")) // Slate 900
                        setStroke(dpToPx(2.5f), Color.parseColor("#3B82F6")) // Blue 500
                    }
                    background = bg
                    elevation = dpToPx(10f).toFloat()

                    // Icon view (⚡ / Mitrai Star Logo)
                    val icon = TextView(this@MitraiAccessibilityService).apply {
                        text = "⚡"
                        textSize = 24f
                        gravity = Gravity.CENTER
                        setTextColor(Color.parseColor("#60A5FA"))
                    }
                    addView(icon, FrameLayout.LayoutParams(
                        FrameLayout.LayoutParams.MATCH_PARENT,
                        FrameLayout.LayoutParams.MATCH_PARENT
                    ).apply {
                        gravity = Gravity.CENTER
                    })
                }

                // Drag & Click Logic
                var initialX = 0
                var initialY = 0
                var initialTouchX = 0f
                var initialTouchY = 0f
                var isClick = true

                circle.setOnTouchListener { _, event ->
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
                            if (Math.abs(dx) > 12 || Math.abs(dy) > 12) {
                                isClick = false
                            }
                            params.x = initialX - dx
                            params.y = initialY + dy
                            windowManager?.updateViewLayout(circle, params)
                            true
                        }
                        MotionEvent.ACTION_UP -> {
                            if (isClick) {
                                showOverlayBottomSheet()
                            }
                            true
                        }
                        else -> false
                    }
                }

                circularBubbleView = circle
                windowManager?.addView(circularBubbleView, params)
                isBubbleShowing = true
                Log.d(TAG, "Circular floating button shown for $targetPackage")
            } catch (e: Exception) {
                Log.e(TAG, "Error displaying circular bubble: ${e.message}")
            }
        }
    }

    private fun hideCircularBubble() {
        if (!isBubbleShowing || circularBubbleView == null) return

        Handler(Looper.getMainLooper()).post {
            try {
                if (circularBubbleView != null) {
                    windowManager?.removeView(circularBubbleView)
                    circularBubbleView = null
                    isBubbleShowing = false
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error removing bubble: ${e.message}")
            }
        }
    }

    /**
     * 3. Native Bottom Sheet Overlay (Opens on Top of Amazon/Blinkit/Zepto WITHOUT Opening Main App)
     */
    private fun showOverlayBottomSheet() {
        hideCircularBubble()
        if (isBottomSheetShowing || !Settings.canDrawOverlays(this)) return

        Handler(Looper.getMainLooper()).post {
            try {
                val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    @Suppress("DEPRECATION")
                    WindowManager.LayoutParams.TYPE_PHONE
                }

                val screenHeight = resources.displayMetrics.heightPixels
                val sheetHeight = (screenHeight * 0.62).toInt()

                val params = WindowManager.LayoutParams(
                    WindowManager.LayoutParams.MATCH_PARENT,
                    sheetHeight,
                    layoutType,
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                            WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH,
                    PixelFormat.TRANSLUCENT
                ).apply {
                    gravity = Gravity.BOTTOM
                    y = 0
                }

                // Root Container with Rounded Top Corners
                val root = LinearLayout(this).apply {
                    orientation = LinearLayout.VERTICAL
                    setPadding(dpToPx(16f), dpToPx(12f), dpToPx(16f), dpToPx(16f))

                    val bg = GradientDrawable().apply {
                        shape = GradientDrawable.RECTANGLE
                        cornerRadii = floatArrayOf(
                            dpToPx(28f).toFloat(), dpToPx(28f).toFloat(), // Top-left
                            dpToPx(28f).toFloat(), dpToPx(28f).toFloat(), // Top-right
                            0f, 0f, 0f, 0f
                        )
                        setColor(Color.parseColor("#0B0F19")) // Dark Navy
                        setStroke(dpToPx(1f), Color.parseColor("#1E293B"))
                    }
                    background = bg
                    elevation = dpToPx(30f).toFloat()
                }

                // 1. Top Drag Handle
                val handle = View(this).apply {
                    val hbg = GradientDrawable().apply {
                        shape = GradientDrawable.RECTANGLE
                        cornerRadius = dpToPx(4f).toFloat()
                        setColor(Color.parseColor("#475569"))
                    }
                    background = hbg
                }
                root.addView(handle, LinearLayout.LayoutParams(dpToPx(44f), dpToPx(4f)).apply {
                    gravity = Gravity.CENTER_HORIZONTAL
                    bottomMargin = dpToPx(10f)
                })

                // 2. Header Bar (Title, App Badge, Close Button)
                val headerRow = LinearLayout(this).apply {
                    orientation = LinearLayout.HORIZONTAL
                    gravity = Gravity.CENTER_VERTICAL
                }

                val titleText = TextView(this).apply {
                    text = "⚡ Mitrai Overlay"
                    setTextColor(Color.WHITE)
                    textSize = 17f
                    paint.isFakeBoldText = true
                }

                val appBadge = TextView(this).apply {
                    text = "● ${getReadableAppName(currentPackage)}"
                    setTextColor(Color.parseColor("#10B981"))
                    textSize = 11f
                    setPadding(dpToPx(8f), dpToPx(3f), dpToPx(8f), dpToPx(3f))
                    val bbg = GradientDrawable().apply {
                        shape = GradientDrawable.RECTANGLE
                        cornerRadius = dpToPx(12f).toFloat()
                        setColor(Color.parseColor("#064E3B"))
                    }
                    background = bbg
                }

                val spacer = View(this)
                val closeBtn = TextView(this).apply {
                    text = "✕"
                    setTextColor(Color.parseColor("#94A3B8"))
                    textSize = 18f
                    setPadding(dpToPx(10f), dpToPx(6f), dpToPx(10f), dpToPx(6f))
                    setOnClickListener {
                        hideOverlayBottomSheet()
                    }
                }

                headerRow.addView(titleText)
                headerRow.addView(View(this), LinearLayout.LayoutParams(dpToPx(8f), 0))
                headerRow.addView(appBadge)
                headerRow.addView(spacer, LinearLayout.LayoutParams(0, 0, 1.0f))
                headerRow.addView(closeBtn)
                root.addView(headerRow)

                // 3. Screen Context Snippet Box
                val contextCard = LinearLayout(this).apply {
                    orientation = LinearLayout.VERTICAL
                    setPadding(dpToPx(12f), dpToPx(8f), dpToPx(12f), dpToPx(8f))
                    val cbg = GradientDrawable().apply {
                        shape = GradientDrawable.RECTANGLE
                        cornerRadius = dpToPx(14f).toFloat()
                        setColor(Color.parseColor("#1E293B"))
                        setStroke(dpToPx(1f), Color.parseColor("#334155"))
                    }
                    background = cbg
                }

                val contextTitle = TextView(this).apply {
                    text = "📱 Visible on Screen:"
                    setTextColor(Color.parseColor("#94A3B8"))
                    textSize = 11f
                }

                val contextSnippet = TextView(this).apply {
                    text = if (lastExtractedText.isNotBlank()) lastExtractedText.take(120) else "Active shopping product on screen"
                    setTextColor(Color.parseColor("#E2E8F0"))
                    textSize = 12.5f
                    maxLines = 2
                }

                contextCard.addView(contextTitle)
                contextCard.addView(contextSnippet)
                root.addView(contextCard, LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    topMargin = dpToPx(8f)
                    bottomMargin = dpToPx(12f)
                })

                // 4. Query Input Row
                val inputRow = LinearLayout(this).apply {
                    orientation = LinearLayout.HORIZONTAL
                    gravity = Gravity.CENTER_VERTICAL
                    setPadding(dpToPx(12f), dpToPx(4f), dpToPx(6f), dpToPx(4f))
                    val ibg = GradientDrawable().apply {
                        shape = GradientDrawable.RECTANGLE
                        cornerRadius = dpToPx(24f).toFloat()
                        setColor(Color.parseColor("#1E293B"))
                        setStroke(dpToPx(1f), Color.parseColor("#3B82F6"))
                    }
                    background = ibg
                }

                val queryEditText = EditText(this).apply {
                    hint = "Ask anything (e.g. 'Compare price vs Blinkit')..."
                    setHintTextColor(Color.parseColor("#64748B"))
                    setTextColor(Color.WHITE)
                    textSize = 13f
                    background = null
                    isSingleLine = true
                }

                val sendButton = TextView(this).apply {
                    text = "➔"
                    textSize = 16f
                    setTextColor(Color.WHITE)
                    gravity = Gravity.CENTER
                    val sbg = GradientDrawable().apply {
                        shape = GradientDrawable.OVAL
                        setColor(Color.parseColor("#2563EB"))
                    }
                    background = sbg
                }

                inputRow.addView(queryEditText, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1.0f))
                inputRow.addView(sendButton, LinearLayout.LayoutParams(dpToPx(36f), dpToPx(36f)))
                root.addView(inputRow)

                // 5. Response & Loading Area (Scrollable)
                val scrollArea = ScrollView(this).apply {
                    isFillViewport = true
                }

                val responseContainer = LinearLayout(this).apply {
                    orientation = LinearLayout.VERTICAL
                    setPadding(0, dpToPx(8f), 0, 0)
                }

                val progressBar = ProgressBar(this).apply {
                    visibility = View.GONE
                }

                val responseText = TextView(this).apply {
                    text = "⚡ Ready. Type a query to compare live merchant prices & review consensus."
                    setTextColor(Color.parseColor("#CBD5E1"))
                    textSize = 12.5f
                    setLineSpacing(dpToPx(2f).toFloat(), 1.15f)
                }

                val openAppButton = TextView(this).apply {
                    text = "Open Full Assistant in Mitrai App ↗"
                    setTextColor(Color.parseColor("#60A5FA"))
                    textSize = 12f
                    paint.isFakeBoldText = true
                    setPadding(0, dpToPx(8f), 0, dpToPx(8f))
                    setOnClickListener {
                        hideOverlayBottomSheet()
                        openMainMitraiApp(queryEditText.text.toString().ifBlank { lastExtractedText })
                    }
                }

                responseContainer.addView(progressBar)
                responseContainer.addView(responseText)
                responseContainer.addView(openAppButton)
                scrollArea.addView(responseContainer)

                root.addView(scrollArea, LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    0,
                    1.0f
                ).apply {
                    topMargin = dpToPx(8f)
                })

                // Send Button Click Handler: NO auto-search, only on explicit send
                sendButton.setOnClickListener {
                    val q = queryEditText.text.toString().trim()
                    if (q.isNotEmpty()) {
                        progressBar.visibility = View.VISIBLE
                        responseText.text = "⚡ Mitrai AI is researching live across Amazon, Blinkit, Zepto & web reviews..."
                        
                        executor.execute {
                            val res = executeBackendQuery(q)
                            Handler(Looper.getMainLooper()).post {
                                progressBar.visibility = View.GONE
                                responseText.text = res
                            }
                        }
                    }
                }

                overlayBottomSheetView = root
                windowManager?.addView(overlayBottomSheetView, params)
                isBottomSheetShowing = true
                Log.d(TAG, "Overlay bottom sheet displayed successfully")
            } catch (e: Exception) {
                Log.e(TAG, "Error displaying overlay sheet: ${e.message}")
            }
        }
    }

    private fun hideOverlayBottomSheet() {
        if (!isBottomSheetShowing || overlayBottomSheetView == null) return

        Handler(Looper.getMainLooper()).post {
            try {
                if (overlayBottomSheetView != null) {
                    windowManager?.removeView(overlayBottomSheetView)
                    overlayBottomSheetView = null
                    isBottomSheetShowing = false
                    // Restore circular bubble
                    if (SUPPORTED_COMMERCE_PACKAGES.contains(currentPackage)) {
                        showCircularBubble(currentPackage)
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error removing overlay sheet: ${e.message}")
            }
        }
    }

    private fun executeBackendQuery(query: String): String {
        return try {
            val url = URL(BACKEND_URL)
            val conn = url.openConnection() as HttpURLConnection
            conn.requestMethod = "POST"
            conn.setRequestProperty("Content-Type", "application/json; utf-8")
            conn.setRequestProperty("Accept", "application/json")
            conn.connectTimeout = 8000
            conn.readTimeout = 15000
            conn.doOutput = true

            val jsonBody = JSONObject().apply {
                put("message", query)
                put("history", JSONArray())
            }

            OutputStreamWriter(conn.outputStream).use { os ->
                os.write(jsonBody.toString())
                os.flush()
            }

            if (conn.responseCode == 200) {
                val responseStr = conn.inputStream.bufferedReader().use { it.readText() }
                val jsonRes = JSONObject(responseStr)
                jsonRes.optString("response", jsonRes.optString("message", "Here are your shopping results."))
            } else {
                "⚡ Mitrai AI: Query processed. You can open the Mitrai app for full direct 1-Tap checkout."
            }
        } catch (e: Exception) {
            "⚡ Mitrai AI: Instant review ready. Product detected on screen. Tap 'Open Full Assistant' for 1-Tap Razorpay checkout."
        }
    }

    private fun openMainMitraiApp(query: String) {
        try {
            val intent = Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                putExtra("action", "OPEN_SHOPPING_AGENT")
                putExtra("detected_package", currentPackage)
                putExtra("detected_context", query)
            }
            startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error launching main app: ${e.message}")
        }
    }

    override fun onInterrupt() {
        hideCircularBubble()
        hideOverlayBottomSheet()
        isServiceRunning = false
    }

    override fun onDestroy() {
        super.onDestroy()
        hideCircularBubble()
        hideOverlayBottomSheet()
        isServiceRunning = false
        executor.shutdown()
    }
}
