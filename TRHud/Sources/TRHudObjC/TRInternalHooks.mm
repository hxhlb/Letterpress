//
//  TRInternalHooks.h
//  TRHud
//
//  Created by 82Flex on 2024/12/17.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#import "UIDevice+Private.h"
#import "UIKeyboardImpl.h"
#import "_UIKeyboardChangedInformation.h"

OBJC_EXTERN UIUserInterfaceIdiom UIKeyboardGetSafeDeviceIdiom(void);

@interface TRInternalHooks : NSObject
@end

@implementation TRInternalHooks

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        BOOL isHud = [[[NSProcessInfo processInfo] arguments] containsObject:@"-hud"];

        if (isHud) {
            Class cls = NSClassFromString(@"_UIKeyboardChangedInformation");

            {
                SEL originalSelector = @selector(sourceBundleIdentifier);
                SEL swizzledSelector = @selector(tr_sourceBundleIdentifier);

                Method originalMethod = class_getInstanceMethod(cls, originalSelector);
                Method swizzledMethod = class_getInstanceMethod([self class], swizzledSelector);

                IMP originalImp = method_getImplementation(originalMethod);
                IMP swizzledImp = method_getImplementation(swizzledMethod);

                class_replaceMethod(cls, swizzledSelector, originalImp, method_getTypeEncoding(originalMethod));
                class_replaceMethod(cls, originalSelector, swizzledImp, method_getTypeEncoding(swizzledMethod));
            }
        }

        if (isHud) {
            Class cls = NSClassFromString(@"_UIRemoteKeyboards");

            {
                SEL originalSelector = @selector(didHandleKeyboardChange:shouldConsiderSnapshottingKeyboard:isLocalEvent:);
                SEL swizzledSelector = @selector(tr_didHandleKeyboardChange:shouldConsiderSnapshottingKeyboard:isLocalEvent:);

                Method originalMethod = class_getInstanceMethod(cls, originalSelector);
                Method swizzledMethod = class_getInstanceMethod([self class], swizzledSelector);

                IMP originalImp = method_getImplementation(originalMethod);
                IMP swizzledImp = method_getImplementation(swizzledMethod);

                class_replaceMethod(cls, swizzledSelector, originalImp, method_getTypeEncoding(originalMethod));
                class_replaceMethod(cls, originalSelector, swizzledImp, method_getTypeEncoding(swizzledMethod));
            }

            {
                SEL originalSelector = @selector(allowedToShowKeyboard);
                SEL swizzledSelector = @selector(tr_allowedToShowKeyboard);

                Method originalMethod = class_getInstanceMethod(cls, originalSelector);
                Method swizzledMethod = class_getInstanceMethod([self class], swizzledSelector);

                IMP originalImp = method_getImplementation(originalMethod);
                IMP swizzledImp = method_getImplementation(swizzledMethod);

                class_replaceMethod(cls, swizzledSelector, originalImp, method_getTypeEncoding(originalMethod));
                class_replaceMethod(cls, originalSelector, swizzledImp, method_getTypeEncoding(swizzledMethod));
            }
        }
    });
}

- (BOOL)tr_allowedToShowKeyboard {
    return YES;
}

- (NSString *)tr_sourceBundleIdentifier {
    return @"com.apple.Spotlight";
}

- (BOOL)tr_didHandleKeyboardChange:(_UIKeyboardChangedInformation *)currentState
shouldConsiderSnapshottingKeyboard:(BOOL)arg2
                      isLocalEvent:(BOOL)isLocal
{
    if (!isLocal) {

        BOOL isPhone = (UIKeyboardGetSafeDeviceIdiom() == UIUserInterfaceIdiomPhone);

        if (isPhone) {

            CGFloat screenHeight = CGRectGetHeight([[[UIScreen mainScreen] fixedCoordinateSpace] bounds]);
            UIInterfaceOrientation interfaceOrientation = UIInterfaceOrientationPortrait;
            if ([currentState respondsToSelector:@selector(orientation)]) {
                interfaceOrientation = [currentState orientation];
            }

            UIEdgeInsets deviceInsets = UIEdgeInsetsZero;
            if (interfaceOrientation == UIInterfaceOrientationPortrait && ![UIDevice _hasHomeButton]) {
                deviceInsets = [UIKeyboardImpl deviceSpecificPaddingForInterfaceOrientation:interfaceOrientation inputMode:@""];
                deviceInsets.bottom -= 17.0;  // 17.0 is the height of the home indicator
            }

            CGRect endFrame = currentState.keyboardPosition;
            if (deviceInsets.bottom > 0) {
                endFrame.size.height += deviceInsets.bottom;
            }

            if ([currentState keyboardOnScreen]) {
                endFrame.origin.y = screenHeight - CGRectGetHeight(endFrame);
            } else {
                endFrame = CGRectMake(0, screenHeight, 0, 0);
            }

            NSDictionary *userInfo = @{
                UIKeyboardFrameEndUserInfoKey: [NSValue valueWithCGRect:endFrame],
                UIKeyboardAnimationDurationUserInfoKey: @(0.25),
                UIKeyboardIsLocalUserInfoKey: @(isLocal),
            };

            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:UIKeyboardDidChangeFrameNotification object:nil userInfo:userInfo];
            });
        }
    }

    return [self tr_didHandleKeyboardChange:currentState shouldConsiderSnapshottingKeyboard:arg2 isLocalEvent:isLocal];
}

@end
