//
//  TRHudMediaObserver.mm
//  TRHud
//
//  Created by Rachel on 9/6/2025.
//

#import "TRHudMediaObserver.h"
#import "MediaRemote+Private.h"
#import "NSData+XXHash.h"

#import <UIKit/UIKit.h>

#import <sys/sysctl.h>

NSNotificationName const TRHudMediaObserverDidChangeNotification = @"TRHudMediaObserverDidChangeNotification";
NSNotificationName const TRHudMediaObserverArtworkDidChangeNotification = @"TRHudMediaObserverArtworkDidChangeNotification";

static void TREnumerateProcessesUsingBlock(void (^enumerator)(pid_t pid, NSString *executablePath, BOOL *stop)) {

    static int kMaximumArgumentSize = 0;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        size_t valSize = sizeof(kMaximumArgumentSize);
        if (sysctl((int[]){CTL_KERN, KERN_ARGMAX}, 2, &kMaximumArgumentSize, &valSize, NULL, 0) < 0) {
            perror("sysctl argument size");
            kMaximumArgumentSize = 4096;
        }
    });

    size_t procInfoLength = 0;
    if (sysctl((int[]){CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0}, 3, NULL, &procInfoLength, NULL, 0) < 0) {
        return;
    }

    struct kinfo_proc *procInfo = (struct kinfo_proc *)malloc(procInfoLength + 1);
    if (!procInfo) {
        return;
    }

    bzero(procInfo, procInfoLength + 1);
    if (sysctl((int[]){CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0}, 3, procInfo, &procInfoLength, NULL, 0) < 0) {
        free(procInfo);
        return;
    }

    int procInfoCnt = (int)(procInfoLength / sizeof(struct kinfo_proc));
    for (int i = 0; i < procInfoCnt; i++) {

        pid_t pid = procInfo[i].kp_proc.p_pid;
        if (pid <= 1) {
            continue;
        }

        size_t argSize = kMaximumArgumentSize;
        if (sysctl((int[]){CTL_KERN, KERN_PROCARGS2, pid, 0}, 3, NULL, &argSize, NULL, 0) < 0) {
            continue;
        }

        char *argBuffer = (char *)malloc(argSize + 1);
        if (!argBuffer) {
            continue;
        }

        bzero(argBuffer, argSize + 1);
        if (sysctl((int[]){CTL_KERN, KERN_PROCARGS2, pid, 0}, 3, argBuffer, &argSize, NULL, 0) < 0) {
            free(argBuffer);
            continue;
        }

        BOOL stop = NO;
        @autoreleasepool {
            enumerator(pid, [NSString stringWithUTF8String:(argBuffer + sizeof(int))], &stop);
        }

        free(argBuffer);

        if (stop) {
            break;
        }
    }

    free(procInfo);
}

#import <os/lock.h>

static NSDictionary<NSNumber *, NSString *> *TRDisplayIdentifiersOfProcessIdentifiers(NSSet<NSNumber *> *targetPids) {

    static NSMutableDictionary<NSString *, NSString *> *cachedDisplayIdentifiers = nil;
    static os_unfair_lock cacheLock = OS_UNFAIR_LOCK_INIT;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cachedDisplayIdentifiers = [NSMutableDictionary dictionary];
    });

    NSMutableDictionary<NSNumber *, NSString *> *displayIdentifiers =
    [NSMutableDictionary dictionaryWithCapacity:targetPids.count];

    TREnumerateProcessesUsingBlock(^(pid_t pid, NSString *_Nonnull executablePath, BOOL *_Nonnull stop) {
        if (!executablePath.length) {
            return;
        }

        if (![targetPids containsObject:@(pid)]) {
            return;
        }

        NSString *cachedBundleIdentifier = nil;
        os_unfair_lock_lock(&cacheLock);
        cachedBundleIdentifier = cachedDisplayIdentifiers[executablePath];
        os_unfair_lock_unlock(&cacheLock);

        if (cachedBundleIdentifier) {
            [displayIdentifiers setObject:cachedBundleIdentifier forKey:@(pid)];
            return;
        }

        NSString *bundlePath = [executablePath stringByDeletingLastPathComponent];
        BOOL isAppBundle = [[bundlePath pathExtension] isEqualToString:@"app"];
        if (!isAppBundle) {
            return;
        }

        NSString *infoPlistPath = [bundlePath stringByAppendingPathComponent:@"Info.plist"];
        NSDictionary *infoPlist = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];
        NSString *bundleIdentifier = [infoPlist[@"CFBundleIdentifier"] copy];

        if (!bundleIdentifier.length) {
            return;
        }

        os_unfair_lock_lock(&cacheLock);
        cachedDisplayIdentifiers[executablePath] = bundleIdentifier;
        os_unfair_lock_unlock(&cacheLock);

        [displayIdentifiers setObject:bundleIdentifier forKey:@(pid)];
    });

    return [displayIdentifiers copy];
}

static NSString *TRDisplayIdentifierOfProcessIdentifier(pid_t pid) {
    NSDictionary<NSNumber *, NSString *> *displayIdentifiers = TRDisplayIdentifiersOfProcessIdentifiers([NSSet setWithObject:@(pid)]);
    return displayIdentifiers[@(pid)];
}

@implementation TRHudMediaObserver {
    dispatch_queue_t mQueue;
    dispatch_queue_t mGlobalQueue;
    BOOL mIsNowPlaying;
    BOOL mIsArtworkDecodingRequired;
    NSString *mLastArtworkIdentifier;
    NSDictionary *mNowPlayingInfo;
    NSArray *mPickableRoutes;
}

@synthesize nowPlayingApp = _nowPlayingApp;
@synthesize nowPlayingSubtitle = _nowPlayingSubtitle;
@synthesize nowPlayingArtwork = _nowPlayingArtwork;

- (instancetype)init {
    self = [super init];
    if (self) {
        mQueue = dispatch_queue_create("TRHudMediaObserver", DISPATCH_QUEUE_SERIAL_WITH_AUTORELEASE_POOL);
        mGlobalQueue = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0);
        mIsNowPlaying = NO;
        mIsArtworkDecodingRequired = NO;
        mLastArtworkIdentifier = nil;
        mNowPlayingInfo = nil;
        mPickableRoutes = nil;

        _nowPlayingApp = nil;
        _nowPlayingSubtitle = nil;
        _nowPlayingArtwork = nil;

        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(handleIsPlayingDidChangeNotification:)
         name:(__bridge NSNotificationName)kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification
         object:nil];

        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(handleNowPlayingInfoDidChangeNotification:)
         name:(__bridge NSNotificationName)kMRMediaRemoteNowPlayingInfoDidChangeNotification
         object:nil];

        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(handlePickableRoutesDidChangeNotification:)
         name:(__bridge NSNotificationName)kMRMediaRemotePickableRoutesDidChangeNotification
         object:nil];

        MRMediaRemoteSetWantsNowPlayingNotifications(true);
        MRMediaRemoteGetNowPlayingApplicationIsPlaying(mGlobalQueue, ^(Boolean isPlaying) {
            [self handleIsPlayingDidChange:isPlaying];
        });
        MRMediaRemoteGetNowPlayingInfo(mGlobalQueue, ^(CFDictionaryRef userInfo) {
            [self handleNowPlayingInfoDidChange:(__bridge NSDictionary *)userInfo];
        });
        MRMediaRemoteGetNowPlayingApplicationPID(mGlobalQueue, ^(int pid) {
            [self handleNowPlayingAppPID:pid];
        });

        MRMediaRemoteSetWantsRouteChangeNotifications(true);
        [self handlePickableRoutesDidChangeNotification:nil];
    }
    return self;
}

- (BOOL)isNowPlaying {
    __block BOOL value = NO;
    dispatch_sync(mQueue, ^{
        value = mIsNowPlaying;
    });
    return value;
}

- (NSDictionary *)nowPlayingInfo {
    __block NSDictionary *value = nil;
    dispatch_sync(mQueue, ^{
        value = [mNowPlayingInfo copy];
    });
    return value;
}

- (BOOL)isArtworkDecodingRequired {
    __block BOOL value = NO;
    dispatch_sync(mQueue, ^{
        value = mIsArtworkDecodingRequired;
    });
    return value;
}

- (BOOL)_shouldUseArtistAsSubtitle {
    if ([_nowPlayingApp hasPrefix:@"com.tencent."] || [_nowPlayingApp hasPrefix:@"com.soda."] ||
        [_nowPlayingApp hasPrefix:@"com.yeelion."] || [_nowPlayingApp hasPrefix:@"com.wenyu."] ||
        [_nowPlayingApp hasPrefix:@"com.fq."] || [_nowPlayingApp hasPrefix:@"com.migu."]) {
        if ([mPickableRoutes isKindOfClass:[NSArray class]]) {
            for (NSDictionary *route in mPickableRoutes) {
                BOOL isBluetooth = [route[@"IsBTRoute"] boolValue];
                BOOL isCurrentRoute = [route[@"RouteCurrentlyPicked"] boolValue];
                if (isCurrentRoute && isBluetooth) {
                    return NO;
                }
            }
        }
        return YES;
    }
    if ([_nowPlayingApp hasPrefix:@"logicui.Music-Player"]) {
        return YES;
    }
    return NO;
}

- (void)setArtworkDecodingRequired:(BOOL)artworkDecodingRequired {
    dispatch_sync(mQueue, ^{
        mIsArtworkDecodingRequired = artworkDecodingRequired;
    });
}

- (void)handleIsPlayingDidChangeNotification:(NSNotification *)noti {
    NSDictionary *userInfo = noti.userInfo;

    BOOL isPlaying = [userInfo[(__bridge NSString *)kMRMediaRemoteNowPlayingApplicationIsPlayingUserInfoKey] boolValue];
    dispatch_async(mGlobalQueue, ^{
        [self handleIsPlayingDidChange:isPlaying];
    });

    pid_t pid = [userInfo[(__bridge NSString *)kMRMediaRemoteNowPlayingApplicationPIDUserInfoKey] intValue];
    dispatch_async(mGlobalQueue, ^{
        [self handleNowPlayingAppPID:pid];
    });
}

- (void)handleIsPlayingDidChange:(BOOL)isPlaying {
    dispatch_async(mQueue, ^{
        if (mIsNowPlaying == isPlaying) {
            return;
        }

        mIsNowPlaying = isPlaying;
        if (mLastArtworkIdentifier) {
            mLastArtworkIdentifier = nil;
            dispatch_async(mGlobalQueue, ^{
                [self handleArtworkData:nil];
            });
        }

        [self notifyDidChange];
    });
}

- (void)handleNowPlayingInfoDidChangeNotification:(NSNotification *_Nullable)noti {
    MRMediaRemoteGetNowPlayingInfo(mGlobalQueue, ^(CFDictionaryRef userInfo) {
        [self handleNowPlayingInfoDidChange:(__bridge NSDictionary *)userInfo];
    });
}

- (void)handleNowPlayingInfoDidChange:(NSDictionary *)userInfo {
    dispatch_async(mQueue, ^{
        if (mIsArtworkDecodingRequired) {
            NSData *artworkData = userInfo[(__bridge NSString *_Nonnull __strong)(kMRMediaRemoteNowPlayingInfoArtworkData)];
            NSString *artworkIdentifier = [NSString stringWithFormat:@"%@-%lu", [artworkData xxh64], [artworkData length]];
            if (artworkIdentifier && artworkData) {
                if (![mLastArtworkIdentifier isEqualToString:artworkIdentifier]) {
#if DEBUG
                    NSLog(@"Artwork identifier changed: %@", artworkIdentifier);
#endif
                    mLastArtworkIdentifier = [artworkIdentifier copy];
                    dispatch_async(mGlobalQueue, ^{
                        [self handleArtworkData:artworkData];
                    });
                }
            }
        }

        NSString *title = [userInfo[(__bridge NSString *_Nonnull __strong)(kMRMediaRemoteNowPlayingInfoTitle)] copy];
        NSString *artist = [userInfo[(__bridge NSString *_Nonnull __strong)(kMRMediaRemoteNowPlayingInfoArtist)] copy];
        _nowPlayingSubtitle = [self _shouldUseArtistAsSubtitle] ? artist : title;
        mNowPlayingInfo = userInfo;

        [self notifyDidChange];
    });
}

- (void)handleArtworkData:(NSData *)artworkData {
    UIImage *artworkImage = nil;
    if (artworkData) {
        artworkImage = [UIImage imageWithData:artworkData];
    }
    dispatch_async(mQueue, ^(void) {
        _nowPlayingArtwork = artworkImage;
        [self notifyArtworkDidChange];
    });
}

- (void)handleNowPlayingAppPID:(pid_t)pid {
    NSString *appId = TRDisplayIdentifierOfProcessIdentifier(pid);
    dispatch_async(mQueue, ^(void) {
        if ([_nowPlayingApp isEqualToString:appId]) {
            return;
        }
        _nowPlayingApp = [appId copy];
        [self notifyDidChange];
    });
}

- (void)handlePickableRoutesDidChangeNotification:(NSNotification *)noti {
    dispatch_async(mGlobalQueue, ^{
        NSArray *pickableRoutes = (NSArray *)CFBridgingRelease(MRMediaRemoteCopyPickableRoutes());
        dispatch_async(mQueue, ^(void) {
            mPickableRoutes = pickableRoutes;
        });
    });
}

- (void)notifyDidChange {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:TRHudMediaObserverDidChangeNotification object:self userInfo:nil];
    });
}

- (void)notifyArtworkDidChange {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:TRHudMediaObserverArtworkDidChangeNotification object:self userInfo:nil];
    });
}

@end
