#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "OTRAssets.h"
#import "OTRBranding.h"
#import "OTRLanguageManager.h"
#import "OTRSecrets.h"
#import "OTRStrings.h"

FOUNDATION_EXPORT double OTRAssetsVersionNumber;
FOUNDATION_EXPORT const unsigned char OTRAssetsVersionString[];

