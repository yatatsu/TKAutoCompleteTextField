//
//  TKAutoCompleteTextField.h
//  TKAutoCompleteTextField
//
//  Created by 北川達也 on 2014/08/13.
//  Copyright (c) 2014年 Tatsuya Kitagawa. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TKAutoCompleteTextFieldDataSource.h"
#import "TKAutoCompleteTextFieldDelegate.h"

@interface TKAutoCompleteTextField : UITextField

// ui
@property (nonatomic, strong, readonly) UITableView *suggestionView;
@property (nonatomic, weak) UIView *overView;

@property (nonatomic, assign) CGFloat marginLefTextPlaceholder;
@property (nonatomic, assign) CGFloat marginTopTextPlaceholder;


// options
@property (nonatomic, assign) BOOL enableAutoComplete; // YES in default
@property (nonatomic, assign) BOOL enableStrictFirstMatch; // NO in default
@property (nonatomic, assign) BOOL enablePreInputSearch; // NO in default

// delegate
@property (nonatomic, weak) id<TKAutoCompleteTextFieldDataSource> autoCompleteDataSource;
@property (nonatomic, weak) id<TKAutoCompleteTextFieldDelegate> autoCompleteDelegate;

@property (nonatomic, strong) NSArray *suggestions;



@end
