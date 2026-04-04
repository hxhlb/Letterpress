//
//  TRSystemUserDefaults.mm
//  TrollRecorder
//
//  Created by Lessica on 2024/2/13.
//

#import "TRSystemUserDefaults.h"

#define USER_PREFS_DIR "/var/mobile/Library/Preferences"

NSUserDefaults *GetSystemUserDefaults(NSString *suiteName) {
    NSString *prefsPath = [NSString stringWithFormat:@USER_PREFS_DIR "/%@.plist", suiteName];
    return [[NSUserDefaults alloc] initWithSuiteName:prefsPath];
}

NSUserDefaults *GetStandardUserDefaults(void) {
    static NSUserDefaults *userDefaults = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        userDefaults = GetSystemUserDefaults([[NSBundle mainBundle] bundleIdentifier]);
    });
    return userDefaults;
}
