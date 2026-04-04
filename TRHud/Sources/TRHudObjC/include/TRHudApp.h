//
//  TRHudApp.h
//  TrollRecorder
//
//  Created by Lessica on 2024/2/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class TRHudMainApplicationDelegate;

OBJC_EXTERN int TRHudMain(int argc, char * _Nullable argv[_Nonnull], TRHudMainApplicationDelegate *delegate);
OBJC_EXTERN void TRHudSetupSignalHandlers(void);

NS_ASSUME_NONNULL_END
