//
//  TRSystemUserDefaults.h
//  TrollRecorder
//
//  Created by Lessica on 2024/2/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

OBJC_EXTERN NSUserDefaults *GetStandardUserDefaults(void);
OBJC_EXTERN NSUserDefaults *GetSystemUserDefaults(NSString *suiteName);

NS_ASSUME_NONNULL_END
