#import "QuickjsDartPlugin.h"
#if __has_include(<quickjs_dart/quickjs_dart-Swift.h>)
#import <quickjs_dart/quickjs_dart-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "quickjs_dart-Swift.h"
#endif

@implementation QuickjsDartPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftQuickjsDartPlugin registerWithRegistrar:registrar];
}
@end
