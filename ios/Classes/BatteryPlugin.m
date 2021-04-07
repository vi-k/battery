#import "BatteryPlugin.h"
#if __has_include(<battery/battery-Swift.h>)
#import <battery/battery-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "battery-Swift.h"
#endif

@implementation BatteryPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftBatteryPlugin registerWithRegistrar:registrar];
}
@end
