//
//  TRHudMainApplicationDelegate.h
//  TrollRecorder
//
//  Created by Lessica on 2024/2/13.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class TRHudAppMonitor;

@protocol TRHudMainApplicationDelegateWindowOrientationProxy <NSObject>
- (void)setWindowOrientation:(UIInterfaceOrientation)windowOrientation;
@end

@protocol TRHudScreenshotInvisibleProxy <NSObject>
- (void)setScreenshotInvisible:(BOOL)screenshotInvisible;
@end

@interface TRHudMainApplicationDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, assign) UIInterfaceOrientation windowOrientation;
@property (nonatomic, copy, nullable) NSString *viewControllerClassName;

@property (nonatomic, weak) id<TRHudMainApplicationDelegateWindowOrientationProxy> windowOrientationProxy;
@property (nonatomic, weak) id<TRHudScreenshotInvisibleProxy> screenshotInvisibleProxy;

@property (nonatomic, strong) TRHudAppMonitor *appMonitor;

@property (nonatomic, assign) BOOL shouldHideWhenLandscape; // Default is YES for iPhone, NO for iPad
@property (nonatomic, assign) BOOL shouldHideWhenScreenRecording; // Default is NO
@property (nonatomic, assign) BOOL shouldDisplayOnLockScreen; // Default is NO

@property (nonatomic, assign) UIUserInterfaceStyle customUserInterfaceStyle;
- (void)setCustomUserInterfaceStyle:(UIUserInterfaceStyle)customUserInterfaceStyle animated:(BOOL)animated;

@property (nonatomic, assign, readonly, getter=isVisible) BOOL visible;

@end

NS_ASSUME_NONNULL_END
