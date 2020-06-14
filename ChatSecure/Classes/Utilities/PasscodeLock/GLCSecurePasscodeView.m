//
//  GLCSecurePasscodeView.m
//  Q-municate
//
//  Created by YuriyFpc on 11.10.17.
//  Copyright © 2017 Quickblox. All rights reserved.
//

#import "GLCSecurePasscodeView.h"

@interface GLCSecurePasscodeView ()
@property (strong, nonatomic) NSMutableArray *enteredNumbers;
@end

@implementation GLCSecurePasscodeView
@synthesize numbersCount;

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _enteredNumbers = [NSMutableArray array];
    }
    return self;
}

- (void) awakeFromNib {
    [super awakeFromNib];
    [self setDefaultState];
}

- (void) setDefaultState {
    for (UIImageView *item in self.imageViews) {
        item.image = [UIImage imageNamed:@"blackCircle"];
    }
}

- (void)setNumbersCount:(NSUInteger)count{
    if (numbersCount != count){
        numbersCount = count;
        if (count == 4){
            [UIView animateWithDuration:0.1 animations:^{
                self.fifthCircle.hidden = YES;
                self.sixthCircle.hidden = YES;
                [self layoutIfNeeded];
            }];
        } else {
            [UIView animateWithDuration:0.1 animations:^{
                self.fifthCircle.hidden = NO;
                self.sixthCircle.hidden = NO;
                [self layoutIfNeeded];
            }];
        }
    }
}

- (NSUInteger)numbersCount{
    return numbersCount == 0 ? 4 : numbersCount;
}

- (void) appendNumber:(NSString *) number {
    NSLog(@"%@ - %@", self, number);
    NSLog(@"%@", self.enteredNumbers);
    UIImageView *imageView = [self.imageViews objectAtIndex:self.enteredNumbers.count];
    imageView.image = [UIImage imageNamed:@"whiteCircle"];
    [self.enteredNumbers addObject:number];

    if (self.enteredNumbers.count == self.numbersCount) {
        [self.enteredNumbers removeAllObjects];
        [self setDefaultState];
        [self.delegate enter];
    }
}

- (void)deleteNumber
{
    UIImageView *imageView = [self.imageViews objectAtIndex:self.enteredNumbers.count - 1];
    imageView.image = [UIImage imageNamed:@"blackCircle"];
    [self.enteredNumbers removeLastObject];
}

- (void)deleteAllNumber
{
    for (int index = 0; index < (int)self.enteredNumbers.count; index++)
    {
        UIImageView *imageView = [self.imageViews objectAtIndex:index];
        imageView.image = [UIImage imageNamed:@"blackCircle"];
    }
    [self.enteredNumbers removeAllObjects];
}

- (void)shakeAndVibrateCompletion:(void (^)(void))completionBlock
{
//    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        if (completionBlock) {
            completionBlock();
        }
    }];
    NSString *keyPath = @"position";
    CABasicAnimation *animation =
    [CABasicAnimation animationWithKeyPath:keyPath];
    [animation setDuration:0.04];
    [animation setRepeatCount:4];
    [animation setAutoreverses:YES];
    CGFloat delta = 10.0;
    CGPoint center = self.center;
    [animation setFromValue:[NSValue valueWithCGPoint:
                             CGPointMake(center.x - delta, center.y)]];
    [animation setToValue:[NSValue valueWithCGPoint:
                           CGPointMake(center.x + delta, center.y)]];
    [[self layer] addAnimation:animation forKey:keyPath];
    [CATransaction commit];
}

@end
