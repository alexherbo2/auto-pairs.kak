# auto-pairs.kak

Auto-paired characters for [Kakoune].

## Installation

Add [`auto-pairs.kak`](rc/auto-pairs.kak) to your autoload or source it manually.

## Usage

Enable auto-pairs (enabled by default) with `auto-pairs-enable`.
Auto-paired characters can be changed via the `auto_pairs` option.

## Surrounding pairs

By default, `auto_pairs` includes the following surrounding pairs.

```
Parenthesis block: ( )
Braces block: { }
Brackets block: [ ]
Double quote string: " "
Single quote string: ' '
Grave quote string: ` `
Double quotation mark: “ ”
Single quotation mark: ‘ ’
Double angle quotation mark: « »
Single angle quotation mark: ‹ ›
```

[Kakoune]: https://kakoune.org
