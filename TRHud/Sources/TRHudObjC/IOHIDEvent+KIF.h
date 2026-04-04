//
//  IOHIDEvent+KIF.h
//  KIF
//
//  Created by Thomas Bonnin on 7/6/15.
//

#import "IOKit+SPI.h"

#import <Foundation/Foundation.h>

CF_EXTERN_C_BEGIN

typedef struct __IOHIDEvent *IOHIDEventRef;
IOHIDEventRef kif_IOHIDEventWithTouches(NSArray *touches) CF_RETURNS_RETAINED;

CF_EXTERN_C_END
