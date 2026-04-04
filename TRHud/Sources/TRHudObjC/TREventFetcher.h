//
//  TREventFetcher.h
//  TrollRecorder
//
//  Created by Lessica on 2024/2/13.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TREventFetcher : NSObject

+ (NSInteger)receiveAXEventID:(NSInteger)pointId
           atGlobalCoordinate:(CGPoint)point
               withTouchPhase:(UITouchPhase)phase
                     inWindow:(UIWindow *)window
                       onView:(UIView *)view;

+ (void)resetAllTouches;

@end

NS_ASSUME_NONNULL_END
