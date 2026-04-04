//
//  TRHudMainApplicationDelegate.mm
//  TrollRecorder
//
//  Created by Lessica on 2024/2/13.
//

#import "TREventFetcher.h"
#import "TRHudAppMonitor+Private.h"
#import "TRHudDefines.h"
#import "TRHudMainApplicationDelegate.h"
#import "TRHudMainWindow.h"
#import "TRHudObjC.h"
#import "TRLogger.h"
#import "TRSystemUserDefaults.h"

#import <notify.h>
#import <objc/runtime.h>

#import "FBSOrientationObserver.h"
#import "FBSOrientationUpdate.h"
#import "LSApplicationProxy.h"
#import "LSApplicationWorkspace.h"
#import "MobileKeyBag.h"
#import "SBSAccessibilityWindowHostingController.h"
#import "SpringBoardServices.h"
#import "UIApplication+Private.h"
#import "UISCurrentUserInterfaceStyleValue.h"
#import "UIDevice+Private.h"
#import "UIWindow+Private.h"

#define NOTIFY_LS_APP_CHANGED    "com.apple.LaunchServices.ApplicationsChanged"
#define NOTIFY_UI_LOCKSTATE      "com.apple.springboard.lockstate"
#define NOTIFY_UI_BLANKED_SCREEN "com.apple.springboard.hasBlankedScreen"

LOGGER_WITH_CATEGORY("TRHudMainApplicationDelegate");

@implementation TRHudMainApplicationDelegate {
    FBSOrientationObserver *_orientationObserver;
    TRHudMainWindow *_mainWindow;
    UIViewController *_rootViewController;
    SBSAccessibilityWindowHostingController *_windowHostingController;
    UISCurrentUserInterfaceStyleValue *_userInterfaceStyleValue;
    UIUserInterfaceStyle _customUserInterfaceStyle;
    BOOL _shouldHideWhenLandscape;
    BOOL _shouldHideWhenScreenRecording;
    BOOL _shouldDisplayOnLockScreen;
    BOOL _isScreenDimmed;
    BOOL _isScreenLocked;
    BOOL _isKeychainLocked;
    BOOL _isOrientationPendingUpdate;
    int _lockStateNotificationToken;
    int _screenDimNotificationToken;
}

static void mLaunchServicesApplicationStateChanged(CFNotificationCenterRef center, void *observer,
                                                   CFStringRef name, const void *object,
                                                   CFDictionaryRef userInfo) {
    /* Application installed or uninstalled */
    BOOL isAppInstalled = NO;

    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    for (LSApplicationProxy *app in [[objc_getClass("LSApplicationWorkspace") defaultWorkspace] allApplications]) {
        if ([app.applicationIdentifier isEqualToString:bundleIdentifier]) {
            isAppInstalled = YES;
            break;
        }
    }

    if (!isAppInstalled) {
        UIApplication *app = [UIApplication sharedApplication];
        [app terminateWithSuccess];
    }
}

static BOOL mSpringBoardLockStatus(void) {
    mach_port_t sbsPort = SBSSpringBoardServerPort();

    if (sbsPort == MACH_PORT_NULL) {
        return NO;
    }

    BOOL isLocked = NO;
    BOOL isPasscodeSet = NO;
    SBGetScreenLockStatus(sbsPort, &isLocked, &isPasscodeSet);

    return isLocked;
}

static void mSpringBoardLockStatusChanged(CFNotificationCenterRef center, void *observer, CFStringRef name,
                                          const void *object, CFDictionaryRef userInfo) {
    TRHudMainApplicationDelegate *appDelegate = (__bridge TRHudMainApplicationDelegate *)observer;

    [appDelegate reloadViewVisibilityWithScreenLock];
}

- (instancetype)init {
    if (self = [super init]) {
        _isScreenDimmed = NO;
        _isScreenLocked = NO;
        _isKeychainLocked = NO;

        _shouldHideWhenLandscape = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone;
        _shouldHideWhenScreenRecording = NO;
        _shouldDisplayOnLockScreen = NO;

        NSBundle *mainBundle = [NSBundle mainBundle];

        NSString *bundleIdentifier = [mainBundle bundleIdentifier];
        _appMonitor = [[TRHudAppMonitor alloc] initWithBundleIdentifier:bundleIdentifier];

        _customUserInterfaceStyle = UIUserInterfaceStyleUnspecified;

        log_debug(LLOOGG, "- [TRHudMainApplicationDelegate init]");

        [self setupUserDefaultsObserver];
        [self setupOrientationObserver];
        [self setupScreenDimObserver];
        [self setupScreenLockObserver];
        [self setupKeychainLockObserver];
    }

    return self;
}

- (void)setupUserDefaultsObserver {
    _userInterfaceStyleValue = [[UISCurrentUserInterfaceStyleValue alloc]
                                initWithChangesDeliveredOnQueue:dispatch_get_main_queue()
                                                        toBlock:^(UISCurrentUserInterfaceStyleValue *value) {
        log_debug(LLOOGG, "UISCurrentUserInterfaceStyleValue changed to: %lld",
                  (long long)value.userInterfaceStyle);
        [self reloadUserInterfaceStyleAnimated:YES];
    }];
}

- (void)setupOrientationObserver {
    _orientationObserver = [[objc_getClass("FBSOrientationObserver") alloc] init];

    __weak __typeof(self) weakSelf = self;
    [_orientationObserver setHandler:^(FBSOrientationUpdate *orientationUpdate) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;

        log_info(LLOOGG, "FBSOrientationUpdate: %{public}@", orientationUpdate);

        UIDeviceOrientation deviceOrientation = (UIDeviceOrientation)orientationUpdate.orientation;
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf _reallyNotifyOrientationChanged:deviceOrientation];
        });
    }];
}

- (void)_reallyNotifyOrientationChanged:(UIDeviceOrientation)deviceOrientation {
    CGRect screenBounds = [[[UIScreen mainScreen] fixedCoordinateSpace] bounds];
    BOOL isLandscape = UIDeviceOrientationIsLandscape(deviceOrientation);

    [self setWindowOrientation:(UIInterfaceOrientation)deviceOrientation];
    [self _reallyReloadViewVisibilityAnimated:YES];

    if (_shouldHideWhenLandscape && isLandscape) {
        _isOrientationPendingUpdate = YES;
        return;
    }

    if ([_windowOrientationProxy respondsToSelector:@selector(setWindowOrientation:)]) {
        [_windowOrientationProxy setWindowOrientation:(UIInterfaceOrientation)deviceOrientation];
    }

    [[UIDevice currentDevice] setOrientation:deviceOrientation animated:YES];

    [UIViewController attemptRotationToDeviceOrientation];

    if (isLandscape) {
        _mainWindow.frame = CGRectMake(0, 0, screenBounds.size.height, screenBounds.size.width);
    } else {
        _mainWindow.frame = CGRectMake(0, 0, screenBounds.size.width, screenBounds.size.height);
    }
}

- (void)setupScreenDimObserver {
    __weak __typeof(self) weakSelf = self;
    notify_register_dispatch(NOTIFY_UI_BLANKED_SCREEN,
                             &self->_screenDimNotificationToken, dispatch_get_main_queue(), ^(int token) {
        uint64_t state;
        notify_get_state(token, &state);
        __strong __typeof(weakSelf) strongSelf = weakSelf;

        BOOL isScreenDimmed = (BOOL)state;
        strongSelf->_isScreenDimmed = isScreenDimmed;

        if (isScreenDimmed) {
            log_debug(LLOOGG, "isScreenDimmed NO -> YES");
            dispatch_async(dispatch_get_main_queue(), ^{
                [TREventFetcher resetAllTouches];
            });
        } else {
            log_debug(LLOOGG, "isScreenDimmed YES -> NO");
        }

        [strongSelf _reallyReloadViewVisibilityAnimated:NO];
    });
}

- (void)setupScreenLockObserver {
    CFNotificationCenterRef darwinCenter = CFNotificationCenterGetDarwinNotifyCenter();

    CFNotificationCenterAddObserver(darwinCenter, (__bridge const void *)self,
                                    mLaunchServicesApplicationStateChanged, CFSTR(NOTIFY_LS_APP_CHANGED), NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);

    CFNotificationCenterAddObserver(darwinCenter, (__bridge const void *)self, mSpringBoardLockStatusChanged,
                                    CFSTR(NOTIFY_UI_LOCKSTATE), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}

- (void)setupKeychainLockObserver {
#if !TARGET_IPHONE_SIMULATOR
    __weak __typeof(self) weakSelf = self;
    notify_register_dispatch([(__bridge NSString *)kMobileKeyBagLockStatusNotification UTF8String],
                             &self->_lockStateNotificationToken, dispatch_get_main_queue(), ^(int token) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf reloadViewVisibilityWithKeychainLock];
    });
#endif
}

- (void)dealloc {
    log_debug(LLOOGG, "- [TRHudMainApplicationDelegate dealloc]");

    notify_cancel(self->_lockStateNotificationToken);

    CFNotificationCenterRef darwinCenter = CFNotificationCenterGetDarwinNotifyCenter();

    CFNotificationCenterRemoveObserver(darwinCenter, (__bridge const void *)self, CFSTR(NOTIFY_LS_APP_CHANGED), NULL);
    CFNotificationCenterRemoveObserver(darwinCenter, (__bridge const void *)self, CFSTR(NOTIFY_UI_LOCKSTATE), NULL);
}

- (BOOL)              application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions {
    log_debug(LLOOGG,
              "- [TRHudMainApplicationDelegate application:%{public}@ didFinishLaunchingWithOptions:%{public}@]",
              application, launchOptions);

    _rootViewController = [[NSClassFromString(@"TRHudRootViewController") alloc] init];
    _mainWindow = [[TRHudMainWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    [_mainWindow setClipsToBounds:YES];
    [_mainWindow setRootViewController:_rootViewController];

    [_mainWindow setWindowLevel:10000001.0];
    [_mainWindow setHidden:NO];
    [_mainWindow makeKeyAndVisible];

    self.window = _mainWindow;

    _windowHostingController = [[objc_getClass("SBSAccessibilityWindowHostingController") alloc] init];
    unsigned int _contextId = [_mainWindow _contextId];
    double windowLevel = [_mainWindow windowLevel];
    [[_mainWindow _boundContext] setSecure:YES];

    [self reloadViewVisibility];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    // [_windowHostingController registerWindowWithContextID:_contextId atLevel:windowLevel];
    NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:"v@:Id"];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:_windowHostingController];
    [invocation setSelector:NSSelectorFromString(@"registerWindowWithContextID:atLevel:")];
    [invocation setArgument:&_contextId atIndex:2];
    [invocation setArgument:&windowLevel atIndex:3];
    [invocation invoke];
#pragma clang diagnostic pop

    return YES;
}

- (UIUserInterfaceStyle)customUserInterfaceStyle {
    return _customUserInterfaceStyle;
}

- (void)setCustomUserInterfaceStyle:(UIUserInterfaceStyle)customUserInterfaceStyle {
    [self setCustomUserInterfaceStyle:customUserInterfaceStyle animated:NO];
}

- (void)setCustomUserInterfaceStyle:(UIUserInterfaceStyle)customUserInterfaceStyle animated:(BOOL)animated {
    _customUserInterfaceStyle = customUserInterfaceStyle;
    [self reloadUserInterfaceStyleAnimated:animated];
}

- (void)reloadUserInterfaceStyleAnimated:(BOOL)animated {
    UIUserInterfaceStyle styleOverride = _customUserInterfaceStyle;

    if (styleOverride == UIUserInterfaceStyleUnspecified) {
        styleOverride = _userInterfaceStyleValue.userInterfaceStyle;
    }

    if (animated) {
        [UIView transitionWithView:self->_mainWindow
                          duration:1.0
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
            self->_mainWindow.overrideUserInterfaceStyle = styleOverride;
            self->_rootViewController.view.overrideUserInterfaceStyle = styleOverride;
        } completion:nil];
    } else {
        _mainWindow.overrideUserInterfaceStyle = styleOverride;
        _rootViewController.view.overrideUserInterfaceStyle = styleOverride;
    }
}

- (BOOL)shouldHideWhenLandscape {
    return _shouldHideWhenLandscape;
}

- (void)setShouldHideWhenLandscape:(BOOL)shouldHideWhenLandscape {
    if (_shouldHideWhenLandscape != shouldHideWhenLandscape) {
        _shouldHideWhenLandscape = shouldHideWhenLandscape;

        if (shouldHideWhenLandscape) {
            log_debug(LLOOGG, "shouldHideWhenLandscape NO -> YES");
        } else {
            log_debug(LLOOGG, "shouldHideWhenLandscape YES -> NO");
        }
    }

    if (_isOrientationPendingUpdate) {
        _isOrientationPendingUpdate = NO;
        [self _reallyNotifyOrientationChanged:(UIDeviceOrientation)_windowOrientation];
    } else {
        [self _reallyReloadViewVisibilityAnimated:YES];
    }
}

- (BOOL)shouldHideWhenScreenRecording {
    return _shouldHideWhenScreenRecording;
}

- (void)setShouldHideWhenScreenRecording:(BOOL)shouldHideWhenScreenRecording {
    if (_shouldHideWhenScreenRecording != shouldHideWhenScreenRecording) {
        _shouldHideWhenScreenRecording = shouldHideWhenScreenRecording;

        if (shouldHideWhenScreenRecording) {
            log_debug(LLOOGG, "shouldHideWhenScreenRecording NO -> YES");
        } else {
            log_debug(LLOOGG, "shouldHideWhenScreenRecording YES -> NO");
        }
    }

    [self.screenshotInvisibleProxy setScreenshotInvisible:shouldHideWhenScreenRecording];
}

- (BOOL)shouldDisplayOnLockScreen {
    return _shouldDisplayOnLockScreen;
}

- (void)setShouldDisplayOnLockScreen:(BOOL)shouldDisplayOnLockScreen {
    if (_shouldDisplayOnLockScreen != shouldDisplayOnLockScreen) {
        _shouldDisplayOnLockScreen = shouldDisplayOnLockScreen;

        if (shouldDisplayOnLockScreen) {
            log_debug(LLOOGG, "shouldDisplayOnLockScreen NO -> YES");
        } else {
            log_debug(LLOOGG, "shouldDisplayOnLockScreen YES -> NO");
        }
    }

    [self _reallyReloadViewVisibilityAnimated:NO];
}

- (void)reloadViewVisibilityWithScreenLock {
    BOOL isScreenLocked = mSpringBoardLockStatus();

    if (_isScreenLocked != isScreenLocked) {
        _isScreenLocked = isScreenLocked;

        if (isScreenLocked) {
            log_debug(LLOOGG, "isScreenLocked NO -> YES");
            dispatch_async(dispatch_get_main_queue(), ^{
                [TREventFetcher resetAllTouches];
            });
        } else {
            // Assume that the screen is not dimmed while the screen was unlocked just now.
            _isScreenDimmed = NO;
            log_debug(LLOOGG, "isScreenLocked YES -> NO");
        }
    }

    [self _reallyReloadViewVisibilityAnimated:NO];
}

- (void)reloadViewVisibilityWithKeychainLock {
#if !TARGET_IPHONE_SIMULATOR
    int lockState = MKBGetDeviceLockState(NULL);
    BOOL isKeychainLocked = (lockState == 1 || lockState == 2);

    if (_isKeychainLocked != isKeychainLocked) {
        _isKeychainLocked = isKeychainLocked;

        if (isKeychainLocked) {
            log_debug(LLOOGG, "isKeychainLocked NO -> YES");
        } else {
            log_debug(LLOOGG, "isKeychainLocked YES -> NO");
        }
    }

#endif
    [self _reallyReloadViewVisibilityAnimated:NO];
}

- (void)reloadViewVisibility {
    // Assume that the screen is not dimmed while the HUD was launched just now.
    _isScreenDimmed = NO;
    _isScreenLocked = mSpringBoardLockStatus();
#if !TARGET_IPHONE_SIMULATOR
    int lockState = MKBGetDeviceLockState(NULL);
    _isKeychainLocked = (lockState == 1 || lockState == 2);
#endif
    [self _reallyReloadViewVisibilityAnimated:NO];
}

- (void)_reallyReloadViewVisibilityAnimated:(BOOL)animated {
    NSAssert([NSThread isMainThread], @"main thread only");

    log_info(LLOOGG, "reloadViewVisibility: screenLocked=%@, keychainLocked=%@, screenDimmed=%@",
             _isScreenLocked ? @"YES" : @"NO", _isKeychainLocked ? @"YES" : @"NO", _isScreenDimmed ? @"YES" : @"NO");

    BOOL shouldBecomeVisible;
    BOOL isLandscape = UIDeviceOrientationIsLandscape((UIDeviceOrientation)_windowOrientation);

    if (_shouldHideWhenLandscape && isLandscape) {
        shouldBecomeVisible = NO;
    } else if (_shouldDisplayOnLockScreen) {
        shouldBecomeVisible = !_isScreenDimmed;
    } else {
        shouldBecomeVisible = !_isScreenLocked && !_isKeychainLocked;
    }

    BOOL isRootViewHidden = [_rootViewController.view isHidden];

    if (shouldBecomeVisible && isRootViewHidden) {
        if (animated) {
            [UIView transitionWithView:_mainWindow duration:0.25 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                [_rootViewController.view setHidden:NO];
            } completion:nil];
        } else {
            [_rootViewController.view setHidden:NO];
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:TRHudVisibilityDidChangeNotification object:self];
    }

    if (!shouldBecomeVisible && !isRootViewHidden) {
        if (animated) {
            [UIView transitionWithView:_mainWindow duration:0.25 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                [_rootViewController.view setHidden:YES];
            } completion:nil];
        } else {
            [_rootViewController.view setHidden:YES];
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:TRHudVisibilityDidChangeNotification object:self];
    }
}

#pragma mark - Getters

- (BOOL)isVisible {
    BOOL shouldBecomeVisible;
    BOOL isLandscape = UIDeviceOrientationIsLandscape((UIDeviceOrientation)_windowOrientation);

    if (_shouldHideWhenLandscape && isLandscape) {
        shouldBecomeVisible = NO;
    } else if (_shouldDisplayOnLockScreen) {
        shouldBecomeVisible = !_isScreenDimmed;
    } else {
        shouldBecomeVisible = !_isScreenLocked && !_isKeychainLocked;
    }

    return shouldBecomeVisible;
}

@end
