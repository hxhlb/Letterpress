#import <UIKit/UIKit.h>

#import "_UIKeyboardChangedInformation.h"

@interface _UIRemoteKeyboards : NSObject

+ (instancetype)sharedRemoteKeyboards;
- (BOOL)keyboardVisible;

- (_UIKeyboardChangedInformation *)currentState;
- (void)updateCurrentState:(_UIKeyboardChangedInformation *)currentState;

@end
