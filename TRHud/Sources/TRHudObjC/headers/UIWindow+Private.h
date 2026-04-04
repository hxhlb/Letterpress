#import <UIKit/UIKit.h>

#import "CAContext+Private.h"

@interface UIWindow (Private)
- (CAContext *)_boundContext;
- (unsigned int)_contextId;
@end
