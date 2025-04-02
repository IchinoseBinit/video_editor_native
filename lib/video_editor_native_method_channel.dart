import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'video_editor_native_platform_interface.dart';

/// An implementation of [VideoEditorNativePlatform] that uses method channels.
class MethodChannelVideoEditorNative extends VideoEditorNativePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('video_editor_native');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
