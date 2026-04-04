#import <Foundation/Foundation.h>

FOUNDATION_EXTERN CFStringRef kMobileKeyBagLockStatusNotification;

#ifdef __cplusplus
extern "C" {
#endif

int MKBGetDeviceLockState(CFDictionaryRef options);
int MKBUnlockDevice(CFDataRef passcode, CFDictionaryRef options);

#ifdef __cplusplus
}
#endif
