import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

class VideoEditorNative {
  static const MethodChannel _channel = MethodChannel('video_editor_native');

  static Future<File?> applyWatermark({
    required String videoPath,
    required String watermarkPath,
  }) async {
    final String? outputPath = await _channel.invokeMethod('applyWatermark', {
      'videoPath': videoPath,
      'watermarkPath': watermarkPath,
    });
    return outputPath != null ? File(outputPath) : null;
  }

  static Future<File?> flipVideo(String videoPath) async {
    final String? outputPath = await _channel.invokeMethod('flipVideo', {
      'videoPath': videoPath,
    });
    return outputPath != null ? File(outputPath) : null;
  }

  static Future<File?> trimVideo({
    required String videoPath,
    required int startTimeMs,
    required int endTimeMs,
  }) async {
    final String? outputPath = await _channel.invokeMethod('trimVideo', {
      'videoPath': videoPath,
      'startTimeMs': startTimeMs,
      'endTimeMs': endTimeMs,
    });
    return outputPath != null ? File(outputPath) : null;
  }
}
