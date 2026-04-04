#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TRHudCore : NSObject

- (BOOL)isMachOFile:(NSString *)filePath __attribute__((objc_direct));
- (BOOL)isMachOExecutable:(NSString *)filePath __attribute__((objc_direct));
- (BOOL)verifyMachOFile:(NSString *)filePath __attribute__((objc_direct));

#if ALLOW_PROTECTED
- (BOOL)protectMachOFile:(NSString *)filePath __attribute__((objc_direct));
- (NSData *_Nullable)dumpEntitlementsDataOfAnyArch:(NSString *)filePath __attribute__((objc_direct));
#endif

@end

NS_ASSUME_NONNULL_END
