package com.sample.edgedetection.processor

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import org.opencv.android.OpenCVLoader
import org.opencv.android.Utils
import org.opencv.core.Mat
import java.io.ByteArrayOutputStream

/**
 * Processor for auto-cropping image bytes without saving to disk.
 * Converts Uint8List (ByteArray) to Bitmap, detects document edges, crops the image,
 * and returns the cropped image as Uint8List (ByteArray).
 */
fun autoCropImageBytes(imageBytes: ByteArray, jpegQuality: Int = 95): ByteArray? {
    return try {
        // 0. Ensure OpenCV is loaded
        if (!OpenCVLoader.initDebug()) {
            Log.e(TAG, "Unable to load OpenCV")
            throw Exception("OpenCV library failed to load")
        }

        // 1. Convert bytes to Bitmap
        val originalBitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
            ?: throw Exception("Failed to decode image bytes")

        // 2. Convert Bitmap to Mat
        val originalMat = Mat()
        Utils.bitmapToMat(originalBitmap, originalMat)

        // 3. Detect corners/contours using existing PaperProcessor
        val corners = processPicture(originalMat)
            ?: throw Exception("Could not detect document edges")

        // 4. Crop the picture using detected corners
        val croppedMat = cropPicture(originalMat, corners.corners.filterNotNull())

        // 5. Convert cropped Mat back to Bitmap
        val croppedBitmap = Bitmap.createBitmap(
            croppedMat.cols(),
            croppedMat.rows(),
            Bitmap.Config.ARGB_8888
        )
        Utils.matToBitmap(croppedMat, croppedBitmap)

        // 6. Convert Bitmap to byte array (JPEG format)
        val outputStream = ByteArrayOutputStream()
        croppedBitmap.compress(Bitmap.CompressFormat.JPEG, jpegQuality, outputStream)
        val resultBytes = outputStream.toByteArray()

        // 7. Clean up resources
        originalMat.release()
        croppedMat.release()
        originalBitmap.recycle()
        croppedBitmap.recycle()
        outputStream.close()

        Log.i(TAG, "autoCropImageBytes completed successfully")
        resultBytes

    } catch (e: Exception) {
        Log.e(TAG, "Error in autoCropImageBytes: ${e.message}", e)
        null
    }
}
