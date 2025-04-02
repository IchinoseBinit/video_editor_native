import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'video_editor_native_method_channel.dart';

abstract class VideoEditorNativePlatform extends PlatformInterface {
  /// Constructs a VideoEditorNativePlatform.
  VideoEditorNativePlatform() : super(token: _token);

  static final Object _token = Object();

  static VideoEditorNativePlatform _instance = MethodChannelVideoEditorNative();

  /// The default instance of [VideoEditorNativePlatform] to use.
  ///
  /// Defaults to [MethodChannelVideoEditorNative].
  static VideoEditorNativePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [VideoEditorNativePlatform] when
  /// they register themselves.
  static set instance(VideoEditorNativePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
