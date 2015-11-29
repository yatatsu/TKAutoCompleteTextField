//
//  TKAutoCompleteTextField.m
//  TKAutoCompleteTextField
//
//  Created by 北川達也 on 2014/08/13.
//  Copyright (c) 2014年 Tatsuya Kitagawa. All rights reserved.
//

#import "TKAutoCompleteTextField.h"

static NSInteger kDefaultNumberOfVisibleRowInSuggestionView = 3;
static CGFloat kDefaultHeightForRowInSuggestionView = 30.f;
static CGFloat kBufferHeightForSuggestionView = 15.f;

static NSString *kCellIdentifier = @"cell";
static NSString *kObserverKeyMatchSuggestions = @"matchSuggestions";
static NSString *kObserverKeyBorderStyle = @"borderStyle";
static NSString *kObserverKeyEnableAutoComplete = @"enableAutoComplete";
static NSString *kObserverKeyEnableStrictFirstMatch = @"enableStrictFirstMatch";
static NSString *kObserverKeyEnablePreInputSearch = @"enablePreInputSearch";

static CGFloat kDefaultLeftMarginTextPlaceholder = 5.f;
static CGFloat kDefaultTopMarginTextPlaceholder = 0.f;

@interface TKAutoCompleteTextField () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong, readwrite) UITableView *suggestionView;
@property (nonatomic, strong) NSMutableArray *matchSuggestions;
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, assign, getter = isInputFromSuggestion) BOOL inputFromSuggestion;

@end

@implementation TKAutoCompleteTextField

#pragma mark - Initialize

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize
{
    self.suggestions = [NSArray new];
    self.matchSuggestions = [NSMutableArray array];
    self.queue = [NSOperationQueue new];
    self.inputFromSuggestion = NO;
    self.enableAutoComplete = YES;
    self.enableStrictFirstMatch = NO;
    self.enablePreInputSearch = NO;
    self.marginLefTextPlaceholder = kDefaultLeftMarginTextPlaceholder;
    self.marginTopTextPlaceholder = kDefaultTopMarginTextPlaceholder;
    
    [self configureSuggestionView];
}

- (void)dealloc
{
    [self stopObserving];
    [self removeSuggestionView];
    self.matchSuggestions = nil;
}

#pragma mark - Observation

- (void)startObserving
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textFieldDidChangeNotification:)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:self];
    [self addObserver:self
           forKeyPath:kObserverKeyMatchSuggestions
              options:NSKeyValueObservingOptionNew
              context:nil];

    [self addObserver:self
           forKeyPath:kObserverKeyBorderStyle
              options:NSKeyValueObservingOptionNew
              context:nil];
    
    [self addObserver:self
           forKeyPath:kObserverKeyEnableAutoComplete
              options:NSKeyValueObservingOptionNew
              context:nil];
    
    [self addObserver:self
           forKeyPath:kObserverKeyEnableStrictFirstMatch
              options:NSKeyValueObservingOptionNew
              context:nil];
}

- (void)stopObserving
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    @try {
        [self removeObserver:self forKeyPath:kObserverKeyMatchSuggestions];
        [self removeObserver:self forKeyPath:kObserverKeyBorderStyle];
        [self removeObserver:self forKeyPath:kObserverKeyEnableAutoComplete];
        [self removeObserver:self forKeyPath:kObserverKeyEnableStrictFirstMatch];
    }
    @catch (NSException *exception) {
        // wasn't observing anyway
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath compare:kObserverKeyMatchSuggestions] == NSOrderedSame) {
        [self didChangeMatchSuggestions];
    } else if ([keyPath compare:kObserverKeyBorderStyle] == NSOrderedSame) {
        [self didChangeTextFieldBorderStyle];
    } else if ([keyPath compare:kObserverKeyEnableAutoComplete] == NSOrderedSame) {
        [self didChangeEnableAutoComplete];
    } else if ([keyPath compare:kObserverKeyEnableStrictFirstMatch] == NSOrderedSame) {
        [self didChangeEnableStrictFirstMatch];
    } else if ([keyPath compare:kObserverKeyEnablePreInputSearch] == NSOrderedSame) {
        [self didChangeEnablePreInputSearch];
    }
}

#pragma mark - Event

- (BOOL)becomeFirstResponder
{
    [self startObserving];
    if ([self enablePreInputSearch]) {
        [self searchSuggestionWithInput:self.text];
    }
    return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
    [self stopObserving];
    [self removeSuggestionView];
    return [super resignFirstResponder];
}

- (void)textFieldDidChangeNotification:(NSNotification *)notification
{
    if ([self isInputFromSuggestion]) {
        self.inputFromSuggestion = NO;
        return;
    }
    [self cancelSearchOperation];
    [self searchSuggestionWithInput:self.text];
}

- (void)didChangeMatchSuggestions
{
    if (!self.enableAutoComplete) {
        return;
    }
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [wself suggestionView:wself.suggestionView updateFrameWithSuggestions:wself.matchSuggestions];
        wself.suggestionView.hidden = NO;
        [wself.suggestionView reloadData];
    });
}

- (void)didChangeTextFieldBorderStyle
{
    [self configureSuggestionViewForBorderStyle:self.borderStyle];
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [wself.suggestionView reloadData];
    });
}

- (void)didChangeEnableAutoComplete
{
    if (self.enableAutoComplete) {
        if ([self isFirstResponder]) {
            [self startObserving];
        }
    } else {
        [self cancelSearchOperation];
        [self stopObserving];
        [self removeSuggestionView];
    }
}

- (void)didChangeEnableStrictFirstMatch
{
    if ([self isFirstResponder]) {
        [self cancelSearchOperation];
        [self searchSuggestionWithInput:self.text];
    }
}

- (void)didChangeEnablePreInputSearch
{
    if ([self isFirstResponder]) {
        [self cancelSearchOperation];
        [self searchSuggestionWithInput:self.text];
    }
}

#pragma mark - fetch suggestion

- (void)cancelSearchOperation
{
    [self.queue cancelAllOperations];
    [self.matchSuggestions removeAllObjects];
}

- (void)searchSuggestionWithInput:(NSString *)input
{
    NSBlockOperation *operation = [[NSBlockOperation alloc] init];
    __weak NSBlockOperation *weakOperation = operation;
    __weak typeof(self) wself = self;
    NSArray *suggestions = self.suggestions;
    NSMutableArray *resultSuggestions = [NSMutableArray array];
    [operation addExecutionBlock:^{
        if (weakOperation.isCancelled) return;

        if (input.length > 0) {
            @autoreleasepool {
                [suggestions enumerateObjectsUsingBlock:^(NSString *suggestion, NSUInteger idx, BOOL *stop) {
                    NSRange range = [[suggestion lowercaseString] rangeOfString:[input lowercaseString]];
                    if (range.location != NSNotFound) {
                        if (wself.enableStrictFirstMatch && range.location > 0) {
                            return;
                        } else {
                            [resultSuggestions addObject:suggestion];
                        }
                    }
                }];
            }
        } else if ([self enablePreInputSearch]) {
            [resultSuggestions addObjectsFromArray:suggestions];
        }
    }];
    [operation setCompletionBlock:^{
        if (weakOperation.isCancelled) return;
        
        wself.matchSuggestions = resultSuggestions;
    }];

    [self.queue addOperation:operation];
}


#pragma mark - suggestionView

- (void)configureSuggestionView
{
    CGRect frame = self.frame;
    UITableView *suggestionView = [[UITableView alloc] initWithFrame:frame
                                                               style:UITableViewStylePlain];
    suggestionView.rowHeight = frame.size.height ?: kDefaultHeightForRowInSuggestionView;
    suggestionView.separatorStyle = UITableViewCellSeparatorStyleNone;
    suggestionView.delegate = self;
    suggestionView.dataSource = self;
    suggestionView.scrollEnabled = YES;
    suggestionView.hidden = YES;
    
    self.suggestionView = suggestionView;
}

- (void)suggestionView:(UITableView *)suggestionView updateFrameWithSuggestions:(NSArray *)suggestions
{
    CGRect frame = suggestionView.frame;
    frame.size.height = [self heightForSuggestionView:suggestionView suggestionsCount:suggestions.count];
    suggestionView.frame = frame;
}

- (CGFloat)heightForSuggestionView:(UITableView *)suggestionView suggestionsCount:(NSInteger)count
{
    CGFloat height = 0.f;
    NSInteger rowCount = [self numberOfVisibleRowInSuggestionView:suggestionView];
    if (rowCount > count) {
        rowCount = count;
    } else {
        height += kBufferHeightForSuggestionView;
    }
    height += rowCount * suggestionView.rowHeight;
    if (self.borderStyle != UITextBorderStyleNone) {
        height += self.frame.size.height;
    }
    if ([self.autoCompleteDataSource respondsToSelector:@selector(TKAutoCompleteTextField:heightForSuggestionView:)]) {
        CGFloat maxHeight = [self.autoCompleteDataSource TKAutoCompleteTextField:self heightForSuggestionView:suggestionView];
        if (maxHeight < height) {
            height = maxHeight;
        }
    }
    return height;
}

- (NSInteger)numberOfVisibleRowInSuggestionView:(UITableView *)suggestionView
{
    if ([self.autoCompleteDataSource respondsToSelector:@selector(TKAutoCompleteTextField:numberOfVisibleRowInSuggestionView:)]) {
        return [self.autoCompleteDataSource TKAutoCompleteTextField:self numberOfVisibleRowInSuggestionView:suggestionView];
    } else {
        return kDefaultNumberOfVisibleRowInSuggestionView;
    }
}

- (void)showSuggestionView
{
    [self configureSuggestionViewForBorderStyle:self.borderStyle];
    if (_overView) {
        CGPoint pt = [_overView convertPoint:self.frame.origin fromView:self.superview];
        _suggestionView.frame = CGRectMake(pt.x, pt.y+self.frame.size.height,
                                           _suggestionView.frame.size.width, _suggestionView.frame.size.height);
        [_overView addSubview:_suggestionView];
    } else {
        [self.superview bringSubviewToFront:self];
        [self.superview insertSubview:self.suggestionView
                         belowSubview:self];
    }
    self.suggestionView.userInteractionEnabled = YES;
}

- (void)removeSuggestionView
{
    [self.suggestionView removeFromSuperview];
}

#pragma mark - UITextBorderStyle

- (void)configureSuggestionViewForBorderStyle:(UITextBorderStyle)borderStyle
{
    switch (borderStyle) {
        case UITextBorderStyleRoundedRect:
            [self setBorderStyleRoundedRect];
            break;
        case UITextBorderStyleBezel:
            self.backgroundColor = [UIColor whiteColor];
            [self setBorderStyleBezel];
            break;
        case UITextBorderStyleLine:
            self.backgroundColor = [UIColor whiteColor];
            [self setBorderStyleLine];
            break;
        case UITextBorderStyleNone:
            [self setBorderStyleNone];
            break;
    }
}

- (void)setBorderStyleRoundedRect
{
    CGFloat offsetHeight = self.frame.size.height;
    [self.suggestionView.layer setCornerRadius:6.0];
    [self.suggestionView setScrollIndicatorInsets:UIEdgeInsetsMake(offsetHeight, 0, 0, 0)];
    [self.suggestionView setContentInset:UIEdgeInsetsMake(offsetHeight, 0, 0, 0)];
    [self.suggestionView.layer setBorderWidth:0.5];
    [self.suggestionView.layer setBorderColor:[UIColor lightGrayColor].CGColor];
}

- (void)setBorderStyleBezel
{
    CGFloat offsetHeight = self.frame.size.height;
    [self.suggestionView.layer setCornerRadius:0.0];
    [self.suggestionView setScrollIndicatorInsets:UIEdgeInsetsMake(offsetHeight, 0, 0, 0)];
    [self.suggestionView setContentInset:UIEdgeInsetsMake(offsetHeight, 0, 0, 0)];
    [self.suggestionView.layer setBorderWidth:0.5];
    [self.suggestionView.layer setBorderColor:[UIColor lightGrayColor].CGColor];
}

- (void)setBorderStyleLine
{
    CGFloat offsetHeight = self.frame.size.height;
    [self.suggestionView.layer setCornerRadius:0.0];
    [self.suggestionView setScrollIndicatorInsets:UIEdgeInsetsMake(offsetHeight, 0, 0, 0)];
    [self.suggestionView setContentInset:UIEdgeInsetsMake(offsetHeight, 0, 0, 0)];
    [self.suggestionView.layer setBorderWidth:0.5];
    [self.suggestionView.layer setBorderColor:[UIColor lightGrayColor].CGColor];
}

- (void)setBorderStyleNone
{
    CGFloat offsetHeight = self.frame.size.height;
    [self.suggestionView.layer setCornerRadius:0.0];
    [self.suggestionView setScrollIndicatorInsets:UIEdgeInsetsZero];
    CGRect frame = self.suggestionView.frame;
    frame.origin.y = self.frame.origin.y + offsetHeight;
    self.suggestionView.frame = frame;
    [self.suggestionView.layer setBorderWidth:0.5];
    [self.suggestionView.layer setBorderColor:[UIColor lightGrayColor].CGColor];
}


// placeholder position
- (CGRect)textRectForBounds:(CGRect)bounds {
    return CGRectInset(bounds, self.marginLefTextPlaceholder, self.marginTopTextPlaceholder);
}

// text position
- (CGRect)editingRectForBounds:(CGRect)bounds {
    return CGRectInset(bounds, self.marginLefTextPlaceholder, self.marginTopTextPlaceholder);
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = self.matchSuggestions.count;
    if (count) {
        [self showSuggestionView];
    }
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.suggestionView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:kCellIdentifier];
    }
    
    if (self.matchSuggestions.count > indexPath.row) {
        cell.textLabel.text = self.matchSuggestions[indexPath.row];
        cell.textLabel.font = self.font;
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *suggestion = self.matchSuggestions[indexPath.row];
    if ([self.autoCompleteDelegate respondsToSelector:@selector(TKAutoCompleteTextField:didSelectSuggestion:)]) {
        [self.autoCompleteDelegate TKAutoCompleteTextField:self didSelectSuggestion:suggestion];
    }

    self.text = suggestion;
    self.inputFromSuggestion = YES;
    [self.suggestionView deselectRowAtIndexPath:indexPath animated:NO];
    self.matchSuggestions = [NSMutableArray array];
    
    if ([self.autoCompleteDelegate respondsToSelector:@selector(TKAutoCompleteTextField:didFillAutoCompleteWithSuggestion:)]) {
        [self.autoCompleteDelegate TKAutoCompleteTextField:self didFillAutoCompleteWithSuggestion:suggestion];
    }
}

@end
