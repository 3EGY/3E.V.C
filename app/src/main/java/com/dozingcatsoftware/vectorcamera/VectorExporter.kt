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
    val simplifyTolerance: Float = 1.8f,   // تبسيط الخطوط (Douglas-Peucker)
    val minNoiseLengthPx: Float = 12f,     // إزالة الشوائب الأصغر من هذا الطول بالبكسل
    val edgeThreshold: Int = 150,          // حساسية اكتشاف الحواف (40 - 255)
    val snapBaseAngle: Float = 90f,        // زاوية الأساس للتقريب (مثلاً 90 أو 45)
    val snapToleranceDeg: Float = 8f,      // مجال التسامح بالدرجات لتقريب الزاوية (0 = معطل)
    val smartLayers: Boolean = true        // تقسيم تلقائي لطبقات الحوائط والأبواب والتفاصيل
)

enum class CadLayer(val dxfName: String, val aciColor: Int, val previewColor: Int) {
    WALLS("3E_WALLS", 7, Color.parseColor("#FFFFFF")),          // أبيض - حوائط وحدود رئيسية
    OPENINGS("3E_OPENINGS", 4, Color.parseColor("#00E5FF")),    // سماوي - أبواب ونوافذ
    DETAILS("3E_DETAILS", 3, Color.parseColor("#76FF03")),      // أخضر - تفاصيل وعناصر
    SINGLE("3E_VECTOR", 7, Color.parseColor("#00E5FF"))         // طبقة موحدة
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

    /**
     * يستخرج المشهد المتجهي وفق الإعدادات الحية للمعاينة أو التصدير
     */
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

                // 1. تبسيط الخطوط
                var pts = ramerDouglasPeucker(chain, settings.simplifyTolerance * invScale)
                if (pts.size < 2) continue

                // 2. تقريب الزوايا لأقرب مضاعف لزاوية الأساس (Ortho / Angle Snap)
                if (settings.snapToleranceDeg > 0.1f && settings.snapBaseAngle > 1f) {
                    pts = snapAngles(pts, settings.snapBaseAngle, settings.snapToleranceDeg)
                }

                // 3. حساب الطول الكلي واستبعاد الشوائب
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

    /**
     * تقريب اتجاه كل قطعة مستقيمة لأقرب مضاعف للزاوية المحددة (مثلاً 90 درجة)
     */
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
                // الحفاظ على الإزاحة النسبية للخطوط المائلة خارج نطاق التقريب
                val dx = currOrig.x - prevOrig.x
                val dy = currOrig.y - prevOrig.y
                out.add(Point2D(prevNew.x + dx, prevNew.y + dy))
            }
        }
        return out
    }

    /**
     * تصنيف الخط هندسياً إلى طبقات الحوائط أو الفتحات (أبواب/نوافذ) أو التفاصيل
     */
    private fun classifyLayer(
        pts: List<Point2D>,
        length: Float,
        isClosed: Boolean,
        diagRef: Float,
        smartLayers: Boolean
    ): CadLayer {
        if (!smartLayers) return CadLayer.SINGLE

        // فحص هل الخط مستطيل/فتحة مغلقة متوسطة الحجم (أبواب / شبابيك)
        if (isClosed && pts.size in 4..7 && length in (diagRef * 0.04f)..(diagRef * 0.35f)) {
            return CadLayer.OPENINGS
        }

        // الخطوط الطويلة الممتدة تمثل الحوائط والحدود المعمارية الرئيسية
        if (length >= diagRef * 0.14f) {
            return CadLayer.WALLS
        }

        // الفتحات المفتوحة المتعامدة المتوسطة
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

            // تعريف الطبقات الذكية وألوانها في جدول الطبقات
            val usedLayers = scene.polylines.map { it.layer }.distinct().ifEmpty { listOf(CadLayer.SINGLE) }
            writer.write("0\nSECTION\n2\nTABLES\n0\nTABLE\n2\nLAYER\n70\n${usedLayers.size}\n")
            for (layer in usedLayers) {
                writer.write("0\nLAYER\n2\n${layer.dxfName}\n70\n0\n62\n${layer.aciColor}\n6\nCONTINUOUS\n")
            }
            writer.write("0\nENDTAB\n0\nENDSEC\n")

            // كتابة الكيانات كلٌ في طبقته
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