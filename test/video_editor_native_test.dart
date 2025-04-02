import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_native/video_editor_native.dart';
import 'package:video_editor_native/video_editor_native_platform_interface.dart';
import 'package:video_editor_native/video_editor_native_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockVideoEditorNativePlatform
    with MockPlatformInterfaceMixin
    implements VideoEditorNativePlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final VideoEditorNativePlatform initialPlatform = VideoEditorNativePlatform.instance;

  test('$MethodChannelVideoEditorNative is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelVideoEditorNative>());
  });

}
