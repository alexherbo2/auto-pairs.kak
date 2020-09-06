# auto-pairs.kak

Auto-paired characters for [Kakoune].

When inserting an opening pair, auto-pairs always inserts the closing pair,
unless when under a word character or preceded by a **backslash**, and for non
nestable characters (such as **apostrophes**), when preceded by word characters.

Auto-pairing is also about pair navigation and editing (deleting existing pairs
and formatting in pair).  It can move in pair `(▌)`, delete in pair `(▌)` and
post pair `()▌`, and pad in pair horizontally `(␣▌␣)` and vertically:
```
    …
    foobar {
        ▌
    }
    …
```
.

When inserting an auto-paired character, if the opening and closing characters
are the same (such as double quote strings), auto-pairs will move right in pair
`"▌"` and skip additional pairing post pair `"▌`.

## Features

- Auto-pairing
- Vertical and horizontal padding
- No `sh` call when typing

## Dependencies

- [prelude.kak]

[prelude.kak]: https://github.com/alexherbo2/prelude.kak

## Installation

Add [`auto-pairs.kak`](rc/auto-pairs.kak) to your autoload or source it manually.

``` kak
require-module auto-pairs
```

## Usage

Enable auto-pairs with `auto-pairs-enable`.
Auto-paired characters can be changed via the `auto_pairs` option.

## Surrounding pairs

By default, `auto_pairs` includes the following surrounding pairs:

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

See also [surround.kak] and [manual-indent.kak].

[Kakoune]: https://kakoune.org
[surround.kak]: https://github.com/alexherbo2/surround.kak
[manual-indent.kak]: https://github.com/alexherbo2/manual-indent.kak
