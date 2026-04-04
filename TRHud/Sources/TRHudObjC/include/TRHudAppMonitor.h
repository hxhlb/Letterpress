//
//  TRHudAppMonitor.h
//  TRHud
//
//  Created by Rachel on 9/6/2025.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

OBJC_EXTERN NSNotificationName const TRHudAppMonitorDidChangeNotification;

@interface TRHudAppMonitor : NSObject
@property (nonatomic, assign, readonly, getter=isPrimaryAppInForeground) BOOL primaryAppInForeground;
@end

NS_ASSUME_NONNULL_END
