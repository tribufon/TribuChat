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

#import "NSBundle+FormatterKit.h"
#import "TTTTimeIntervalFormatter.h"
#import "TTTUnitOfInformationFormatter.h"

FOUNDATION_EXPORT double FormatterKitVersionNumber;
FOUNDATION_EXPORT const unsigned char FormatterKitVersionString[];

