#import <UIKit/UIKit.h>

@interface UIDevice (Private)

+ (BOOL)_hasHomeButton;
- (void)setOrientation:(UIDeviceOrientation)orientation animated:(BOOL)animated;

@end
