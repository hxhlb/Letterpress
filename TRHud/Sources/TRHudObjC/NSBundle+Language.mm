//
//  NSBundle+Language.mm
//  ios_language_manager
//
//  Created by Maxim Bilan on 1/10/15.
//  Copyright (c) 2015 Maxim Bilan. All rights reserved.
//

#import "NSBundle+Language.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static const char kBundleKey = 0;

@interface BundleEx : NSBundle

@end

@implementation BundleEx

- (NSString *)localizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName {
    NSBundle *bundle = objc_getAssociatedObject(self, &kBundleKey);
    if (bundle) {
        return [bundle localizedStringForKey:key value:value table:tableName];
    } else {
        return [super localizedStringForKey:key value:value table:tableName];
    }
}

@end

@implementation NSBundle (Language)

+ (void)setLanguage:(NSString *)language {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      object_setClass([NSBundle mainBundle], [BundleEx class]);
    });

    BOOL isLanguageRTL = [self isLanguageRTL:language];
    if (isLanguageRTL) {
        if ([[[UIView alloc] init] respondsToSelector:@selector(setSemanticContentAttribute:)]) {
            [[UIView appearance] setSemanticContentAttribute:UISemanticContentAttributeForceRightToLeft];
        }
    } else {
        if ([[[UIView alloc] init] respondsToSelector:@selector(setSemanticContentAttribute:)]) {
            [[UIView appearance] setSemanticContentAttribute:UISemanticContentAttributeForceLeftToRight];
        }
    }
    [[NSUserDefaults standardUserDefaults] setBool:isLanguageRTL forKey:@"AppleTextDirection"];
    [[NSUserDefaults standardUserDefaults] setBool:isLanguageRTL forKey:@"NSForceRightToLeftWritingDirection"];
    [[NSUserDefaults standardUserDefaults] setObject:@[ language ] forKey:@"AppleLanguages"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    NSBundle *possibleBundle = nil;
    if (language) {
        NSMutableArray<NSString *> *languageComponents = [[language componentsSeparatedByString:@"-"] mutableCopy];
        if (!possibleBundle) {
            possibleBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:language ofType:@"lproj"]];
        }
        if (!possibleBundle) {
            [languageComponents removeLastObject];
            language = [languageComponents componentsJoinedByString:@"-"];
            possibleBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:language ofType:@"lproj"]];
        }
        if (!possibleBundle) {
            [languageComponents removeLastObject];
            language = [languageComponents componentsJoinedByString:@"-"];
            possibleBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:language ofType:@"lproj"]];
        }
    }

    objc_setAssociatedObject([NSBundle mainBundle], &kBundleKey, possibleBundle, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (BOOL)isLanguageRTL:(NSString *)languageCode {
    return ([NSLocale characterDirectionForLanguage:languageCode] == NSLocaleLanguageDirectionRightToLeft);
}

@end
