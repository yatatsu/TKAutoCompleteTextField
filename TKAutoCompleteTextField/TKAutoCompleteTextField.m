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
static CGFloat kBufferHeightForSuggestionView = 10.f;

static NSString *kCellIdentifier = @"cell";
static NSString *kObserverKeyMatchSuggestions = @"matchSuggestions";

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
    
    [self configureSuggestionView];
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
    
}

- (void)stopObserving
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeObserver:self forKeyPath:kObserverKeyMatchSuggestions];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath compare:kObserverKeyMatchSuggestions] == NSOrderedSame) {
        [self didChangeMatchSuggestions];
    }
}

#pragma mark - Event

- (BOOL)becomeFirstResponder
{
    [self startObserving];
    return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
    self.suggestionView.hidden = YES;
    [self stopObserving];
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
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [wself suggestionView:wself.suggestionView updateFrameWithSuggestions:wself.matchSuggestions];
        wself.suggestionView.hidden = NO;
        [wself.suggestionView reloadData];
    });
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
                        [resultSuggestions addObject:suggestion];
                    }
                }];
            }
        } else {
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
    height += rowCount * suggestionView.rowHeight + self.frame.size.height;
    if ([self.autoCompleteDataSource respondsToSelector:@selector(heightForSuggestionView:)]) {
        CGFloat maxHeight = [self.autoCompleteDataSource heightForSuggestionView:suggestionView];
        if (maxHeight < height) {
            height = maxHeight;
        }
    }
    return height;
}

- (NSInteger)numberOfVisibleRowInSuggestionView:(UITableView *)suggestionView
{
    if ([self.autoCompleteDataSource respondsToSelector:@selector(numberOfVisibleRowInSuggestionView:)]) {
        return [self.autoCompleteDataSource numberOfVisibleRowInSuggestionView:suggestionView];
    } else {
        return kDefaultNumberOfVisibleRowInSuggestionView;
    }
}

- (void)showSuggestionView
{
    [self.superview bringSubviewToFront:self];
    UIView *rootView = self.window.subviews[0];
    [rootView insertSubview:self.suggestionView
               belowSubview:self];
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = self.matchSuggestions.count;
    // show tableView
    if (count) {
        [self showSuggestionView];
    } else {
        // TODO: dismiss
    }
    return count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return self.frame.size.height;
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
