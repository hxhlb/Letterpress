#ifndef LSApplicationProxy_h
#define LSApplicationProxy_h

#import <Foundation/Foundation.h>

@class LSPlugInKitProxy;

@interface LSApplicationProxy : NSObject

+ (LSApplicationProxy *)applicationProxyForIdentifier:(NSString *)bundleIdentifier;
- (NSString *)applicationIdentifier;
- (NSString *)localizedName;
- (NSString *)shortVersionString;
- (NSString *)applicationType;
- (NSURL *)bundleURL;
- (NSURL *)dataContainerURL;
- (NSURL *)bundleContainerURL;
- (NSDictionary<NSString *, NSURL *> *)groupContainerURLs;
- (NSDictionary *)entitlements;
- (NSArray<LSPlugInKitProxy *> *)plugInKitPlugins;
- (id)correspondingApplicationRecord;

@end

#endif /* LSApplicationProxy_h */
