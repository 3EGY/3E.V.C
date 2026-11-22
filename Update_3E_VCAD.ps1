$ErrorActionPreference = "Stop"

if (-not (Test-Path "app\src\main")) {
    Write-Host "ERROR: Place this script inside the root project folder (next to 'app') and run again." -ForegroundColor Red
    exit 1
}

function Write-Utf8NoBom($Path, $Content) {
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText((Join-Path (Get-Location) $Path), $Content, $utf8NoBom)
    Write-Host "[OK] Updated: $Path" -ForegroundColor Green
}

Write-Host "=== Starting 3E.V.CAD Project Update ===" -ForegroundColor Cyan

# 1. Update app name (3E.V.CAD) and share labels in strings.xml
$stringsXml = @'
<resources>
    <string name="app_name">3E.V.CAD</string>
    <string name="noImagesFound">No pictures found.</string>

    <string name="takePictureWithVolumeButtonPrefsKey">takePictureWithVolumeButton</string>
    <string name="takePictureWithVolumeButtonPrefsTitle">Take picture with volume button</string>

    <string name="autoConvertPicturesPrefsKey">autoConvertPictures</string>
    <string name="autoConvertPicturesPrefsTitle">Auto-import camera pictures</string>

    <string name="showDebugInfoPrefsKey">showDebugInfo</string>
    <string name="showDebugInfoPrefsTitle">Show debug info</string>

    <string name="numAsciiColumnsPrefId">numAsciiColumns</string>
    <string name="numAsciiColumnsPrefTitle">Number of text columns</string>

    <string name="whiteOnBlackPixelCharsPrefId">pixelChars.WHITE_ON_BLACK</string>
    <string name="whiteOnBlackPixelCharsPrefTitle">White on black characters</string>
    <string name="whiteOnBlackPixelCharsPrefMessage">Enter characters to use for white on black images from darkest to brightest, or leave blank for the default of .:oO8#</string>

    <string name="blackOnWhitePixelCharsPrefId">pixelChars.BLACK_ON_WHITE</string>
    <string name="blackOnWhitePixelCharsPrefTitle">Black on white characters</string>
    <string name="blackOnWhitePixelCharsPrefMessage">Enter characters to use in images from darkest to brightest, or leave blank for the default of #o:..</string>

    <string name="ansiColorPixelCharsPrefId">pixelChars.ANSI_COLOR</string>
    <string name="ansiColorPixelCharsPrefTitle">Primary color characters</string>
    <string name="ansiColorPixelCharsPrefMessage">Enter characters to use in images from darkest to brightest, or leave blank for the default of .:oO8#</string>

    <string name="fullColorPixelCharsPrefId">pixelChars.FULL_COLOR</string>
    <string name="fullColorPixelCharsPrefTitle">Full color characters</string>
    <string name="fullColorPixelCharsPrefMessage">Enter characters to use in images from darkest to brightest. Full color mode usually works best with fewer or even just one character. Leave blank for default of O8@</string>

    <string name="matrixTextColorPrefId">matrixTextColor</string>
    <string name="matrixTextColorPrefTitle">Matrix text color</string>

    <string name="savingImageMessage">Saving image...</string>
    <string name="exportingImageMessage">Exporting image...</string>

    <string name="shareDialogYesLabel">Share</string>
    <string name="shareDialogNoLabel">Cancel</string>
    <string name="shareActionTitle">Share using</string>

    <string name="sharePictureDialogTitle">Share picture as</string>
    <string name="sharePictureImageOptionLabel">Image (PNG)</string>
    <string name="sharePictureDxfOptionLabel">CAD Vector Studio (DXF / SVG)</string>
    <string name="sharePictureHtmlOptionLabel">HTML</string>
    <string name="sharePictureTextOptionLabel">Text</string>

    <string name="shareVideoDialogTitle">Share video as</string>
    <string name="shareVideoWebmOptionLabel">WebM video</string>
    <string name="shareVideoFrameArchiveOptionLabel">All frames as ZIP archive</string>
    <string name="shareVideoSingleFrameOptionLabel">Current frame as image</string>

    <string name="webmExportDialogTitle">Exporting to WebM</string>
    <string name="webmExportDialogMessageVideo">Writing video track</string>
    <string name="webmExportDialogMessageAudio">Writing audio track</string>

    <string name="zipExportDialogTitle">Creating ZIP archive</string>
    <string name="zipExportDialogMessageVideo">Writing video frames</string>
    <string name="zipExportDialogMessageAudio">Writing audio data</string>
</resources>
'@
Write-Utf8NoBom "app\src\main\res\values\strings.xml" $stringsXml

# 2. Update Adaptive Vector App Icon (3E + CAD Vector Wireframe)
Get-ChildItem -Path "app\src\main\res\mipmap-*" -Filter "ic_launcher*.png" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force

$icBgXml = @'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#0F172A</color>
</resources>
'@
Write-Utf8NoBom "app\src\main\res\values\ic_launcher_background.xml" $icBgXml

$icForegroundXml = @'
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">

    <path
        android:strokeColor="#1E293B"
        android:strokeWidth="0.7"
        android:pathData="M24,18 L24,90 M44,18 L44,90 M64,18 L64,90 M84,18 L84,90 M18,24 L90,24 M18,44 L90,44 M18,64 L90,64 M18,84 L90,84" />

    <path
        android:strokeColor="#0284C7"
        android:strokeWidth="1.8"
        android:fillColor="#00000000"
        android:pathData="M26,32 L54,20 L82,32 L82,76 L54,88 L26,76 Z" />
    <path
        android:strokeColor="#0EA5E9"
        android:strokeWidth="1.2"
        android:fillColor="#00000000"
        android:pathData="M26,32 L54,44 L82,32 M54,44 L54,88 M22,54 L86,54" />

    <path android:fillColor="#38BDF8" android:pathData="M24,30 h4 v4 h-4 z" />
    <path android:fillColor="#38BDF8" android:pathData="M52,18 h4 v4 h-4 z" />
    <path android:fillColor="#38BDF8" android:pathData="M80,30 h4 v4 h-4 z" />
    <path android:fillColor="#38BDF8" android:pathData="M80,74 h4 v4 h-4 z" />
    <path android:fillColor="#38BDF8" android:pathData="M52,86 h4 v4 h-4 z" />
    <path android:fillColor="#38BDF8" android:pathData="M24,74 h4 v4 h-4 z" />

    <path
        android:fillColor="#D90F172A"
        android:pathData="M28,41 L80,41 L80,67 L28,67 Z" />

    <path
        android:strokeColor="#00E5FF"
        android:strokeWidth="4.2"
        android:strokeCap="round"
        android:strokeJoin="round"
        android:fillColor="#00000000"
        android:pathData="M33,45 L48,45 L41,53.5 L48,53.5 L48,63 L33,63" />

    <path
        android:strokeColor="#FFFFFF"
        android:strokeWidth="4.2"
        android:strokeCap="round"
        android:strokeJoin="round"
        android:fillColor="#00000000"
        android:pathData="M73,45 L57,45 L57,63 L73,63 M57,54 L69,54" />
</vector>
'@
Write-Utf8NoBom "app\src\main\res\drawable\ic_launcher_foreground.xml" $icForegroundXml

$icAdaptiveXml = @'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
'@
Write-Utf8NoBom "app\src\main\res\mipmap-anydpi-v26\ic_launcher.xml" $icAdaptiveXml
Write-Utf8NoBom "app\src\main\res\mipmap-anydpi-v26\ic_launcher_round.xml" $icAdaptiveXml

# 3. Create VectorExporter.kt
$vectorExporterKt = @'
package com.dozingcatsoftware.vectorcamera

import android.graphics.Bitmap
import android.graphics.Color
import java.io.BufferedWriter
import java.io.OutputStream
import java.io.OutputStreamWriter
import java.util.Locale
import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.round
import kotlin.math.sin

data class VectorExportSettings(
    val simplifyTolerance: Float = 1.8f,
    val minNoiseLengthPx: Float = 12f,
    val edgeThreshold: Int = 150,
    val snapBaseAngle: Float = 90f,
    val snapToleranceDeg: Float = 8f,
    val smartLayers: Boolean = true
)

enum class CadLayer(val dxfName: String, val aciColor: Int, val previewColor: Int) {
    WALLS("3E_WALLS", 7, Color.parseColor("#FFFFFF")),
    OPENINGS("3E_OPENINGS", 4, Color.parseColor("#00E5FF")),
    DETAILS("3E_DETAILS", 3, Color.parseColor("#76FF03")),
    SINGLE("3E_VECTOR", 7, Color.parseColor("#00E5FF"))
}

data class VectorPolyline(
    val points: List<VectorExporter.Point2D>,
    val isClosed: Boolean,
    val layer: CadLayer
)

data class VectorScene(
    val polylines: List<VectorPolyline>,
    val width: Int,
    val height: Int
) {
    val totalVertices: Int get() = polylines.sumOf { it.points.size }
}

object VectorExporter {

    data class Point2D(val x: Float, val y: Float)

    fun traceScene(src: Bitmap, settings: VectorExportSettings): VectorScene {
        val maxDim = 1280
        val scale = if (max(src.width, src.height) > maxDim) {
            maxDim.toFloat() / max(src.width, src.height)
        } else {
            1f
        }
        val w = max(1, (src.width * scale).toInt())
        val h = max(1, (src.height * scale).toInt())
        val bmp = if (scale < 1f) Bitmap.createScaledBitmap(src, w, h, true) else src

        val pixels = IntArray(w * h)
        bmp.getPixels(pixels, 0, w, 0, 0, w, h)
        if (bmp !== src) bmp.recycle()

        val luma = IntArray(w * h)
        var sumLuma = 0L
        var extremeCount = 0
        for (i in pixels.indices) {
            val c = pixels[i]
            val y = (77 * Color.red(c) + 150 * Color.green(c) + 29 * Color.blue(c)) shr 8
            luma[i] = y
            sumLuma += y
            if (y < 30 || y > 225) extremeCount++
        }
        val avgLuma = (sumLuma / max(1, pixels.size)).toInt()
        val isLineArt = extremeCount > (pixels.size * 0.72)

        val edge = BooleanArray(w * h)
        if (isLineArt) {
            val darkBackground = avgLuma < 128
            val cutoff = settings.edgeThreshold.coerceIn(20, 235)
            for (i in luma.indices) {
                edge[i] = if (darkBackground) luma[i] > (255 - cutoff) else luma[i] < cutoff
            }
        } else {
            val gradCutoff = (settings.edgeThreshold * 1.4f).toInt().coerceIn(40, 350)
            for (y in 1 until h - 1) {
                val row = y * w
                for (x in 1 until w - 1) {
                    val idx = row + x
                    val gx = -luma[idx - w - 1] + luma[idx - w + 1] -
                            2 * luma[idx - 1] + 2 * luma[idx + 1] -
                            luma[idx + w - 1] + luma[idx + w + 1]
                    val gy = -luma[idx - w - 1] - 2 * luma[idx - w] - luma[idx - w + 1] +
                            luma[idx + w - 1] + 2 * luma[idx + w] + luma[idx + w + 1]
                    if (abs(gx) + abs(gy) > gradCutoff) {
                        edge[idx] = true
                    }
                }
            }
        }

        val visited = BooleanArray(w * h)
        val dx = intArrayOf(1, 1, 0, -1, -1, -1, 0, 1)
        val dy = intArrayOf(0, 1, 1, 1, 0, -1, -1, -1)
        val invScale = 1f / scale
        val polylines = ArrayList<VectorPolyline>()
        val diagRef = hypot(src.width.toDouble(), src.height.toDouble()).toFloat()

        for (y in 1 until h - 1) {
            for (x in 1 until w - 1) {
                val startIdx = y * w + x
                if (!edge[startIdx] || visited[startIdx]) continue

                val chain = ArrayList<Point2D>()
                var cx = x
                var cy = y
                var dir = 0

                while (true) {
                    val idx = cy * w + cx
                    visited[idx] = true
                    chain.add(Point2D(cx * invScale, cy * invScale))

                    var foundNext = false
                    for (step in 0 until 8) {
                        val nd = (dir + step) and 7
                        val nx = cx + dx[nd]
                        val ny = cy + dy[nd]
                        if (nx in 1 until w - 1 && ny in 1 until h - 1) {
                            val nIdx = ny * w + nx
                            if (edge[nIdx] && !visited[nIdx]) {
                                cx = nx
                                cy = ny
                                dir = (nd + 6) and 7
                                foundNext = true
                                break
                            }
                        }
                    }
                    if (!foundNext) break
                }

                if (chain.size < 3) continue

                var pts = ramerDouglasPeucker(chain, settings.simplifyTolerance * invScale)
                if (pts.size < 2) continue

                if (settings.snapToleranceDeg > 0.1f && settings.snapBaseAngle > 1f) {
                    pts = snapAngles(pts, settings.snapBaseAngle, settings.snapToleranceDeg)
                }

                val totalLen = polylineLength(pts)
                if (totalLen < settings.minNoiseLengthPx) continue

                val isClosed = pts.size > 3 &&
                        hypot((pts.first().x - pts.last().x).toDouble(),
                              (pts.first().y - pts.last().y).toDouble()) <= (4.0 * invScale)

                val layer = classifyLayer(pts, totalLen, isClosed, diagRef, settings.smartLayers)
                polylines.add(VectorPolyline(pts, isClosed, layer))
            }
        }

        return VectorScene(polylines, src.width, src.height)
    }

    private fun snapAngles(points: List<Point2D>, baseAngleDeg: Float, toleranceDeg: Float): List<Point2D> {
        if (points.size < 2) return points
        val out = ArrayList<Point2D>(points.size)
        out.add(points[0])

        for (i in 1 until points.size) {
            val prevOrig = points[i - 1]
            val currOrig = points[i]
            val segLen = hypot((currOrig.x - prevOrig.x).toDouble(), (currOrig.y - prevOrig.y).toDouble()).toFloat()
            if (segLen < 0.5f) continue

            val rawAngleDeg = Math.toDegrees(atan2((currOrig.y - prevOrig.y).toDouble(), (currOrig.x - prevOrig.x).toDouble())).toFloat()
            val nearestMultiple = round(rawAngleDeg / baseAngleDeg) * baseAngleDeg
            val diff = abs(rawAngleDeg - nearestMultiple)

            val prevNew = out.last()
            if (diff <= toleranceDeg) {
                val rad = Math.toRadians(nearestMultiple.toDouble())
                val nx = prevNew.x + (segLen * cos(rad)).toFloat()
                val ny = prevNew.y + (segLen * sin(rad)).toFloat()
                out.add(Point2D(nx, ny))
            } else {
                val dx = currOrig.x - prevOrig.x
                val dy = currOrig.y - prevOrig.y
                out.add(Point2D(prevNew.x + dx, prevNew.y + dy))
            }
        }
        return out
    }

    private fun classifyLayer(
        pts: List<Point2D>,
        length: Float,
        isClosed: Boolean,
        diagRef: Float,
        smartLayers: Boolean
    ): CadLayer {
        if (!smartLayers) return CadLayer.SINGLE

        if (isClosed && pts.size in 4..7 && length in (diagRef * 0.04f)..(diagRef * 0.35f)) {
            return CadLayer.OPENINGS
        }

        if (length >= diagRef * 0.14f) {
            return CadLayer.WALLS
        }

        if (pts.size in 3..5 && length >= diagRef * 0.06f) {
            return CadLayer.OPENINGS
        }

        return CadLayer.DETAILS
    }

    private fun polylineLength(pts: List<Point2D>): Float {
        var sum = 0f
        for (i in 1 until pts.size) {
            sum += hypot((pts[i].x - pts[i - 1].x).toDouble(), (pts[i].y - pts[i - 1].y).toDouble()).toFloat()
        }
        return sum
    }

    fun writeDxf(scene: VectorScene, outputStream: OutputStream) {
        BufferedWriter(OutputStreamWriter(outputStream, Charsets.UTF_8)).use { writer ->
            writer.write("0\nSECTION\n2\nHEADER\n")
            writer.write("9\n\$ACADVER\n1\nAC1009\n")
            writer.write("9\n\$INSUNITS\n70\n4\n")
            writer.write("9\n\$EXTMIN\n10\n0.0\n20\n0.0\n30\n0.0\n")
            writer.write("9\n\$EXTMAX\n10\n${scene.width.toFloat()}\n20\n${scene.height.toFloat()}\n30\n0.0\n")
            writer.write("0\nENDSEC\n")

            val usedLayers = scene.polylines.map { it.layer }.distinct().ifEmpty { listOf(CadLayer.SINGLE) }
            writer.write("0\nSECTION\n2\nTABLES\n0\nTABLE\n2\nLAYER\n70\n${usedLayers.size}\n")
            for (layer in usedLayers) {
                writer.write("0\nLAYER\n2\n${layer.dxfName}\n70\n0\n62\n${layer.aciColor}\n6\nCONTINUOUS\n")
            }
            writer.write("0\nENDTAB\n0\nENDSEC\n")

            writer.write("0\nSECTION\n2\nENTITIES\n")
            for (poly in scene.polylines) {
                if (poly.points.size < 2) continue
                val layerName = poly.layer.dxfName
                writer.write("0\nPOLYLINE\n8\n$layerName\n66\n1\n")
                writer.write("10\n0.0\n20\n0.0\n30\n0.0\n")
                writer.write("70\n${if (poly.isClosed) 1 else 0}\n")

                val limit = if (poly.isClosed) poly.points.size - 1 else poly.points.size
                for (i in 0 until limit) {
                    val pt = poly.points[i]
                    val cadY = scene.height - pt.y
                    writer.write("0\nVERTEX\n8\n$layerName\n")
                    writer.write("10\n${"%.2f".format(Locale.US, pt.x)}\n")
                    writer.write("20\n${"%.2f".format(Locale.US, cadY)}\n")
                    writer.write("30\n0.0\n")
                }
                writer.write("0\nSEQEND\n")
            }
            writer.write("0\nENDSEC\n0\nEOF\n")
        }
    }

    fun writeSvg(scene: VectorScene, outputStream: OutputStream) {
        BufferedWriter(OutputStreamWriter(outputStream, Charsets.UTF_8)).use { writer ->
            writer.write("""<?xml version="1.0" encoding="UTF-8"?>""" + "\n")
            writer.write(
                """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${scene.width} ${scene.height}" width="${scene.width}" height="${scene.height}">""" + "\n"
            )

            val grouped = scene.polylines.groupBy { it.layer }
            for ((layer, polys) in grouped) {
                val strokeHex = when (layer) {
                    CadLayer.WALLS -> "#111111"
                    CadLayer.OPENINGS -> "#00838F"
                    CadLayer.DETAILS -> "#2E7D32"
                    CadLayer.SINGLE -> "#000000"
                }
                writer.write("""  <g id="${layer.dxfName}" fill="none" stroke="$strokeHex" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round">""" + "\n")
                for (poly in polys) {
                    if (poly.points.size < 2) continue
                    val sb = StringBuilder("    <path d=\"")
                    for (i in poly.points.indices) {
                        val pt = poly.points[i]
                        val cmd = if (i == 0) "M" else "L"
                        sb.append("$cmd${"%.1f".format(Locale.US, pt.x)},${"%.1f".format(Locale.US, pt.y)} ")
                    }
                    if (poly.isClosed) sb.append("Z")
                    sb.append("\" />\n")
                    writer.write(sb.toString())
                }
                writer.write("  </g>\n")
            }
            writer.write("</svg>\n")
        }
    }

    private fun ramerDouglasPeucker(points: List<Point2D>, epsilon: Float): List<Point2D> {
        if (points.size < 3) return points
        var maxDist = 0f
        var index = 0
        val end = points.size - 1

        for (i in 1 until end) {
            val d = perpendicularDistance(points[i], points[0], points[end])
            if (d > maxDist) {
                maxDist = d
                index = i
            }
        }

        return if (maxDist > epsilon) {
            val left = ramerDouglasPeucker(points.subList(0, index + 1), epsilon)
            val right = ramerDouglasPeucker(points.subList(index, points.size), epsilon)
            left.dropLast(1) + right
        } else {
            listOf(points.first(), points.last())
        }
    }

    private fun perpendicularDistance(p: Point2D, a: Point2D, b: Point2D): Float {
        val dx = b.x - a.x
        val dy = b.y - a.y
        if (dx == 0f && dy == 0f) {
            return hypot((p.x - a.x).toDouble(), (p.y - a.y).toDouble()).toFloat()
        }
        val num = abs(dy * p.x - dx * p.y + b.x * a.y - b.y * a.x)
        val den = hypot(dx.toDouble(), dy.toDouble()).toFloat()
        return num / den
    }
}
'@
Write-Utf8NoBom "app\src\main\java\com\dozingcatsoftware\vectorcamera\VectorExporter.kt" $vectorExporterKt

# 4. Create VectorPreviewDialog.kt (using Unicode escapes for Arabic UI text so file encoding never breaks)
$vectorPreviewDialogKt = @'
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
'@
Write-Utf8NoBom "app\src\main\java\com\dozingcatsoftware\vectorcamera\VectorPreviewDialog.kt" $vectorPreviewDialogKt

# 5. Update ViewImageActivity.kt
$viewImageActivityKt = @'
package com.dozingcatsoftware.vectorcamera

import android.app.Activity
import android.app.AlertDialog
import android.app.ProgressDialog
import android.content.DialogInterface
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.util.Log
import android.view.View
import android.widget.Toast
import androidx.activity.OnBackPressedCallback
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.FileProvider
import com.dozingcatsoftware.util.getLandscapeDisplaySize
import com.dozingcatsoftware.util.grantUriPermissionForIntent
import com.dozingcatsoftware.vectorcamera.databinding.ViewImageBinding
import com.dozingcatsoftware.vectorcamera.effect.AsciiEffect
import com.dozingcatsoftware.vectorcamera.effect.CustomEffect
import com.dozingcatsoftware.vectorcamera.effect.Effect
import com.dozingcatsoftware.vectorcamera.effect.EffectContext
import com.dozingcatsoftware.vectorcamera.effect.EffectInfo
import com.dozingcatsoftware.vectorcamera.effect.EffectRegistry
import com.dozingcatsoftware.vectorcamera.effect.customColorMapEffect
import com.dozingcatsoftware.vectorcamera.effect.customContourEffect
import com.dozingcatsoftware.vectorcamera.effect.customPaletteEffect
import com.dozingcatsoftware.vectorcamera.effect.customPermuteEffect
import java.io.File


class ViewImageActivity : AppCompatActivity() {
    private lateinit var binding: ViewImageBinding

    private lateinit var photoLibrary: PhotoLibrary

    private lateinit var imageId: String
    private var inEffectSelectionMode = false
    private var thumbnailRenderer: StaticThumbnailRenderer? = null
    private var cameraImageForEditing: CameraImage? = null
    private val effectRegistry = EffectRegistry()
    private val preferences = VCPreferences(this)
    private val handler = Handler()

    private lateinit var onBackPressedCallback: OnBackPressedCallback

    public override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ViewImageBinding.inflate(layoutInflater)
        setContentView(binding.root)
        photoLibrary = PhotoLibrary.defaultLibrary(this)

        binding.switchEffectButton.setOnClickListener(this::toggleEffectSelectionMode)
        binding.editEffectButton.setOnClickListener(this::showCustomEffectEditor)
        binding.shareButton.setOnClickListener(this::shareImage)
        binding.deleteButton.setOnClickListener(this::deleteImage)
        binding.editSchemeView.activity = this
        binding.editSchemeView.changeCallback = this::handleCustomColorSchemeChanged
        binding.editSchemeView.doneCallback = this::handleCustomEffectEditorDone
        binding.editPermuteView.changeCallback = this::handleCustomPermuteSchemeChanged
        binding.editPermuteView.doneCallback = this::handleCustomEffectEditorDone
        binding.editPaletteView.activity = this
        binding.editPaletteView.changeCallback = this::handleCustomPaletteSchemeChanged
        binding.editPaletteView.doneCallback = this::handleCustomEffectEditorDone
        binding.editContourView.activity = this
        binding.editContourView.changeCallback = this::handleCustomContourSchemeChanged
        binding.editContourView.doneCallback = this::handleCustomEffectEditorDone
        binding.effectPickerView.setEffects(effectRegistry.effectInfos)
        binding.effectPickerView.onEffectSelected = this::handleEffectSelected
        binding.effectPickerView.onThumbnailNeeded = {info ->
            thumbnailRenderer?.requestThumbnail(info.id)
        }

        onBackPressedCallback = object: OnBackPressedCallback(false) {
            override fun handleOnBackPressed() {
                if (inEffectSelectionMode) {
                    toggleEffectSelectionMode(null)
                }
                else if (visibleCustomEffectEditor() != null) {
                    hideCustomEffectEditor()
                }
            }
        }
        onBackPressedDispatcher.addCallback(onBackPressedCallback)

        imageId = intent.getStringExtra("imageId")!!
        loadImage()
    }

    override fun onDestroy() {
        thumbnailRenderer?.shutdown()
        thumbnailRenderer = null
        super.onDestroy()
    }

    private fun loadImage() {
        val metadata = photoLibrary.metadataForItemId(imageId)
        val effect = effectRegistry.effectForMetadata(metadata.effectMetadata)
        showImage(effect, metadata)
        updateEditButton()
    }

    private fun customEffectForImage(metadata: MediaMetadata): Effect? =
            effectRegistry.customEffectForMetadata(
                    metadata.effectId, metadata.effectMetadata, preferences.lookupFunction)

    private fun customEffectEditors() = listOf(
            binding.editSchemeView, binding.editPermuteView,
            binding.editPaletteView, binding.editContourView)

    private fun visibleCustomEffectEditor(): View? =
            customEffectEditors().firstOrNull {it.visibility == View.VISIBLE}

    private fun updateBackPressedCallback() {
        onBackPressedCallback.isEnabled =
                inEffectSelectionMode || visibleCustomEffectEditor() != null
    }

    private fun updateEditButton() {
        val editable = customEffectForImage(photoLibrary.metadataForItemId(imageId)) != null
        binding.editEffectButton.visibility =
                if (editable && visibleCustomEffectEditor() == null) View.VISIBLE else View.GONE
    }

    private fun showCustomEffectEditor(effect: Effect) {
        hideCustomEffectEditor()
        val editor: View? = when (val scheme = (effect as? CustomEffect<*>)?.scheme) {
            is CustomColorScheme -> binding.editSchemeView.also {it.setScheme(scheme)}
            is CustomPermuteScheme -> binding.editPermuteView.also {it.setScheme(scheme)}
            is CustomPaletteScheme -> binding.editPaletteView.also {it.setScheme(scheme)}
            is CustomContourScheme -> binding.editContourView.also {it.setScheme(scheme)}
            else -> null
        }
        editor?.visibility = View.VISIBLE
        if (visibleCustomEffectEditor() != null) {
            cameraImageForEditing = createCameraImage(photoLibrary.metadataForItemId(imageId))
        }
        updateBackPressedCallback()
        updateEditButton()
    }

    private fun showCustomEffectEditor(view: View?) {
        val effect = customEffectForImage(photoLibrary.metadataForItemId(imageId)) ?: return
        showCustomEffectEditor(effect)
    }

    private fun hideCustomEffectEditor() {
        for (editor in customEffectEditors()) {
            editor.visibility = View.GONE
        }
        handleCustomEffectEditorDone()
    }

    private fun handleCustomEffectEditorDone() {
        cameraImageForEditing = null
        updateBackPressedCallback()
        updateEditButton()
    }

    private fun handleCustomColorSchemeChanged(cs: CustomColorScheme) {
        applyEditedEffect {id -> customColorMapEffect(cs, id, EffectContext.NORMAL)}
    }

    private fun handleCustomPermuteSchemeChanged(ps: CustomPermuteScheme) {
        applyEditedEffect {id -> customPermuteEffect(ps, id)}
    }

    private fun handleCustomPaletteSchemeChanged(ps: CustomPaletteScheme) {
        applyEditedEffect {id -> customPaletteEffect(ps, id)}
    }

    private fun handleCustomContourSchemeChanged(cs: CustomContourScheme) {
        applyEditedEffect {id -> customContourEffect(cs, id)}
    }

    private fun applyEditedEffect(effectForId: (String) -> Effect) {
        val metadata = photoLibrary.metadataForItemId(imageId)
        val effectId = metadata.effectId ?: return
        val effect = effectForId(effectId)
        val newMetadata = metadata.withEffectMetadata(effect.effectMetadata(), effectId)
        val cameraImage = cameraImageForEditing ?: createCameraImage(newMetadata)
        val pb = effect.createBitmap(cameraImage)
        photoLibrary.writeMetadata(newMetadata, imageId)
        photoLibrary.writeThumbnail(pb, imageId)
        binding.overlayView.updateBitmap(pb)
    }

    private fun showEffectPicker() {
        val picker = binding.effectPickerView
        val metadata = photoLibrary.metadataForItemId(imageId)
        var renderer: StaticThumbnailRenderer? = null
        renderer = StaticThumbnailRenderer(
                effectRegistry, preferences.lookupFunction, createCameraImage(metadata),
                {picker.thumbnailSize},
                {id, bitmap ->
                    handler.post {
                        if (renderer === thumbnailRenderer) {
                            picker.setThumbnail(id, bitmap)
                        }
                    }
                })
        thumbnailRenderer?.shutdown()
        thumbnailRenderer = renderer
        picker.clearThumbnails()
        picker.setSourceShape(metadata.width, metadata.height, metadata.orientation.portrait)
        picker.selectedEffectId = metadata.effectId
        picker.visibility = View.VISIBLE
        picker.scrollToEffect(metadata.effectId)
        binding.controlBar.visibility = View.GONE
        hideCustomEffectEditor()
    }

    private fun hideEffectPicker() {
        thumbnailRenderer?.shutdown()
        thumbnailRenderer = null
        binding.effectPickerView.visibility = View.GONE
        binding.effectPickerView.clearThumbnails()
        binding.controlBar.visibility = View.VISIBLE
    }

    private fun updateInEffectSelectionModeFlag(inMode: Boolean) {
        inEffectSelectionMode = inMode
        updateBackPressedCallback()
    }

    private fun toggleEffectSelectionMode(view: View?) {
        updateInEffectSelectionModeFlag(!inEffectSelectionMode)
        if (inEffectSelectionMode) {
            showEffectPicker()
        }
        else {
            hideEffectPicker()
        }
    }

    private fun createCameraImage(metadata: MediaMetadata): CameraImage {
        val yuvBytes = photoLibrary.rawImageFileInputStreamForItemId(imageId).readBytes()
        val imageData = ImageData.fromYuvBytes(
            yuvBytes, metadata.width, metadata.height
        )
        return CameraImage(imageData, metadata.orientation,
                CameraStatus.CAPTURING_PHOTO, metadata.timestamp, getLandscapeDisplaySize(this))
    }

    private fun createProcessedBitmap(effect: Effect, metadata: MediaMetadata): ProcessedBitmap {
        return effect.createBitmap(createCameraImage(metadata))
    }

    private fun showImage(effect: Effect, metadata: MediaMetadata) {
        val pb = createProcessedBitmap(effect, metadata)
        binding.overlayView.updateBitmap(pb)
    }

    private fun handleEffectSelected(info: EffectInfo) {
        val effect = effectRegistry.createEffect(info.id, preferences.lookupFunction)
        val newMetadata = photoLibrary.metadataForItemId(imageId)
                .withEffectMetadata(effect.effectMetadata(), info.id)
        val pb = createProcessedBitmap(effect, newMetadata)
        photoLibrary.writeMetadata(newMetadata, imageId)
        photoLibrary.writeThumbnail(pb, imageId)
        binding.overlayView.updateBitmap(pb)
        updateInEffectSelectionModeFlag(false)
        hideEffectPicker()
        showCustomEffectEditor(effect)
    }

    private fun shareImage(view: View) {
        val metadata = photoLibrary.metadataForItemId(imageId)
        val effect = effectRegistry.effectForMetadata(metadata.effectMetadata)
        showFormatShareDialog(metadata, effect)
    }

    private fun shareFile(path: String, mimeType: String) {
        val file = File(path)
        val fileUri = FileProvider.getUriForFile(this,
                BuildConfig.APPLICATION_ID + ".fileprovider", file)
        val shareIntent = Intent(Intent.ACTION_SEND)
        shareIntent.type = mimeType
        shareIntent.putExtra(Intent.EXTRA_STREAM, fileUri)
        shareIntent.putExtra(Intent.EXTRA_SUBJECT, file.name)
        shareIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

        val chooser = Intent.createChooser(shareIntent, getString(R.string.shareActionTitle))
        grantUriPermissionForIntent(this, fileUri, chooser)
        startActivity(chooser)
    }

    private fun shareImage(metadata: MediaMetadata, effect: Effect) {
        var waitDialog: ProgressDialog? = null
        val pngFile = photoLibrary.imageFileForItemId(imageId)
        var firstCheckTimestamp: Long? = null

        fun doShare() {
            waitDialog?.cancel()
            waitDialog = null
            shareFile(pngFile.path, "image/png")
        }

        fun showWaitDialog() {
            if (waitDialog == null) {
                waitDialog = ProgressDialog(this)
                waitDialog!!.isIndeterminate = true
                waitDialog!!.setMessage(getString(R.string.exportingImageMessage))
                waitDialog!!.setCancelable(false)
                Log.i(TAG, "Showing wait dialog")
                waitDialog!!.show()
            }
        }

        fun exportAndShare() {
            showWaitDialog()
            Thread {
                try {
                    val pb = createProcessedBitmap(effect, metadata)
                    photoLibrary.writePngImage(this, pb, imageId)
                    val currentMetadata = photoLibrary.metadataForItemId(imageId)
                    val newMetadata = currentMetadata.withExportedEffectMetadata(
                        effect.effectMetadata(), "png")
                    photoLibrary.writeMetadata(newMetadata, imageId)
                    handler.post { doShare() }
                } catch (ex: Exception) {
                    handler.post {
                        Toast.makeText(this, "Error exporting image", Toast.LENGTH_LONG).show()
                    }
                } finally {
                    waitDialog?.dismiss()
                }
            }.start()
        }

        fun shareIfExists() {
            if (pngFile.exists()) {
                val exportedEffect =
                        photoLibrary.metadataForItemId(imageId).exportedEffectMetadata["png"]
                if (effect.effectMetadata().equals(exportedEffect)) {
                    Log.i(TAG, "Exported effect matches")
                    doShare()
                }
                else {
                    Log.i(TAG, "Exported effect doesn't match, re-exporting")
                    exportAndShare()
                }
            }
            else {
                val now = System.currentTimeMillis()
                if (firstCheckTimestamp == null) {
                    firstCheckTimestamp = now
                }
                if ((now - metadata.timestamp < 10000) && (now - firstCheckTimestamp!! < 10000)) {
                    Log.i(TAG, "Waiting for initial export")
                    showWaitDialog()
                    handler.postDelayed({shareIfExists()}, 1000L)
                }
                else {
                    Log.i(TAG, "Giving up on initial export")
                    exportAndShare()
                }
            }
        }
        shareIfExists()
    }

    private fun openVectorStudio(metadata: MediaMetadata, effect: Effect) {
        val waitDialog = ProgressDialog(this).apply {
            isIndeterminate = true
            setMessage("Preparing CAD Studio...")
            setCancelable(false)
            show()
        }

        Thread {
            try {
                val pb = createProcessedBitmap(effect, metadata)
                val fullBitmap = pb.renderBitmap(pb.sourceImage.width(), pb.sourceImage.height())
                handler.post {
                    waitDialog.dismiss()
                    VectorPreviewDialog(this, fullBitmap) { finalScene, isDxf ->
                        exportAndShareScene(finalScene, isDxf)
                    }.show()
                }
            } catch (ex: Exception) {
                Log.e(TAG, "Error preparing CAD studio", ex)
                handler.post {
                    waitDialog.dismiss()
                    Toast.makeText(this, "Error: ${ex.message}", Toast.LENGTH_LONG).show()
                }
            }
        }.start()
    }

    private fun exportAndShareScene(scene: VectorScene, isDxf: Boolean) {
        val waitDialog = ProgressDialog(this).apply {
            isIndeterminate = true
            setMessage(if (isDxf) "Exporting DXF CAD file..." else "Exporting SVG file...")
            setCancelable(false)
            show()
        }

        Thread {
            try {
                val ext = if (isDxf) "dxf" else "svg"
                val mimeType = if (isDxf) "application/dxf" else "image/svg+xml"
                val outFile = photoLibrary.tempFileWithName("${imageId}_3E.$ext")
                photoLibrary.createTempFileOutputStream(outFile).use { os ->
                    if (isDxf) {
                        VectorExporter.writeDxf(scene, os)
                    } else {
                        VectorExporter.writeSvg(scene, os)
                    }
                }
                handler.post {
                    waitDialog.dismiss()
                    shareFile(outFile.path, mimeType)
                }
            } catch (ex: Exception) {
                Log.e(TAG, "Error exporting vector", ex)
                handler.post {
                    waitDialog.dismiss()
                    Toast.makeText(this, "Error exporting: ${ex.message}", Toast.LENGTH_LONG).show()
                }
            }
        }.start()
    }

    private fun shareText(metadata: MediaMetadata, effect: AsciiEffect) {
        val textFile = photoLibrary.tempFileWithName(imageId + ".txt")
        val inputImage = createCameraImage(metadata)
        photoLibrary.createTempFileOutputStream(textFile).use {
            effect.writeText(inputImage, it)
        }
        shareFile(textFile.path, "text/plain")
    }

    private fun shareHtml(metadata: MediaMetadata, effect: AsciiEffect) {
        val htmlFile = photoLibrary.tempFileWithName(imageId + ".html")
        val inputImage = createCameraImage(metadata)
        photoLibrary.createTempFileOutputStream(htmlFile).use {
            effect.writeHtml(inputImage, it)
        }
        shareFile(htmlFile.path, "text/html")
    }

    private fun showFormatShareDialog(metadata: MediaMetadata, effect: Effect) {
        val shareTypes = mutableListOf("image", "cad_studio")
        val shareTypeLabels = mutableListOf(
            getString(R.string.sharePictureImageOptionLabel),
            getString(R.string.sharePictureDxfOptionLabel)
        )
        if (effect is AsciiEffect) {
            shareTypes.add("html")
            shareTypes.add("text")
            shareTypeLabels.add(getString(R.string.sharePictureHtmlOptionLabel))
            shareTypeLabels.add(getString(R.string.sharePictureTextOptionLabel))
        }

        var selectedShareType = shareTypes[0]
        AlertDialog.Builder(this)
            .setTitle(R.string.sharePictureDialogTitle)
            .setSingleChoiceItems(shareTypeLabels.toTypedArray(), 0) { _: DialogInterface, which: Int ->
                selectedShareType = shareTypes[which]
            }
            .setPositiveButton(R.string.shareDialogYesLabel) { _: DialogInterface, _: Int ->
                when (selectedShareType) {
                    "image" -> shareImage(metadata, effect)
                    "cad_studio" -> openVectorStudio(metadata, effect)
                    "html" -> if (effect is AsciiEffect) shareHtml(metadata, effect)
                    "text" -> if (effect is AsciiEffect) shareText(metadata, effect)
                }
            }
            .setNegativeButton(R.string.shareDialogNoLabel, null)
            .show()
    }

    private fun deleteImage(view: View) {
        val deleteFn = { _: DialogInterface, _: Int ->
            photoLibrary.deleteItem(imageId)
            finish()
        }

        AlertDialog.Builder(this)
                .setCancelable(true)
                .setMessage("Are you sure you want to delete this picture?")
                .setPositiveButton("Delete", deleteFn)
                .setNegativeButton("Don't delete", null)
                .show()
    }

    companion object {
        const val TAG = "ViewImageActivity"

        fun startActivityWithImageId(parent: Activity, imageId: String): Intent {
            val intent = Intent(parent, ViewImageActivity::class.java)
            intent.putExtra("imageId", imageId)
            parent.startActivityForResult(intent, 0)
            return intent
        }
    }
}
'@
Write-Utf8NoBom "app\src\main\java\com\dozingcatsoftware\vectorcamera\ViewImageActivity.kt" $viewImageActivityKt

# 6. Update GitHub Actions Workflow
$workflowYml = @'
name: Build 3E.V.CAD APK

on:
  push:
    branches: [ master, main ]
  pull_request:
    branches: [ master, main ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up JDK 21
        uses: actions/setup-java@v4
        with:
          java-version: '21'
          distribution: 'temurin'

      - name: Setup Android SDK
        uses: android-actions/setup-android@v3
        with:
          packages: 'platforms;android-36 build-tools;36.0.0 cmake;3.22.1 ndk;27.0.12077973'

      - name: Cache Gradle packages
        uses: actions/cache@v4
        with:
          path: |
            ~/.gradle/caches
            ~/.gradle/wrapper
          key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties') }}
          restore-keys: |
            ${{ runner.os }}-gradle-

      - name: Grant execute permission for gradlew
        run: chmod +x gradlew

      - name: Build Debug APK
        run: ./gradlew assembleDebug --max-workers=2 --stacktrace

      - name: Upload APK Artifact
        uses: actions/upload-artifact@v4
        with:
          name: 3E.V.CAD-Debug-APK
          path: app/build/outputs/apk/debug/*.apk
'@
Write-Utf8NoBom ".github\workflows\build.yml" $workflowYml

Write-Host "`n=== All files, 3E Vector Icon, and App Name (3E.V.CAD) updated successfully! ===" -ForegroundColor Green
Write-Host "Now open GitHub Desktop, Commit, and Push." -ForegroundColor Yellow