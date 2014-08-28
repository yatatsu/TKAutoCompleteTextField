# TKAutoCompleteTextField

TKAutoCompleteTextField is UITextField with simple auto complete.
It shows list of suggestion below textField when you input some character.

![alt tag](https://github.com/yatatsu/TKAutoCompleteTextField/blob/master/TKAutoCompleteTextFieldSample.png)

## Usage

Set TKAutoCompleteTextField in xib or storyboard, and add property. Then, 

```ViewController.m

// configure suggestions
self.autoCompleteTextField.suggestions = @[@"apple", @"orange", @"grape", @"lemon"];

// you can select match type; left-hand match or partical match.
self.autoCompleteTextField.enableStrictFirstMatch = YES; // default is NO

```

it's all.

## Other

these delegate methods are all optional.

- ``TKAutoCompleteTextField:heightForSuggestionView:`` : specify max height.
- ``TKAutoCompleteTextField:numberOfVisibleRowInSuggestionView:`` : specify limit of visible suggestion count.
  - default count is 3.

## auther

[yatatsu](https://github.com/yatatsu), yatatsukitagawa@gmail.com