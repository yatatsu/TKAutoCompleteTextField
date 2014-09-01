//
//  ViewController.m
//  TKAutoCompleteTextField
//
//  Created by 北川達也 on 2014/08/10.
//  Copyright (c) 2014年 Tatsuya Kitagawa. All rights reserved.
//

#import "ViewController.h"

typedef NS_ENUM(NSInteger, TKAutoCompleteSampleType) {
    TKAutoCompleteSampleTypeRoundRect = 1,
    TKAutoCompleteSampleTypeBorderNone,
    TKAutoCompleteSampleTypeLine,
};

@interface ViewController () <TKAutoCompleteTextFieldDataSource, TKAutoCompleteTextFieldDelegate>

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // sample 1
    self.textFieldSample1.suggestions = [self resourse];
    self.textFieldSample1.enableStrictFirstMatch = NO;
    
    // sample 2
    self.textFieldSample2.suggestions = [self resourse];
    self.textFieldSample2.enableStrictFirstMatch = YES;
    self.textFieldSample3.autoCompleteDelegate = self;
    self.textFieldSample3.autoCompleteDataSource = self;
    
    // sample 3
    self.textFieldSample3.suggestions = [self prefecture];
    self.textFieldSample3.enableStrictFirstMatch = NO;
    self.textFieldSample3.enablePreInputSearch = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)didTapCancelButton:(id)sender
{
    [self.view endEditing:YES];
}

- (NSArray *)resourse
{
    static dispatch_once_t onceToken;
    static NSArray *__instance = nil;
    dispatch_once(&onceToken, ^{
        __instance = [self loadArray];
    });
    return __instance;
}

- (NSArray *)prefecture
{
    static dispatch_once_t onceToken;
    static NSArray *__instance = nil;
    dispatch_once(&onceToken, ^{
        __instance = [self loadPrefecture];
    });
    return __instance;
}

- (NSArray *)loadArray
{
    return [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"NYY" ofType:@"plist"]];
}

- (NSArray *)loadPrefecture
{
    return [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Japanese" ofType:@"plist"]];
}

#pragma mark - TKAutoCompleteTextFieldDelegate

- (void)TKAutoCompleteTextField:(TKAutoCompleteTextField *)textField
            didSelectSuggestion:(NSString *)suggestion
{
    NSLog(@">>> didSelectSuggestion: %@", suggestion);
}

- (void)TKAutoCompleteTextField:(TKAutoCompleteTextField *)textField
  didFillAutoCompleteWithSuggestion:(NSString *)suggestion
{
    NSLog(@">>> didFillAutoCompleteWithSuggestion: %@", suggestion);
}

#pragma mark = TKAutoCompleteTextFieldDataSource

- (CGFloat)TKAutoCompleteTextField:(TKAutoCompleteTextField *)textField
           heightForSuggestionView:(UITableView *)suggestionView
{
    return 150.f;
}

- (NSInteger)TKAutoCompleteTextField:(TKAutoCompleteTextField *)textField
  numberOfVisibleRowInSuggestionView:(UITableView *)suggestionView
{
    return 2;
}

@end
