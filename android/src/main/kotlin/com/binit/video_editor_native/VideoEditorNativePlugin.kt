package com.binit.video_editor_native

import android.graphics.BitmapFactory
import android.util.Log
import androidx.annotation.NonNull
import com.daasuu.mp4compose.composer.Mp4Composer
import com.daasuu.mp4compose.filter.GlFilter
import com.daasuu.mp4compose.filter.GlFlipHorizontalFilter
import com.daasuu.mp4compose.filter.GlWatermarkFilter
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class VideoEditorNativePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: android.content.Context

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "video_editor_native")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "applyWatermark" -> {
                val videoPath = call.argument<String>("videoPath")
                val watermarkPath = call.argument<String>("watermarkPath")
                if (videoPath != null && watermarkPath != null) {
                    applyWatermark(videoPath, watermarkPath, result)
                } else {
                    result.error("INVALID_ARGUMENTS", "Missing videoPath or watermarkPath", null)
                }
            }

            "flipVideo" -> {
                val videoPath = call.argument<String>("videoPath")
                if (videoPath != null) {
                    flipVideo(videoPath, result)
                } else {
                    result.error("INVALID_ARGUMENTS", "Missing videoPath", null)
                }
            }

            "trimVideo" -> {
                val videoPath = call.argument<String>("videoPath")
                val startTimeMs = call.argument<Int>("startTimeMs") ?: 0
                val endTimeMs = call.argument<Int>("endTimeMs") ?: 0
                if (videoPath != null && endTimeMs > startTimeMs) {
                    trimVideo(videoPath, startTimeMs, endTimeMs, result)
                } else {
                    result.error("INVALID_ARGUMENTS", "Invalid trim times", null)
                }
            }

            else -> result.notImplemented()
        }
    }

    private fun applyWatermark(videoPath: String, watermarkPath: String, result: MethodChannel.Result) {
        val outputPath = "${context.cacheDir}/output_watermarked.mp4"
        val bitmap = BitmapFactory.decodeFile(watermarkPath)

        Mp4Composer(videoPath, outputPath)
            .filter(GlWatermarkFilter(bitmap))
            .listener(object : Mp4Composer.Listener {
                override fun onCompleted() {
                    result.success(outputPath)
                }

                override fun onFailed(exception: java.lang.Exception) {
                    result.error("WATERMARK_FAILED", exception.message, null)
                }

                override fun onProgress(progress: Double) {
                    Log.d("Mp4Composer", "Progress: $progress")
                }

                override fun onCanceled() {}
            }).start()
    }

    private fun flipVideo(videoPath: String, result: MethodChannel.Result) {
        val outputPath = "${context.cacheDir}/output_flipped.mp4"

        Mp4Composer(videoPath, outputPath)
            .filter(GlFlipHorizontalFilter())
            .listener(object : Mp4Composer.Listener {
                override fun onCompleted() {
                    result.success(outputPath)
                }

                override fun onFailed(exception: java.lang.Exception) {
                    result.error("FLIP_FAILED", exception.message, null)
                }

                override fun onProgress(progress: Double) {
                    Log.d("Mp4Composer", "Progress: $progress")
                }

                override fun onCanceled() {}
            }).start()
    }

    private fun trimVideo(videoPath: String, startTimeMs: Int, endTimeMs: Int, result: MethodChannel.Result) {
        val outputPath = "${context.cacheDir}/output_trimmed.mp4"

        Mp4Composer(videoPath, outputPath)
            .setTrim(startTimeMs.toLong(), endTimeMs.toLong())
            .listener(object : Mp4Composer.Listener {
                override fun onCompleted() {
                    result.success(outputPath)
                }

                override fun onFailed(exception: java.lang.Exception) {
                    result.error("TRIM_FAILED", exception.message, null)
                }

                override fun onProgress(progress: Double) {
                    Log.d("Mp4Composer", "Progress: $progress")
                }

                override fun onCanceled() {}
            }).start()
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
