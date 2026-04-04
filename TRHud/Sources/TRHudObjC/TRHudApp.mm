//
//  TRHudApp.mm
//  TrollRecorder
//
//  Created by Lessica on 2024/2/13.
//

#import "TRHudApp.h"
#import "TREventFetcher.h"
#import "TRHudMainApplication.h"
#import "TRHudMainApplicationDelegate.h"
#import "TRLogger.h"
#import "TRSystemUserDefaults.h"

#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <notify.h>
#import <objc/runtime.h>
#import <spawn.h>
#import <sys/utsname.h>

#import "AXEventRepresentation.h"
#import "BackboardServices.h"
#import "IOKit+SPI.h"
#import "NSBundle+Language.h"
#import "UIApplication+Private.h"
#import "_UIRemoteKeyboards.h"

#define NOTIFY_TERMINATE_DELAY 2.0
#define NOTIFY_SPRINGBOARD_DID_LAUNCH "SBSpringBoardDidLaunchNotification"

@interface UIDevice (Private)
- (UIDeviceOrientation)orientation;
@end

static NSString *mDeviceModel(void) {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

static void mHUDEventCallback(void *target, void *refcon, IOHIDServiceRef service, IOHIDEventRef event) {

    static UIApplication *app = [UIApplication sharedApplication];

    // iOS 15.1+ has a new API for handling HID events.
    if (@available(iOS 15.1, *)) {
    } else {
        [app _enqueueHIDEvent:event];
    }

    BOOL shouldUseAXEvent = YES; // Always use AX events now...

    BOOL isExactly15 = NO;
    static NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
    if (version.majorVersion == 15 && version.minorVersion == 0 && version.patchVersion == 0) {
        NSString *deviceModel = mDeviceModel();
        if (![deviceModel hasPrefix:@"iPhone13,"] && ![deviceModel hasPrefix:@"iPhone14,"]) { // iPhone 12 & 13 Series
            isExactly15 = YES;
        }
    }

    if (@available(iOS 15.0, *)) {
        shouldUseAXEvent = !isExactly15;
    } else {
        shouldUseAXEvent = NO;
    }

    if (shouldUseAXEvent) {

        static Class AXEventRepresentationCls = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/AccessibilityUtilities.framework"] load];
            AXEventRepresentationCls = objc_getClass("AXEventRepresentation");
        });

        AXEventRepresentation *rep = [AXEventRepresentationCls representationWithHIDEvent:event
                                                                      hidStreamIdentifier:@"UIApplicationEvents"];

        /* I don't like this. It's too hacky, but it works. */
        if (rep) {

            dispatch_async(dispatch_get_main_queue(), ^(void) {
                static UIWindow *keyWindow = nil;
                static UIDevice *currentDevice = nil;
                static dispatch_once_t onceToken;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                dispatch_once(&onceToken, ^{
                    keyWindow = [[app windows] firstObject];
                    currentDevice = [UIDevice currentDevice];
                });
#pragma clang diagnostic pop

                CGSize screenSize = [[[UIScreen mainScreen] fixedCoordinateSpace] bounds].size;

                CGPoint hitLocation = [rep location];
                UIDeviceOrientation deviceOrientation = currentDevice.orientation;
                if (!UIDeviceOrientationIsFlat(deviceOrientation)) {
                    CGPoint newLocation;
                    switch (deviceOrientation) {
                        case UIDeviceOrientationLandscapeLeft:
                            newLocation = CGPointMake(hitLocation.y, screenSize.width - hitLocation.x);
                            break;
                        case UIDeviceOrientationLandscapeRight:
                            newLocation = CGPointMake(screenSize.height - hitLocation.y, hitLocation.x);
                            break;
                        case UIDeviceOrientationPortraitUpsideDown:
                            newLocation = CGPointMake(screenSize.width - hitLocation.x, screenSize.height - hitLocation.y);
                            break;
                        default:
                            newLocation = hitLocation;
                            break;
                    }
                    hitLocation = newLocation;
                }

                UIView *keyView = [keyWindow hitTest:hitLocation withEvent:nil];

                UITouchPhase phase = UITouchPhaseEnded;
                if ([rep isTouchDown])
                    phase = UITouchPhaseBegan;
                else if ([rep isMove])
                    phase = UITouchPhaseMoved;
                else if ([rep isCancel])
                    phase = UITouchPhaseCancelled;

                if (!rep.handInfo.paths.firstObject.pathIdentity) {
                    return;
                }

                [TREventFetcher receiveAXEventID:2
                              atGlobalCoordinate:hitLocation
                                  withTouchPhase:phase
                                        inWindow:keyWindow
                                          onView:keyView];
            });
        }
    }
}

static void mSignalInterrupt(int signal) {
    NSString *notifyName = [NSString stringWithFormat:@"%@.hud.dismissal", [[NSBundle mainBundle] bundleIdentifier]];
    notify_post([notifyName UTF8String]);
}

static void mSignalChildren(int signal, struct __siginfo *info, void *context) {
    int unused;
    waitpid(info->si_pid, &unused, WNOHANG);
}

static void mMonitorSelfAndRestartIfVnodeDeleted(char *executablePath) {

    int selfHandle = open(executablePath, O_EVTONLY);
    if (selfHandle <= 0) {
        return;
    }

    static unsigned long monitorMask = DISPATCH_VNODE_DELETE;
    static dispatch_source_t monitorSource;
    monitorSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, selfHandle, monitorMask, dispatch_get_main_queue());

    dispatch_source_set_event_handler(monitorSource, ^{
        unsigned long flags = dispatch_source_get_data(monitorSource);
        if (flags & DISPATCH_VNODE_DELETE) {
            dispatch_source_cancel(monitorSource);
            mSignalInterrupt(SIGINT);
        }
    });

    dispatch_resume(monitorSource);
}

extern "C" char **environ;

#define POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE 1
extern "C" int posix_spawnattr_set_persona_np(const posix_spawnattr_t *__restrict, uid_t, uint32_t);
extern "C" int posix_spawnattr_set_persona_uid_np(const posix_spawnattr_t *__restrict, uid_t);
extern "C" int posix_spawnattr_set_persona_gid_np(const posix_spawnattr_t *__restrict, uid_t);

static void mPosixSpawnSelfAndDetached(const char *executablePath) {

    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);

    posix_spawnattr_set_persona_np(&attr, 99, POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE);
    posix_spawnattr_set_persona_uid_np(&attr, 501);
    posix_spawnattr_set_persona_gid_np(&attr, 501);

    pid_t task_pid;
    const char *args[] = {executablePath, "--restart", NULL};
    posix_spawn(&task_pid, executablePath, NULL, &attr, (char **)args, environ);
    posix_spawnattr_destroy(&attr);
}

void TRHudSetupSignalHandlers(void) {
    struct sigaction act = {{0}};
    struct sigaction oldact = {{0}};
    act.sa_sigaction = &mSignalChildren;
    act.sa_flags = SA_SIGINFO;
    sigaction(SIGCHLD, &act, &oldact);
}

int TRHudMain(int argc, char *argv[], TRHudMainApplicationDelegate *delegate) {

    @autoreleasepool {

        NSString *terminateNotifyName = [NSString stringWithFormat:@"%@.terminate-other-instances", [[NSBundle mainBundle] bundleIdentifier]];

        if (argc > 1) {
            BOOL isRestart = strcmp(argv[1], "--restart") == 0;
            if (isRestart) {
                notify_post([terminateNotifyName UTF8String]);
                CFRunLoopRunInMode(kCFRunLoopDefaultMode, NOTIFY_TERMINATE_DELAY, false);
            }
        }

        /* Signal */
        struct sigaction act = {{0}};
        struct sigaction oldact = {{0}};
        act.sa_handler = &mSignalInterrupt;
        act.sa_flags = SA_RESETHAND;
        sigaction(SIGINT, &act, &oldact);
        mMonitorSelfAndRestartIfVnodeDeleted(argv[0]);

        /* Singleton */
        NSString *markerPath;
        char *cMarkerPath = getenv("MARKER_PATH");
        if (cMarkerPath) {
            markerPath = [NSString stringWithUTF8String:cMarkerPath];
        } else {
            NSString *markerName = [NSString stringWithFormat:@"%@.hud.pid", [[NSBundle mainBundle] bundleIdentifier]];
            markerPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:markerName];
        }

        // Open file for read/write, create if doesn't exist
        int lockFD = open([markerPath fileSystemRepresentation], O_RDWR | O_CREAT, 0644);
        if (lockFD == -1) {
            log_error(OS_LOG_DEFAULT, "Failed to open lock file: %s", strerror(errno));
            return EXIT_FAILURE;
        }

        // Try to acquire an exclusive lock
        struct flock fl;
        fl.l_type = F_WRLCK;
        fl.l_whence = SEEK_SET;
        fl.l_start = 0;
        fl.l_len = 0; // Lock entire file

        if (fcntl(lockFD, F_SETLK, &fl) == -1) {
            // Lock already held by another process
            log_info(OS_LOG_DEFAULT, "Another instance is already running");
            close(lockFD);
            return EXIT_FAILURE;
        }

        // Truncate the file to clear any previous content
        if (ftruncate(lockFD, 0) == -1) {
            log_error(OS_LOG_DEFAULT, "Failed to truncate lock file: %s", strerror(errno));
            // Continue anyway
        }

        // Write PID to file
        pid_t pid = getpid();
        char pidStr[16];
        int len = snprintf(pidStr, sizeof(pidStr), "%d\n", pid);
        if (write(lockFD, pidStr, len) != len) {
            log_error(OS_LOG_DEFAULT, "Failed to write PID to lock file: %s", strerror(errno));
            // Continue anyway
        }

        // Keep the file descriptor open to maintain the lock
        // It will be automatically closed when the process exits

        {
            static int mNotifyTerminateToken;
            notify_register_dispatch([terminateNotifyName UTF8String], &mNotifyTerminateToken,
                                     dispatch_get_main_queue(), ^(int token) {
                notify_cancel(token);
                exit(EXIT_SUCCESS);
            });
        }

        {
            static int mSpringboardBootToken;
            notify_register_dispatch(NOTIFY_SPRINGBOARD_DID_LAUNCH, &mSpringboardBootToken, dispatch_get_main_queue(),
                                     ^(int token) {
                notify_cancel(token);
                mPosixSpawnSelfAndDetached(argv[0]);
                exit(EXIT_SUCCESS);
            });
        }

        /* Language */

        /* HUD */
        [UIScreen initialize];
        CFRunLoopGetCurrent();

        GSInitialize();
        BKSDisplayServicesStart();
        UIApplicationInitialize();
        UIApplicationInstantiateSingleton([TRHudMainApplication class]);

        UIApplication *app = [UIApplication sharedApplication];
        [app setDelegate:delegate];
        [app _accessibilityInit];

        [NSRunLoop currentRunLoop];
        BKSHIDEventRegisterEventCallback(mHUDEventCallback);

        if (@available(iOS 15.0, *)) {
            GSEventInitialize(0);
            GSEventPushRunLoopMode(kCFRunLoopDefaultMode);
        }

        [_UIRemoteKeyboards sharedRemoteKeyboards];
        [app __completeAndRunAsPlugin];

        CFRunLoopRun();
        return EXIT_SUCCESS;
    }
}
