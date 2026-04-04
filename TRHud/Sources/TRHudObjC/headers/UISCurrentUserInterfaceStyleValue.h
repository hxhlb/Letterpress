#import <UIKit/UIKit.h>

@interface UISCurrentUserInterfaceStyleValue : NSObject
@property(nonatomic, readonly) UIUserInterfaceStyle userInterfaceStyle;
- (UIUserInterfaceStyle)userInterfaceStyle;
- (instancetype)initWithChangesDeliveredOnQueue:(dispatch_queue_t)arg1 toBlock:(void (^)(id))arg2;
@end
