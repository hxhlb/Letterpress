#import <QuartzCore/CALayer.h>

FOUNDATION_EXTERN NSString *const kCALayerSecurityModeSecure;

@interface CALayer (Private)

- (NSString *)securityMode;
- (void)setSecurityMode:(NSString *)arg1;

@end
