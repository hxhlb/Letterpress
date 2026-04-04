/**
 * SpringBoardServices framework header.
 *
 * Borrows work done by KennyTM.
 * See https://github.com/kennytm/iphone-private-frameworks/blob/master/SpringBoardServices/SpringBoardServices.h
 * for more information.
 *
 * Copyright (c) 2010 KennyTM~
 * Copyright (c) 2013-2014 Cykey (David Murray)
 * All rights reserved.
*/

#ifndef SPRINGBOARDSERVICES_H_
#define SPRINGBOARDSERVICES_H_

#include <CoreFoundation/CoreFoundation.h>

enum SBSApplicationState {
    kSBSApplicationStateUnknown = 0,
    kSBSApplicationStateTerminated = 1 << 0,
    kSBSApplicationStateBackgroundTaskSuspended = 1 << 1,
    kSBSApplicationStateBackgroundRunning = 1 << 2,
    kSBSApplicationStateForegroundRunning = 1 << 3,
    kSBSApplicationStateProcessServer = 1 << 4,
    kSBSApplicationStateForegroundRunningObscured = 1 << 5,
};

CF_EXTERN_C_BEGIN

mach_port_t SBSSpringBoardServerPort();
void SBSetSystemVolumeHUDEnabled(mach_port_t springBoardPort, const char *audioCategory, Boolean enabled);

void SBGetScreenLockStatus(mach_port_t port, BOOL *lockStatus, BOOL *passcodeEnabled);
void SBGetCurrentBacklightFactor(mach_port_t port, float *outFactor);

void SBSOpenNewsstand();
void SBSSuspendFrontmostApplication();

CFStringRef SBSCopyStatusBarOperatorName();

CFStringRef SBSCopyBundlePathForDisplayIdentifier(CFStringRef displayIdentifier);
CFStringRef SBSCopyExecutablePathForDisplayIdentifier(CFStringRef displayIdentifier);
CFDataRef SBSCopyIconImagePNGDataForDisplayIdentifier(CFStringRef displayIdentifier);

CFStringRef SBSCopyNowPlayingAppBundleIdentifier();

CFSetRef SBSCopyDisplayIdentifiers();
CFStringRef SBSCopyLocalizedApplicationNameForDisplayIdentifier(CFStringRef identifier);

CFStringRef SBSCopyFrontmostApplicationDisplayIdentifier();
CFStringRef SBSCopyDisplayIdentifierForProcessID(pid_t PID);
CFDictionaryRef SBSCopyInfoForApplicationWithProcessID(pid_t PID);

CFArrayRef SBSCopyDisplayIdentifiersForProcessID(pid_t PID);
BOOL SBSProcessIDForDisplayIdentifier(CFStringRef identifier, pid_t *pid);

// The following need com.apple.backboardd.launchapplications entitlement
int SBSLaunchApplicationWithIdentifier(CFStringRef identifier, Boolean suspended);
int SBSLaunchApplicationWithIdentifierAndLaunchOptions(CFStringRef identifier, CFDictionaryRef launchOptions, BOOL suspended);
CFStringRef SBSApplicationLaunchingErrorString(int error);

int SBSOpenSensitiveURLAndUnlock(CFURLRef url, char flags); // need com.apple.springboard.opensensitiveurl entitlement

SBSApplicationState SBSGetApplicationState(CFStringRef identifier);

CF_EXTERN_C_END

#endif /* SPRINGBOARDSERVICES_H_ */
