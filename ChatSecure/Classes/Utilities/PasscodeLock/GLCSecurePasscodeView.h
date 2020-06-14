//
//  GLCSecurePasscodeView.h
//  Q-municate
//
//  Created by YuriyFpc on 11.10.17.
//  Copyright © 2017 Quickblox. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GLCSecurePasscodeViewDelegate <NSObject>

- (void) enter;

@end

@interface GLCSecurePasscodeView : UIStackView

@property (weak, nonatomic) IBOutlet UIImageView *firstCircle;
@property (weak, nonatomic) IBOutlet UIImageView *secondCircle;
@property (weak, nonatomic) IBOutlet UIImageView *thirdCircle;
@property (weak, nonatomic) IBOutlet UIImageView *fourthCircle;
@property (weak, nonatomic) IBOutlet UIImageView *fifthCircle;
@property (weak, nonatomic) IBOutlet UIImageView *sixthCircle;

@property (nonatomic, strong) IBOutletCollection(UIImageView) NSArray *imageViews;
@property (nonatomic, assign) NSUInteger numbersCount;

@property (weak, nonatomic) id<GLCSecurePasscodeViewDelegate> delegate;

- (void) appendNumber:(NSString *) number;
- (void) deleteNumber;
- (void) deleteAllNumber;

- (void)shakeAndVibrateCompletion:(void (^)(void))completionBlock;

@end
