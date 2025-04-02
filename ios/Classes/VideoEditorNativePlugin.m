#if __has_include(<video_editor_native/video_editor_native-Swift.h>)
#import <video_editor_native/video_editor_native-Swift.h>
#else
#import "video_editor_native-Swift.h"
#endif
@interface VideoEditorNativePlugin : NSObject<FlutterPlugin>
@end

@implementation VideoEditorNativePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftVideoEditorNativePlugin registerWithRegistrar:registrar];
}
@end
