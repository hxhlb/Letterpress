#import "IOKit+SPI.h"
#import <UIKit/UIKit.h>

@class UIEventDispatcher;

@interface UIEventFetcher : NSObject

- (void)_receiveHIDEvent:(IOHIDEventRef)arg1;
- (void)setEventFetcherSink:(UIEventDispatcher *)arg1;

@end
