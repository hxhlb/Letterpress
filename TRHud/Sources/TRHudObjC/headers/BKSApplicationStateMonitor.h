#import <Foundation/Foundation.h>

@interface BKSApplicationStateMonitor : NSObject

- (void)setHandler:(void (^)(NSDictionary *))arg1;
- (void)invalidate;

@end