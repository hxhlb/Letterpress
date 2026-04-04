#import <Foundation/Foundation.h>

#import "IOKit+SPI.h"

#if __cplusplus
extern "C" {
#endif

void *BKSHIDEventRegisterEventCallback(void (*)(void *, void *, IOHIDServiceRef, IOHIDEventRef));
void UIApplicationInstantiateSingleton(id);
void UIApplicationInitialize();
void BKSDisplayServicesStart();
void BKSDisplaySetSecureMode(BOOL);
void GSInitialize();
void GSEventInitialize(Boolean);
void GSEventPopRunLoopMode(CFStringRef);
void GSEventPushRunLoopMode(CFStringRef);
void GSEventRegisterEventCallBack(void (*)(GSEventRef));

#if __cplusplus
}
#endif
