#import "SoterFlutterBluePlugin.h"
#if __has_include(<soter_flutter_blue/soter_flutter_blue-Swift.h>)
#import <soter_flutter_blue/soter_flutter_blue-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "soter_flutter_blue-Swift.h"
#endif

@implementation SoterFlutterBluePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftSoterFlutterBluePlugin registerWithRegistrar:registrar];
}
@end
