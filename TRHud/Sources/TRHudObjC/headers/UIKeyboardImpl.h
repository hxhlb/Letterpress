#import <UIKit/UIKit.h>

@interface UIKeyboardImpl : NSObject

+ (UIEdgeInsets)deviceSpecificPaddingForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation inputMode:(NSString *)inputMode;

@end
