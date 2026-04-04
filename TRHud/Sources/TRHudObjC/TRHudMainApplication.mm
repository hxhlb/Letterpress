//
//  TRHudMainApplication.mm
//  TrollRecorder
//
//  Created by Lessica on 2024/2/13.
//

#import "TRHudMainApplication.h"
#import "TRLogger.h"

#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <notify.h>
#import <objc/runtime.h>
#import <pthread.h>

#import "UIApplication+Private.h"
#import "UIEventDispatcher.h"
#import "UIEventFetcher.h"
#import "pac_helper.h"

#define FADE_OUT_DURATION 0.3

LOGGER_WITH_CATEGORY("TRHudMainApplication");

@implementation TRHudMainApplication

- (void)performAlphaFadeOut {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [[self.windows firstObject] setAlpha:0.0];
#pragma clang diagnostic pop
}

- (instancetype)init {
    if (self = [super init]) {
        log_debug(LLOOGG, "- [TRHudMainApplication init]");

        {
            NSString *notifyName = [NSString stringWithFormat:@"%@.hud.dismissal", [[NSBundle mainBundle] bundleIdentifier]];
            int outToken;
            notify_register_dispatch([notifyName UTF8String], &outToken, dispatch_get_main_queue(), ^(int token) {
              notify_cancel(token);

              // Fade out the HUD window
              [UIView animateWithDuration:FADE_OUT_DURATION
                  animations:^(void) {
                    [self performAlphaFadeOut];
                  }
                  completion:^(BOOL finished) {
                    // Terminate the HUD app
                    [self terminateWithSuccess];
                  }];
            });
        }

        do {
            UIEventDispatcher *dispatcher = (UIEventDispatcher *)[self valueForKey:@"eventDispatcher"];
            if (!dispatcher) {
                log_error(LLOOGG, "failed to get ivar _eventDispatcher");
                break;
            }
            log_debug(LLOOGG, "got ivar _eventDispatcher: %p", dispatcher);

            if ([dispatcher respondsToSelector:@selector(_installEventRunLoopSources:)]) {
                CFRunLoopRef mainRunLoop = CFRunLoopGetMain();
                [dispatcher _installEventRunLoopSources:mainRunLoop];
            } else {
                IMP runMethodIMP = class_getMethodImplementation([self class], @selector(_run));
                if (!runMethodIMP) {
                    log_error(LLOOGG, "failed to get - [UIApplication _run] method");
                    break;
                }

                uint32_t *runMethodPtr = (uint32_t *)make_sym_readable((void *)runMethodIMP);
                log_debug(LLOOGG, "- [UIApplication _run]: %p", runMethodPtr);

                void (*orig_UIEventDispatcher__installEventRunLoopSources_)(id _Nonnull, SEL _Nonnull, CFRunLoopRef) =
                    NULL;
                for (int i = 0; i < 0x140; i++) {
                    // mov x2, x0
                    // mov x0, x?
                    if (runMethodPtr[i] != 0xaa0003e2 || (runMethodPtr[i + 1] & 0xff000000) != 0xaa000000)
                        continue;

                    // bl -[UIEventDispatcher _installEventRunLoopSources:]
                    uint32_t blInst = runMethodPtr[i + 2];
                    uint32_t *blInstPtr = &runMethodPtr[i + 2];
                    if ((blInst & 0xfc000000) != 0x94000000) {
                        log_error(LLOOGG, "not a BL instruction: 0x%x, address %p", blInst, blInstPtr);
                        continue;
                    }
                    log_debug(LLOOGG, "found BL instruction: 0x%x, address %p", blInst, blInstPtr);

                    int32_t blOffset = blInst & 0x03ffffff;
                    if (blOffset & 0x02000000)
                        blOffset |= 0xfc000000;
                    blOffset <<= 2;
                    log_debug(LLOOGG, "BL offset: 0x%x", blOffset);

                    uint64_t blAddr = (uint64_t)blInstPtr + blOffset;
                    log_debug(LLOOGG, "BL target address: %p", (void *)blAddr);

                    // cbz x0, loc_?????????
                    uint32_t cbzInst = *((uint32_t *)make_sym_readable((void *)blAddr));
                    if ((cbzInst & 0xff000000) != 0xb4000000) {
                        log_error(LLOOGG, "not a CBZ instruction: 0x%x", cbzInst);
                        continue;
                    }

                    log_debug(LLOOGG, "found CBZ instruction: 0x%x, address %p", cbzInst, (void *)blAddr);

                    orig_UIEventDispatcher__installEventRunLoopSources_ =
                        (void (*)(id _Nonnull __strong, SEL _Nonnull, CFRunLoopRef))make_sym_callable((void *)blAddr);
                }

                if (!orig_UIEventDispatcher__installEventRunLoopSources_) {
                    log_error(LLOOGG, "failed to find -[UIEventDispatcher _installEventRunLoopSources:]");
                    break;
                }

                log_debug(LLOOGG, "- [UIEventDispatcher _installEventRunLoopSources:]: %p",
                          orig_UIEventDispatcher__installEventRunLoopSources_);

                CFRunLoopRef mainRunLoop = CFRunLoopGetMain();
                orig_UIEventDispatcher__installEventRunLoopSources_(dispatcher, @selector(_installEventRunLoopSources:),
                                                                    mainRunLoop);
            }

            UIEventFetcher *fetcher = [[objc_getClass("UIEventFetcher") alloc] init];
            [dispatcher setValue:fetcher forKey:@"eventFetcher"];

            if ([fetcher respondsToSelector:@selector(setEventFetcherSink:)]) {
                [fetcher setEventFetcherSink:dispatcher];
            } else {
                /* Tested on iOS 15.1.1 and below */
                [fetcher setValue:dispatcher forKey:@"eventFetcherSink"];
            }

            [self setValue:fetcher forKey:@"eventFetcher"];
        } while (NO);
    }
    return self;
}

- (BOOL)_supportedOnLockScreen {
    return YES;
}

@end
