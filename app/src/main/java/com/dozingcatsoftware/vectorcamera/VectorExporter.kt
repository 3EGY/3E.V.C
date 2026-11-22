package com.dozingcatsoftware.vectorcamera

import android.graphics.Bitmap
import android.graphics.Color
import java.io.BufferedWriter
import java.io.OutputStream
import java.io.OutputStreamWriter
import kotlin.math.abs
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min

/**
 * Converts a ProcessedBitmap into clean vector polylines and exports to DXF (CAD) or SVG.
 */
object VectorExporter {

    data class Point2D(val x: Float, val y: Float)

    fun writeDxf(pb: ProcessedBitmap, outputStream: OutputStream, simplifyTolerance: Float = 1.6f) {
        val bitmap = pb.renderBitmap(pb.sourceImage.width(), pb.sourceImage.height())
        val (polylines, width, height) = extractPolylines(bitmap, simplifyTolerance)
        bitmap.recycle()

        BufferedWriter(OutputStreamWriter(outputStream, Charsets.UTF_8)).use { writer ->
            // DXF Header
            writer.write("0\nSECTION\n2\nHEADER\n")
            writer.write("9\n\$ACADVER\n1\nAC1009\n")
            writer.write("9\n\$INSUNITS\n70\n4\n") // Millimeters
            writer.write("9\n\$EXTMIN\n10\n0.0\n20\n0.0\n30\n0.0\n")
            writer.write("9\n\$EXTMAX\n10\n${width.toFloat()}\n20\n${height.toFloat()}\n30\n0.0\n")
            writer.write("0\nENDSEC\n")

            // Tables / Layers
            writer.write("0\nSECTION\n2\nTABLES\n0\nTABLE\n2\nLAYER\n70\n1\n")
            writer.write("0\nLAYER\n2\n3E_VECTOR\n70\n0\n62\n7\n6\nCONTINUOUS\n")
            writer.write("0\nENDTAB\n0\nENDSEC\n")

            // Entities (POLYLINE + VERTEX for universal CAD compatibility)
            writer.write("0\nSECTION\n2\nENTITIES\n")
            for (poly in polylines) {
                if (poly.size < 2) continue
                val isClosed = poly.size > 3 &&
                        hypot((poly.first().x - poly.last().x).toDouble(),
                              (poly.first().y - poly.last().y).toDouble()) <= 2.0
                writer.write("0\nPOLYLINE\n8\n3E_VECTOR\n66\n1\n")
                writer.write("10\n0.0\n20\n0.0\n30\n0.0\n")
                writer.write("70\n${if (isClosed) 1 else 0}\n")

                val limit = if (isClosed) poly.size - 1 else poly.size
                for (i in 0 until limit) {
                    val pt = poly[i]
                    // Flip Y axis so (0,0) is bottom-left in CAD space
                    val cadY = height - pt.y
                    writer.write("0\nVERTEX\n8\n3E_VECTOR\n")
                    writer.write("10\n${"%.2f".format(java.util.Locale.US, pt.x)}\n")
                    writer.write("20\n${"%.2f".format(java.util.Locale.US, cadY)}\n")
                    writer.write("30\n0.0\n")
                }
                writer.write("0\nSEQEND\n")
            }
            writer.write("0\nENDSEC\n0\nEOF\n")
        }
    }

    fun writeSvg(pb: ProcessedBitmap, outputStream: OutputStream, simplifyTolerance: Float = 1.4f) {
        val bitmap = pb.renderBitmap(pb.sourceImage.width(), pb.sourceImage.height())
        val (polylines, width, height) = extractPolylines(bitmap, simplifyTolerance)
        bitmap.recycle()

        BufferedWriter(OutputStreamWriter(outputStream, Charsets.UTF_8)).use { writer ->
            writer.write("""<?xml version="1.0" encoding="UTF-8"?>""" + "\n")
            writer.write(
                """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $width $height" width="$width" height="$height">""" + "\n"
            )
            writer.write("""  <g id="3E_VECTOR" fill="none" stroke="#000000" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round">""" + "\n")

            for (poly in polylines) {
                if (poly.size < 2) continue
                val sb = StringBuilder("    <path d=\"")
                for (i in poly.indices) {
                    val pt = poly[i]
                    val cmd = if (i == 0) "M" else "L"
                    sb.append("$cmd${"%.1f".format(java.util.Locale.US, pt.x)},${"%.1f".format(java.util.Locale.US, pt.y)} ")
                }
                sb.append("\" />\n")
                writer.write(sb.toString())
            }

            writer.write("  </g>\n</svg>\n")
        }
    }

    private fun extractPolylines(
        src: Bitmap,
        simplifyTolerance: Float
    ): Triple<List<List<Point2D>>, Int, Int> {
        // Downscale very large images to keep CAD vector files fast, clean, and responsive
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
        for (i in pixels.indices) {
            val c = pixels[i]
            val y = (77 * Color.red(c) + 150 * Color.green(c) + 29 * Color.blue(c)) shr 8
            luma[i] = y
            sumLuma += y
        }
        val avgLuma = (sumLuma / max(1, pixels.size)).toInt()

        // Build binary edge map:
        // If image is already mostly high-contrast edge/wireframe (very dark or very bright background),
        // threshold directly; otherwise run Sobel gradient edge detection.
        val edge = BooleanArray(w * h)
        var extremeCount = 0
        for (y in luma) {
            if (y < 30 || y > 225) extremeCount++
        }
        val isLineArt = extremeCount > (pixels.size * 0.72)

        if (isLineArt) {
            val darkBackground = avgLuma < 128
            for (i in luma.indices) {
                edge[i] = if (darkBackground) luma[i] > 75 else luma[i] < 180
            }
        } else {
            for (y in 1 until h - 1) {
                val row = y * w
                for (x in 1 until w - 1) {
                    val idx = row + x
                    val gx = -luma[idx - w - 1] + luma[idx - w + 1] -
                            2 * luma[idx - 1] + 2 * luma[idx + 1] -
                            luma[idx + w - 1] + luma[idx + w + 1]
                    val gy = -luma[idx - w - 1] - 2 * luma[idx - w] - luma[idx - w + 1] +
                            luma[idx + w - 1] + 2 * luma[idx + w] + luma[idx + w + 1]
                    if (abs(gx) + abs(gy) > 160) {
                        edge[idx] = true
                    }
                }
            }
        }

        // 8-neighbor contour tracing
        val visited = BooleanArray(w * h)
        val dx = intArrayOf(1, 1, 0, -1, -1, -1, 0, 1)
        val dy = intArrayOf(0, 1, 1, 1, 0, -1, -1, -1)
        val invScale = 1f / scale
        val result = ArrayList<List<Point2D>>()

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

                // Filter tiny noise specks (< 5 pixels) and simplify geometry
                if (chain.size >= 5) {
                    val simplified = ramerDouglasPeucker(chain, simplifyTolerance * invScale)
                    if (simplified.size >= 2) {
                        result.add(simplified)
                    }
                }
            }
        }

        return Triple(result, src.width, src.height)
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