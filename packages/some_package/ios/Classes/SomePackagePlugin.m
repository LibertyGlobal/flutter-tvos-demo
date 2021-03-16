#import "SomePackagePlugin.h"
#if __has_include(<some_package/some_package-Swift.h>)
#import <some_package/some_package-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "some_package-Swift.h"
#endif

@implementation SomePackagePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftSomePackagePlugin registerWithRegistrar:registrar];
}
@end
