# TKAutoCompleteTextField

[![Version](https://img.shields.io/cocoapods/v/TKAutoCompleteTextField.svg?style=flat)](http://cocoadocs.org/docsets/TKAutoCompleteTextField)
[![License](https://img.shields.io/cocoapods/l/TKAutoCompleteTextField.svg?style=flat)](http://cocoadocs.org/docsets/TKAutoCompleteTextField)
[![Platform](https://img.shields.io/cocoapods/p/TKAutoCompleteTextField.svg?style=flat)](http://cocoadocs.org/docsets/TKAutoCompleteTextField)

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

// you can select whether or not suggestion in empty input.
self.autoCompleteTextField.enablePreInputSearch = YES; // default is NO

```

it's all.

## Other

### Delegates

- ``TKAutoCompleteTextField:heightForSuggestionView:`` : specify max height.
- ``TKAutoCompleteTextField:numberOfVisibleRowInSuggestionView:`` : specify limit of visible suggestion count.
  - default count is 3.

### properties

- ``enableAutoComplete`` : show suggestion view.
- ``enableStrictFirstMatch`` : left-hand match or partical match.
- ``enablePreInputSearch`` : show suggestion view when input is empty.
- ``marginLefTextPlaceholder``
- ``marginTopTextPlaceholder``

## auther

[yatatsu](https://github.com/yatatsu), yatatsukitagawa@gmail.com
