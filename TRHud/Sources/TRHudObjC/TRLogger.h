//
//  TRLogger.h
//  TrollRecorder
//
//  Created by Lessica on 2024/2/13.
//

#import <os/log.h>

#ifdef __cplusplus

#define LOGGER_WITH_CATEGORY(category) \
__used const static os_log_t LLOOGG = os_log_create("", category); \
__used const static NSString *const TTAAGG = @ category;

#else

#define STATIC_VAR(type, code) ^type() { \
    static type object; \
    static dispatch_once_t onceToken; \
    dispatch_once(&onceToken, ^{ \
        object = code; \
    }); \
    return object; \
};

#define LOGGER_WITH_CATEGORY(category) \
__used __auto_type const static LLOOGGEERR = STATIC_VAR(os_log_t, os_log_create("", category)); \
__used static NSString *const TTAAGG = @ category;

#define LLOOGG LLOOGGEERR()

#endif

#if DEBUG
#define log_debug os_log_debug
#define log_info os_log_info
#define log_error os_log_error
#else
#define log_debug(...)
#define log_info(...)
#define log_error(...)
#endif
