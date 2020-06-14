//
//  GLCPasscodeViewController.h
//  Q-municate
//
//  Created by YuriyFpc on 11.10.17.
//  Copyright © 2017 Quickblox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VENTouchLockSplashViewController.h"

typedef NS_ENUM(NSUInteger, GLCPasscodeViewMode) {
    GLCPasscodeViewModeCreate,
    GLCPasscodeViewModeConfirm,
    GLCPasscodeViewModeEnter
};

typedef NS_ENUM(NSUInteger, GLCPasscodeInputMode) {
    GLCPasscodeInputModeFourNumbers,
    GLCPasscodeInputModeSixNumbers,
    GLCPasscodeInputModeCustomNumeric,
    GLCPasscodeInputModeAlphanumeric
};

@class GLCSecurePasscodeView;

@interface GLCPasscodeViewController : UIViewController

@property (weak, nonatomic) IBOutlet GLCSecurePasscodeView *passwordStackView;
@property (nonatomic, copy) void (^willFinishWithResult)(BOOL success);
@property (nonatomic, strong) NSString *confirmPasscode;

- (instancetype)initWithMode:(GLCPasscodeViewMode)mode;
- (instancetype)initWithMode:(GLCPasscodeViewMode)mode inputMode:(GLCPasscodeInputMode)inputMode;

@end
