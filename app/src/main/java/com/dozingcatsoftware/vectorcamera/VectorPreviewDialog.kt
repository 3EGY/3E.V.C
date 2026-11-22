package com.dozingcatsoftware.vectorcamera

import android.app.Dialog
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.Typeface
import android.os.Handler
import android.os.Looper
import android.text.Editable
import android.text.InputType
import android.text.TextWatcher
import android.view.Gravity
import android.view.MotionEvent
import android.view.ScaleGestureDetector
import android.view.View
import android.view.ViewGroup
import android.view.Window
import android.widget.Button
import android.widget.CheckBox
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.SeekBar
import android.widget.TextView
import java.util.concurrent.Executors
import kotlin.math.min

class VectorPreviewDialog(
    context: Context,
    private val sourceBitmap: Bitmap,
    private val onExportConfirmed: (scene: VectorScene, isDxf: Boolean) -> Unit
) : Dialog(context, android.R.style.Theme_Black_NoTitleBar_Fullscreen) {

    private var settings = VectorExportSettings()
    private var currentScene: VectorScene? = null
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var renderVersion = 0

    private lateinit var canvasView: VectorCanvasView
    private lateinit var statsText: TextView

    init {
        requestWindowFeature(Window.FEATURE_NO_TITLE)
        setContentView(buildUi())
        triggerRecompute()
    }

    private fun buildUi(): View {
        val root = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#121417"))
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        }

        val topBar = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            setBackgroundColor(Color.parseColor("#1C2026"))
            setPadding(24, 16, 24, 16)
            gravity = Gravity.CENTER_VERTICAL
        }

        statsText = TextView(context).apply {
            text = "\u062C\u0627\u0631\u064A \u062A\u062D\u0644\u064A\u0644 \u0627\u0644\u062E\u0637\u0648\u0637..."
            setTextColor(Color.parseColor("#00E5FF"))
            textSize = 13f
            typeface = Typeface.DEFAULT_BOLD
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
        }

        val closeBtn = Button(context).apply {
            text = "\u2715 \u0625\u063A\u0644\u0627\u0642"
            setTextColor(Color.WHITE)
            setBackgroundColor(Color.parseColor("#2C323B"))
            setPadding(24, 8, 24, 8)
            setOnClickListener { dismiss() }
        }
        topBar.addView(statsText)
        topBar.addView(closeBtn)
        root.addView(topBar)

        canvasView = VectorCanvasView(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                0,
                1f
            )
        }
        root.addView(canvasView)

        val controlsScroll = ScrollView(context).apply {
            setBackgroundColor(Color.parseColor("#1A1E24"))
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                (context.resources.displayMetrics.heightPixels * 0.38).toInt()
            )
        }

        val controlsBox = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(28, 16, 28, 16)
        }

        val togglesRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }

        val smartLayersCheck = CheckBox(context).apply {
            text = "\u0637\u0628\u0642\u0627\u062A \u0630\u0643\u064A\u0629 (\u062D\u0648\u0627\u0626\u0637/\u0623\u0628\u0648\u0627\u0628/\u062A\u0641\u0627\u0635\u064A\u0644)"
            isChecked = settings.smartLayers
            setTextColor(Color.WHITE)
            textSize = 13f
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
            setOnCheckedChangeListener { _, checked ->
                settings = settings.copy(smartLayers = checked)
                triggerRecompute()
            }
        }

        val overlayBgCheck = CheckBox(context).apply {
            text = "\u0625\u0638\u0647\u0627\u0631 \u0627\u0644\u0635\u0648\u0631\u0629"
            isChecked = true
            setTextColor(Color.LTGRAY)
            textSize = 13f
            setOnCheckedChangeListener { _, checked ->
                canvasView.showSourceImage = checked
                canvasView.invalidate()
            }
        }
        togglesRow.addView(smartLayersCheck)
        togglesRow.addView(overlayBgCheck)
        controlsBox.addView(togglesRow)

        val angleRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(0, 10, 0, 6)
        }
        val angleTitle = TextView(context).apply {
            text = "\u062A\u0642\u0631\u064A\u0628 \u0644\u0623\u0642\u0631\u0628 \u0632\u0627\u0648\u064A\u0629 (\u00B0): "
            setTextColor(Color.WHITE)
            textSize = 13f
        }
        val angleInput = EditText(context).apply {
            setText("90")
            inputType = InputType.TYPE_CLASS_NUMBER or InputType.TYPE_NUMBER_FLAG_DECIMAL
            setTextColor(Color.parseColor("#00E5FF"))
            setBackgroundColor(Color.parseColor("#262C35"))
            setPadding(20, 8, 20, 8)
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(150, ViewGroup.LayoutParams.WRAP_CONTENT)
            addTextChangedListener(object : TextWatcher {
                override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
                override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
                override fun afterTextChanged(s: Editable?) {
                    val v = s?.toString()?.toFloatOrNull()
                    if (v != null && v in 1f..180f) {
                        settings = settings.copy(snapBaseAngle = v)
                        triggerRecompute()
                    }
                }
            })
        }
        angleRow.addView(angleTitle)
        angleRow.addView(angleInput)
        controlsBox.addView(angleRow)

        controlsBox.addView(createSliderRow(
            label = "\u0642\u0648\u0629 \u062A\u0639\u062F\u064A\u0644 \u0627\u0644\u0632\u0648\u0627\u064A\u0627 (Tolerance)",
            unit = "\u00B0",
            max = 30,
            initial = settings.snapToleranceDeg.toInt()
        ) { progress ->
            settings = settings.copy(snapToleranceDeg = progress.toFloat())
            triggerRecompute()
        })

        controlsBox.addView(createSliderRow(
            label = "\u0625\u0632\u0627\u0644\u0629 \u0627\u0644\u0634\u0648\u0627\u0626\u0628 \u0627\u0644\u0623\u0635\u063A\u0631 \u0645\u0646",
            unit = " px",
            max = 120,
            initial = settings.minNoiseLengthPx.toInt()
        ) { progress ->
            settings = settings.copy(minNoiseLengthPx = progress.toFloat())
            triggerRecompute()
        })

        controlsBox.addView(createSliderRow(
            label = "\u062A\u0628\u0633\u064A\u0637 \u0627\u0644\u0646\u0642\u0627\u0637 \u0648\u062A\u0646\u0639\u064A\u0645 \u0627\u0644\u062E\u0637\u0648\u0637",
            unit = "",
            max = 100,
            initial = (settings.simplifyTolerance * 10).toInt()
        ) { progress ->
            val tol = (progress / 10f).coerceAtLeast(0.2f)
            settings = settings.copy(simplifyTolerance = tol)
            triggerRecompute()
        })

        controlsBox.addView(createSliderRow(
            label = "\u062D\u0633\u0627\u0633\u064A\u0629 \u0627\u0644\u062D\u0648\u0627\u0641 \u0648\u0627\u0644\u062A\u0641\u0627\u0635\u064A\u0644",
            unit = "",
            max = 220,
            initial = settings.edgeThreshold
        ) { progress ->
            settings = settings.copy(edgeThreshold = progress.coerceAtLeast(25))
            triggerRecompute()
        })

        controlsScroll.addView(controlsBox)
        root.addView(controlsScroll)

        val bottomBar = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            setBackgroundColor(Color.parseColor("#121417"))
            setPadding(20, 14, 20, 14)
        }

        val exportDxfBtn = Button(context).apply {
            text = "\u0645\u0634\u0627\u0631\u0643\u0629 \u0645\u0644\u0641 CAD (.DXF)"
            setTextColor(Color.BLACK)
            typeface = Typeface.DEFAULT_BOLD
            setBackgroundColor(Color.parseColor("#00E5FF"))
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f).apply {
                marginEnd = 12
            }
            setOnClickListener {
                currentScene?.let { scene ->
                    dismiss()
                    onExportConfirmed(scene, true)
                }
            }
        }

        val exportSvgBtn = Button(context).apply {
            text = "\u0645\u0634\u0627\u0631\u0643\u0629 (.SVG)"
            setTextColor(Color.WHITE)
            typeface = Typeface.DEFAULT_BOLD
            setBackgroundColor(Color.parseColor("#2E7D32"))
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 0.7f)
            setOnClickListener {
                currentScene?.let { scene ->
                    dismiss()
                    onExportConfirmed(scene, false)
                }
            }
        }

        bottomBar.addView(exportDxfBtn)
        bottomBar.addView(exportSvgBtn)
        root.addView(bottomBar)

        return root
    }

    private fun createSliderRow(
        label: String,
        unit: String,
        max: Int,
        initial: Int,
        onChanged: (Int) -> Unit
    ): View {
        val container = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(0, 6, 0, 6)
        }
        val titleView = TextView(context).apply {
            text = "$label: $initial$unit"
            setTextColor(Color.parseColor("#E0E0E0"))
            textSize = 12.5f
        }
        val seekBar = SeekBar(context).apply {
            this.max = max
            progress = initial
            setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
                override fun onProgressChanged(sb: SeekBar?, p: Int, fromUser: Boolean) {
                    titleView.text = "$label: $p$unit"
                    if (fromUser) onChanged(p)
                }
                override fun onStartTrackingTouch(sb: SeekBar?) {}
                override fun onStopTrackingTouch(sb: SeekBar?) {}
            })
        }
        container.addView(titleView)
        container.addView(seekBar)
        return container
    }

    private fun triggerRecompute() {
        val version = ++renderVersion
        val snapshotSettings = settings
        executor.execute {
            val scene = VectorExporter.traceScene(sourceBitmap, snapshotSettings)
            mainHandler.post {
                if (version == renderVersion && isShowing) {
                    currentScene = scene
                    canvasView.scene = scene
                    canvasView.invalidate()
                    val wallsCount = scene.polylines.count { it.layer == CadLayer.WALLS }
                    val openCount = scene.polylines.count { it.layer == CadLayer.OPENINGS }
                    statsText.text = if (snapshotSettings.smartLayers) {
                        "\u0627\u0644\u062E\u0637\u0648\u0637: ${scene.polylines.size} | \u062D\u0648\u0627\u0626\u0637: $wallsCount | \u0641\u062A\u062D\u0627\u062A: $openCount"
                    } else {
                        "\u0627\u0644\u062E\u0637\u0648\u0637: ${scene.polylines.size} | \u0627\u0644\u0646\u0642\u0627\u0637: ${scene.totalVertices}"
                    }
                }
            }
        }
    }

    override fun dismiss() {
        super.dismiss()
        executor.shutdownNow()
        if (!sourceBitmap.isRecycled) {
            sourceBitmap.recycle()
        }
    }

    private inner class VectorCanvasView(context: Context) : View(context) {
        var scene: VectorScene? = null
        var showSourceImage: Boolean = true

        private val bgPaint = Paint().apply { alpha = 75 }
        private val gridPaint = Paint().apply {
            color = Color.parseColor("#1F262E")
            strokeWidth = 1f
        }
        private val linePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeCap = Paint.Cap.ROUND
            strokeJoin = Paint.Join.ROUND
        }
        private val path = Path()

        private var userScale = 1f
        private var panX = 0f
        private var panY = 0f
        private var lastTouchX = 0f
        private var lastTouchY = 0f

        private val scaleDetector = ScaleGestureDetector(context,
            object : ScaleGestureDetector.SimpleOnScaleGestureListener() {
                override fun onScale(detector: ScaleGestureDetector): Boolean {
                    userScale = (userScale * detector.scaleFactor).coerceIn(0.5f, 12f)
                    invalidate()
                    return true
                }
            })

        override fun onTouchEvent(event: MotionEvent): Boolean {
            scaleDetector.onTouchEvent(event)
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    lastTouchX = event.x
                    lastTouchY = event.y
                }
                MotionEvent.ACTION_MOVE -> {
                    if (!scaleDetector.isInProgress && event.pointerCount == 1) {
                        panX += (event.x - lastTouchX)
                        panY += (event.y - lastTouchY)
                        lastTouchX = event.x
                        lastTouchY = event.y
                        invalidate()
                    }
                }
            }
            return true
        }

        override fun onDraw(canvas: Canvas) {
            super.onDraw(canvas)
            canvas.drawColor(Color.parseColor("#0D1014"))

            val gridStep = 60f
            var gx = 0f
            while (gx < width) {
                canvas.drawLine(gx, 0f, gx, height.toFloat(), gridPaint)
                gx += gridStep
            }
            var gy = 0f
            while (gy < height) {
                canvas.drawLine(0f, gy, width.toFloat(), gy, gridPaint)
                gy += gridStep
            }

            val s = scene ?: return
            val baseScale = min(width.toFloat() / s.width, height.toFloat() / s.height) * 0.94f
            val totalScale = baseScale * userScale
            val offsetX = (width - s.width * totalScale) / 2f + panX
            val offsetY = (height - s.height * totalScale) / 2f + panY

            canvas.save()
            canvas.translate(offsetX, offsetY)
            canvas.scale(totalScale, totalScale)

            if (showSourceImage && !sourceBitmap.isRecycled) {
                canvas.drawBitmap(sourceBitmap, 0f, 0f, bgPaint)
            }

            linePaint.strokeWidth = (2.2f / totalScale).coerceAtLeast(0.6f)
            for (poly in s.polylines) {
                if (poly.points.size < 2) continue
                linePaint.color = poly.layer.previewColor
                path.reset()
                path.moveTo(poly.points[0].x, poly.points[0].y)
                for (i in 1 until poly.points.size) {
                    path.lineTo(poly.points[i].x, poly.points[i].y)
                }
                if (poly.isClosed) path.close()
                canvas.drawPath(path, linePaint)
            }

            canvas.restore()
        }
    }
}