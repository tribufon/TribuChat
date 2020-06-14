//
//  GLCPasscodeViewController.m
//  Q-municate
//
//  Created by YuriyFpc on 11.10.17.
//  Copyright © 2017 Quickblox. All rights reserved.
//

#import "GLCPasscodeViewController.h"
#import "GLCSecurePasscodeView.h"
#import "VENTouchLock.h"
#import "MaterialTextFields.h"

@interface GLCPasscodeViewController () <GLCSecurePasscodeViewDelegate, UITextFieldDelegate>

@property (strong, nonatomic) NSMutableArray *enteredNumbers;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (assign, nonatomic) GLCPasscodeViewMode mode;
@property (assign, nonatomic) GLCPasscodeInputMode inputMode;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UIButton *passcodeOptionsButton;
@property (weak, nonatomic) IBOutlet UIStackView *numbersStackView;
@property (weak, nonatomic) IBOutlet MDCTextField *passwordTextField;

@end

@implementation GLCPasscodeViewController

- (instancetype)initWithMode:(GLCPasscodeViewMode)mode
{
    self = [super init];
    if (self) {
        _mode = mode;
    }
    return self;
}

- (instancetype)initWithMode:(GLCPasscodeViewMode)mode inputMode:(GLCPasscodeInputMode)inputMode
{
    self = [super init];
    if (self) {
        _mode = mode;
        _inputMode = inputMode;
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.enteredNumbers = [NSMutableArray array];
    self.passwordStackView.delegate = self;
    self.cancelButton.hidden = self.mode == GLCPasscodeViewModeEnter;
    [self updateDeleteButton];
    self.passcodeOptionsButton.hidden = !(self.mode == GLCPasscodeViewModeCreate);
   
    if (self.mode == GLCPasscodeViewModeCreate){
        self.inputMode = GLCPasscodeInputModeFourNumbers;
    } else if (self.mode == GLCPasscodeViewModeEnter){
        NSCharacterSet *nonDigitCharacterSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
        NSString *numbersString = [[[VENTouchLock sharedInstance].currentPasscode componentsSeparatedByCharactersInSet:nonDigitCharacterSet] componentsJoinedByString:@""];
        NSUInteger passcodeLangth = [VENTouchLock sharedInstance].currentPasscode.length;
        
        if (passcodeLangth == 4 && numbersString.length == 4){
            self.inputMode = GLCPasscodeInputModeFourNumbers;
        } else if (passcodeLangth == 6 && numbersString.length == 6){
            self.inputMode = GLCPasscodeInputModeSixNumbers;
        } else if (passcodeLangth != numbersString.length){
            self.inputMode = GLCPasscodeInputModeAlphanumeric;
        } else if (passcodeLangth == numbersString.length){
            self.inputMode = GLCPasscodeInputModeCustomNumeric;
        }
    }
    self.passwordStackView.numbersCount = (self.inputMode == GLCPasscodeInputModeFourNumbers)? 4 : 6;
    [self layoutInputView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.inputMode == GLCPasscodeInputModeFourNumbers || self.inputMode == GLCPasscodeInputModeSixNumbers){
        [self deleteAllNumbers];
    } else {
        self.passwordTextField.text = @"";
    }
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.mode != GLCPasscodeViewModeEnter){
        [self.navigationController.navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
        [self.navigationController.navigationBar setShadowImage:[[UIImage alloc] init]];
        [self.navigationController.navigationBar setTranslucent:YES];
        [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    }
    
    [[self.view window] endEditing:YES];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat selfHeight = self.view.bounds.size.height;

    if (selfHeight < 500) {
        [self layoutFromSmallScreen];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)appendNumberAction:(UIButton *)sender {
    NSString *number = [NSString stringWithFormat:@"%zd", sender.tag];
    [self.enteredNumbers addObject:number];
    [self.passwordStackView appendNumber: number];
    [self updateDeleteButton];
}

- (IBAction)cancelAction:(__unused id)sender
{
    if (self.willFinishWithResult) {
        self.willFinishWithResult(NO);
    }
}

- (IBAction)deleteAction:(__unused id)sender
{
    if (self.inputMode == GLCPasscodeInputModeSixNumbers || self.inputMode == GLCPasscodeInputModeFourNumbers){
        [self.enteredNumbers removeLastObject];
        [self.passwordStackView deleteNumber];
        [self updateDeleteButton];
    } else {
        [self.passwordTextField setText:@""];
    }
}

- (IBAction)passcodeOptionsAction:(__unused id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *alphanumAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"QM_STR_CUSTOM_ALPHANUMERIC_CODE", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull __unused action) {
        self.inputMode = GLCPasscodeInputModeAlphanumeric;
        [self layoutInputView];
    }];
    
    UIAlertAction *numericAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"QM_STR_CUSTOM_NUMERIC_CODE", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull __unused action) {
        self.inputMode = GLCPasscodeInputModeCustomNumeric;
        [self layoutInputView];
    }];
    
     int numbersCount = self.passwordStackView.numbersCount == 6 ? 4 : 6;
    UIAlertAction *digitsAction = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%d-%@", numbersCount, NSLocalizedString(@"QM_STR_DIGITS_NUMERIC_CODE", nil)] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull __unused action) {
        self.inputMode = numbersCount == 4 ? GLCPasscodeInputModeFourNumbers : GLCPasscodeInputModeSixNumbers;
        self.passwordStackView.numbersCount = numbersCount;
        [self layoutInputView];
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"QM_STR_CANCEL", nil) style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    [alert addAction:alphanumAction];
    [alert addAction:numericAction];
    [alert addAction:digitsAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)updateDeleteButton
{
    self.deleteButton.enabled = self.enteredNumbers.count > 0 && [self isNumbersMode] ? YES : self.passwordTextField.text.length > 0 && ![self isNumbersMode] ? YES : NO;
}

- (void)deleteAllNumbers{
    [self.passwordStackView deleteAllNumber];
    [self updateDeleteButton];
    [self.enteredNumbers removeAllObjects];
}

- (void)layoutInputView{
    self.passwordTextField.hidden = [self isNumbersMode];
    self.numbersStackView.hidden = ![self isNumbersMode];
    self.passwordStackView.hidden = ![self isNumbersMode];
    
    if (![self isNumbersMode])
    {
        self.passwordTextField.keyboardType = (self.inputMode == GLCPasscodeInputModeAlphanumeric) ? UIKeyboardTypeDefault : UIKeyboardTypeNumberPad;
        self.passwordTextField.text = @"";
        self.passwordTextField.textColor = [UIColor whiteColor];
        [self.passwordTextField becomeFirstResponder];
    } else {
        [self deleteAllNumbers];
    }
}

-(void)dismissKeyboard
{
    [self.passwordTextField resignFirstResponder];
}

- (BOOL)isNumbersMode
{
    return (self.inputMode == GLCPasscodeInputModeSixNumbers || self.inputMode == GLCPasscodeInputModeFourNumbers);
}

#pragma mark - GLCSecurePasscodeViewDelegate

- (void) enter {
    NSString* passcode = [self.enteredNumbers componentsJoinedByString:@""];
    if (self.mode == GLCPasscodeViewModeConfirm) {
        if ([self.confirmPasscode isEqualToString:passcode]){
           [[VENTouchLock sharedInstance] setPasscode:passcode];
            if (self.willFinishWithResult) {
                self.willFinishWithResult(YES);
            }
        }
    } else if (self.mode == GLCPasscodeViewModeCreate) {
        [self presentConfirmationVC];
    } else {
        if ([passcode isEqualToString:[VENTouchLock sharedInstance].currentPasscode]) {
            if (self.willFinishWithResult) {
                self.willFinishWithResult(YES);
            }
        } else {
            [self.passwordStackView shakeAndVibrateCompletion:nil];
        }
    }
    [self.enteredNumbers removeAllObjects];
    [self updateDeleteButton];
}

- (void)layoutFromSmallScreen{
    [self.topView setFrame:CGRectMake(0, -50, 0, 0)];
    [self.passwordStackView setFrame:CGRectMake(self.passwordStackView.frame.origin.x, -15, self.passwordStackView.frame.size.width, self.passwordStackView.frame.size.height)];
    [self.view setNeedsLayout];
}

- (void)presentConfirmationVC{
    GLCPasscodeViewController *confirmPasscodeVC = [[GLCPasscodeViewController alloc] initWithMode:GLCPasscodeViewModeConfirm inputMode:self.inputMode];
    confirmPasscodeVC.willFinishWithResult = self.willFinishWithResult;
    confirmPasscodeVC.confirmPasscode = self.inputMode == GLCPasscodeInputModeFourNumbers || self.inputMode == GLCPasscodeInputModeSixNumbers ? [self.enteredNumbers componentsJoinedByString:@""] : self.passwordTextField.text;
    [self.navigationController pushViewController:confirmPasscodeVC animated:YES];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)__unused textField shouldChangeCharactersInRange:(NSRange)__unused range replacementString:(NSString *)string
{
    if (self.inputMode == GLCPasscodeInputModeCustomNumeric){
        NSCharacterSet *myCharSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
        for (int i = 0; i < (int)[string length]; i++) {
            unichar c = [string characterAtIndex:i];
            if (![myCharSet characterIsMember:c]) {
                return NO;
            }
        }
    }

    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)__unused textField {
    NSString* passcode = self.passwordTextField.text;

    if (self.mode == GLCPasscodeViewModeCreate){
        if (passcode.length < 4) {
//            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"QM_STR_WRONG_PASSWORD_LENGTH", nil)];
        } else {
            [self presentConfirmationVC];
        }
    } else if (self.mode == GLCPasscodeViewModeConfirm) {
        if ([passcode isEqualToString:self.confirmPasscode]){
            [[VENTouchLock sharedInstance] setPasscode:passcode];
            if (self.willFinishWithResult) {
                self.willFinishWithResult(YES);
            }
        } else {
//            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"QM_STR_PASSWORD_DONT_MATCH", nil)];
        }
    } else {
        if ([passcode isEqualToString:[VENTouchLock sharedInstance].currentPasscode]) {
            if (self.willFinishWithResult) {
                self.willFinishWithResult(YES);
            }
        } else {
//            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"QM_STR_WRONG_PASSWORD", nil)];
        }
    }
    [self updateDeleteButton];
}

- (BOOL)textFieldShouldReturn:(UITextField *)__unused textField {
    [self.view endEditing:YES];
    return YES;
}

@end
