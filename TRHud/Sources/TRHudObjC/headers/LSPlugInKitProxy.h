#ifndef LSPlugInKitProxy_h
#define LSPlugInKitProxy_h

#import <Foundation/Foundation.h>

@interface LSPlugInKitProxy : NSObject

+ (instancetype)pluginKitProxyForIdentifier:(NSString *)identifier;
+ (instancetype)pluginKitProxyForURL:(NSURL *)url;

- (NSURL *)bundleURL;
- (NSURL *)containerURL;
- (NSURL *)dataContainerURL;
- (NSURL *)bundleContainerURL;

@property(nonatomic, readonly) NSDictionary *infoPlist;
@property(nonatomic, readonly) NSString *pluginIdentifier;
@property(nonatomic, readonly) NSString *originalIdentifier;

@property(nonatomic, readonly) NSUUID *pluginUUID;
@property(nonatomic, readonly) NSString *protocol;
@property(nonatomic, readonly) NSDate *registrationDate;
@property(nonatomic, readonly) NSString *teamID;

@end

#endif /* LSPlugInKitProxy_h */
