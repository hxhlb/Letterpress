#import <UIKit/UIKit.h>

@interface _UIKeyboardChangedInformation : NSObject

- (BOOL)keyboardOnScreen;
- (CGRect)keyboardPosition;
- (UIInterfaceOrientation)orientation;

@end
