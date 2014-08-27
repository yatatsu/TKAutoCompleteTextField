//
//  TKAutoCompleteTextFieldDataSource.h
//  TKAutoCompleteTextField
//
//  Created by 北川達也 on 2014/08/13.
//  Copyright (c) 2014年 Tatsuya Kitagawa. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TKAutoCompleteTextField;

@protocol TKAutoCompleteTextFieldDataSource <NSObject>

@optional
- (CGFloat)TKAutoCompleteTextField:(TKAutoCompleteTextField *)textField
           heightForSuggestionView:(UITableView *)suggestionView;
- (NSInteger)TKAutoCompleteTextField:(TKAutoCompleteTextField *)textField
  numberOfVisibleRowInSuggestionView:(UITableView *)suggestionView;

@end
