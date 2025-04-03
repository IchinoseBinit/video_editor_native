package com.binit.video_editor_native

import android.os.Handler
import android.os.Looper
import android.graphics.BitmapFactory
import android.util.Log
import androidx.annotation.NonNull
import com.daasuu.mp4compose.composer.Mp4Composer
import com.daasuu.mp4compose.filter.GlWatermarkFilter
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class VideoEditorNativePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var progressChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private lateinit var context: android.content.Context

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext

        channel = MethodChannel(binding.binaryMessenger, "video_editor_native")
        channel.setMethodCallHandler(this)

        progressChannel = EventChannel(binding.binaryMessenger, "video_editor_native_progress")
        progressChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                eventSink = sink
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "applyWatermark" -> {
                val videoPath = call.argument<String>("videoPath")
                val watermarkPath = call.argument<String>("watermarkPath")
                if (!videoPath.isNullOrEmpty() && !watermarkPath.isNullOrEmpty()) {
                    applyWatermark(videoPath, watermarkPath, result)
                } else {
                    Handler(Looper.getMainLooper()).post {  
                        result.error("INVALID_ARGUMENTS", "Missing videoPath or watermarkPath", null)
                    }
                }
            }

            "flipVideo" -> {
                val videoPath = call.argument<String>("videoPath")
                if (!videoPath.isNullOrEmpty()) {
                    flipVideo(videoPath, result)
                } else {
                    Handler(Looper.getMainLooper()).post {  
                        result.error("INVALID_ARGUMENTS", "Missing videoPath", null)
                    }
                }
            }

            "trimVideo" -> {
                val videoPath = call.argument<String>("videoPath")
                val startTimeMs = call.argument<Int>("startTimeMs") ?: 0
                val endTimeMs = call.argument<Int>("endTimeMs") ?: 0
                if (!videoPath.isNullOrEmpty() && endTimeMs > startTimeMs) {
                    trimVideo(videoPath, startTimeMs, endTimeMs, result)
                } else {
                    Handler(Looper.getMainLooper()).post {  
                        result.error("INVALID_ARGUMENTS", "Invalid trim times or missing videoPath", null)
                    }
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
                    Handler(Looper.getMainLooper()).post {  
                        result.success(outputPath)
                    }
                }

                override fun onFailed(exception: Exception) {
                    Handler(Looper.getMainLooper()).post {  
                        result.error("WATERMARK_FAILED", exception.message, null)
                    }
                }

                override fun onProgress(progress: Double) {
                    Log.d("Mp4Composer", "applyWatermark Progress: $progress")
                    Handler(Looper.getMainLooper()).post {  
                        eventSink?.success(progress)
                    }
                }

                override fun onCanceled() {
                    Log.d("Mp4Composer", "applyWatermark Canceled")
                }
            }).start()
    }

    private fun flipVideo(videoPath: String, result: MethodChannel.Result) {
        val outputPath = "${context.cacheDir}/output_flipped.mp4"

        Mp4Composer(videoPath, outputPath)
            .flipHorizontal(true)
            .listener(object : Mp4Composer.Listener {
                override fun onCompleted() {
                    Handler(Looper.getMainLooper()).post {  
                        result.success(outputPath)
                    }
                }

                override fun onFailed(exception: Exception) {
                    Handler(Looper.getMainLooper()).post {  
                        result.error("FLIP_FAILED", exception.message, null)
                    }
                }

                override fun onProgress(progress: Double) {
                    Log.d("Mp4Composer", "flipVideo Progress: $progress")
                    Handler(Looper.getMainLooper()).post {  
                        eventSink?.success(progress)
                    }
                }

                override fun onCanceled() {
                    Log.d("Mp4Composer", "flipVideo Canceled")
                }
            }).start()
    }

    private fun trimVideo(videoPath: String, startTimeMs: Int, endTimeMs: Int, result: MethodChannel.Result) {
        val outputPath = "${context.cacheDir}/output_trimmed.mp4"

        Mp4Composer(videoPath, outputPath)
            .trim(startTimeMs.toLong(), endTimeMs.toLong())
            .listener(object : Mp4Composer.Listener {
                override fun onCompleted() {
                    Handler(Looper.getMainLooper()).post {  
                        result.success(outputPath)
                    }
                }

                override fun onFailed(exception: Exception) {
                    Handler(Looper.getMainLooper()).post {  
                        result.error("TRIM_FAILED", exception.message, null)
                    }
                }

                override fun onProgress(progress: Double) {
                    Log.d("Mp4Composer", "trimVideo Progress: $progress")
                    Handler(Looper.getMainLooper()).post {  
                        eventSink?.success(progress)
                    }
                }

                override fun onCanceled() {
                    Log.d("Mp4Composer", "trimVideo Canceled")
                }
            }).start()
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventSink = null
    }
}
