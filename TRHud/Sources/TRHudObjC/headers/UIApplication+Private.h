//
//  UIApplication+Private.h
//  FakeTouch
//
//  Created by Watanabe Toshinori on 2/6/19.
//  Copyright © 2019 Watanabe Toshinori. All rights reserved.
//

#import "IOKit+SPI.h"
#import <UIKit/UIKit.h>

@interface UIApplication (Private)

- (UIEvent *)_touchesEvent;
- (void)_run;
- (void)suspend;
- (void)_accessibilityInit;
- (void)terminateWithSuccess;
- (void)__completeAndRunAsPlugin;
- (id)_systemAnimationFenceExemptQueue;
- (void)_enqueueHIDEvent:(IOHIDEventRef)event;
- (BOOL)_isClassic;
- (void)_reloadKeyboardArbiterState;

@end
