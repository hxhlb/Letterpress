//
//  TRHudAppMonitor.mm
//  TRHud
//
//  Created by Rachel on 9/6/2025.
//

#import "TRHudAppMonitor.h"
#import "TRHudAppMonitor+Private.h"

#import "BKSApplicationStateMonitor.h"
#import "SpringBoardServices.h"

#define BKSApplicationStateAppIsFrontmost @"BKSApplicationStateAppIsFrontmost"
#define BKSApplicationStateExtensionKey @"BKSApplicationStateExtensionKey"
#define SBApplicationStateDisplayIDKey @"SBApplicationStateDisplayIDKey"
#define SBApplicationStateRunningReasonsKey @"SBApplicationStateRunningReasonsKey"
#define SBApplicationStateRunningReasonAssertionIdentifierKey @"SBApplicationStateRunningReasonAssertionIdentifierKey"
#define SBApplicationStateRunningReasonAssertionReasonKey @"SBApplicationStateRunningReasonAssertionReasonKey"

NSNotificationName const TRHudAppMonitorDidChangeNotification = @"TRHudAppMonitorDidChangeNotification";

@implementation TRHudAppMonitor {
    NSString *mTargetBundleIdentifier;
    BKSApplicationStateMonitor *mAppStateMonitor;
    BOOL mIsPrimaryAppInForeground;
}

// com.apple.assertiond.app-state-monitor
- (instancetype)initWithBundleIdentifier:(NSString *)bundleIdentifier {
    self = [super init];
    if (self) {
        mTargetBundleIdentifier = [bundleIdentifier copy];
        mAppStateMonitor = [[BKSApplicationStateMonitor alloc] init];

        __weak __typeof(self) weakSelf = self;
        [mAppStateMonitor setHandler:^(NSDictionary *appInfo) {
            __strong __typeof(weakSelf) strongSelf = weakSelf;

            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [strongSelf didReceiveApplicationStateChange:appInfo];
            });
        }];

        mIsPrimaryAppInForeground = NO;
        // mIsPrimaryAppInForeground = (kSBSApplicationStateForegroundRunning | SBSGetApplicationState((__bridge CFStringRef)bundleIdentifier));
    }
    return self;
}

- (void)dealloc {
    [mAppStateMonitor invalidate];
    mAppStateMonitor = nil;
}

- (void)didReceiveApplicationStateChange:(NSDictionary *)appInfo {
    static NSArray<NSString *> *viewServiceIds = @[
        @"com.apple.InputUI",
    ];

    NSString *appId = appInfo[SBApplicationStateDisplayIDKey];
    if (!appId) {
        return;
    }

    BOOL isExtension = [appInfo[BKSApplicationStateExtensionKey] boolValue];
    if (isExtension) {
        return;
    }

    BOOL isViewService = [viewServiceIds containsObject:appId];
    NSArray<NSDictionary *> *runningReasons = appInfo[SBApplicationStateRunningReasonsKey];
    for (NSDictionary *runningReason in runningReasons) {
        if ([runningReason[SBApplicationStateRunningReasonAssertionIdentifierKey]
             isEqualToString:@"com.apple.viewservice.session"]) {
            isViewService = YES;
            break;
        }
    }
    if (isViewService) {
        return;
    }

    BOOL isPrimaryAppInForeground = mIsPrimaryAppInForeground;
    BOOL isFrontmost = [appInfo[BKSApplicationStateAppIsFrontmost] boolValue];
    if ([appId isEqualToString:mTargetBundleIdentifier]) {
        mIsPrimaryAppInForeground = isFrontmost;
    }

    if (isPrimaryAppInForeground != mIsPrimaryAppInForeground) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TRHudAppMonitorDidChangeNotification
                                                            object:self];
    }
}

- (BOOL)isPrimaryAppInForeground {
    return mIsPrimaryAppInForeground;
}

@end
