# Auto-pairs

[![Build Status][Badge]][Travis]
[![IRC][IRC Badge]][IRC]

###### [Usage](#usage) | [Documentation](#commands) | [Contributing](CONTRIBUTING)

> [Kakoune] extension to enable automatic closing of pairs.

![Demo]

## Features

### Normal (Around cursors)

#### Close pair

```
┌──────────────────────────┐
│ What ┊  1  ┊  2  ┊   3   │
├──────────────────────────┤
│  (   ┊  ▌  ┊ (▌) ┊ ((▌)) │
╰──────────────────────────╯
```

#### Move in pair

```
┌───────────────────────┐
│ What ┊ Input ┊ Output │
├───────────────────────┤
│  )   ┊  (▌)  ┊  ()▌   │
╰───────────────────────╯
```

#### Jump to closing pair

```
┌─────────────────────────────────────────┐
│ What ┊      Input      ┊     Output     │
├─────────────────────────────────────────┤
│      ┊ void main() {   ┊ void main() {  │
│  }   ┊   return null;▌ ┊   return null; │
│      ┊ }               ┊ }▌             │
╰─────────────────────────────────────────╯
```

#### Pair padding and movements (Same pair)

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ What ┊  1  ┊  2  ┊  3  ┊   4    ┊   5    ┊   6    ┊    7    ┊       8        │
├──────────────────────────────────────────────────────────────────────────────┤
│  "   ┊  ▌  ┊ ""  ┊ ""  ┊ """""" ┊ """""" ┊ """""" ┊ """"""  ┊ """""""""""""" │
│      ┊     ┊  ‾  ┊   ‾ ┊    ‾   ┊     ‾  ┊      ‾ ┊       ‾ ┊ ⁷     ¹‾     ⁷ │
╰──────────────────────────────────────────────────────────────────────────────╯
```

#### Delete in pair

```
┌───────────────────────┐
│ What ┊ Input ┊ Output │
├───────────────────────┤
│  ⌫   ┊  (▌)  ┊   ▌    │
╰───────────────────────╯
```

#### Delete post pair

```
┌───────────────────────┐
│ What ┊ Input ┊ Output │
├───────────────────────┤
│  ⌫   ┊  ()▌  ┊   ▌    │
╰───────────────────────╯
```

#### New line in pair

```
┌─────────────────────────────────────────┐
│ What ┊      Input      ┊     Output     │
├─────────────────────────────────────────┤
│      ┊ void main() {▌} ┊ void main() {  │
│  ⏎   ┊                 ┊   ▌            │
│      ┊                 ┊ }              │
╰─────────────────────────────────────────╯
```

```
┌─────────────────────────────────────────┐
│ What ┊     Input      ┊     Output      │
├─────────────────────────────────────────┤
│      ┊ void main() {  ┊ void main() {▌} │
│  ⌫   ┊ ▌              ┊                 │
│      ┊ }              ┊                 │
╰─────────────────────────────────────────╯
```

#### Space padding

```
┌──────────────────────────────┐
│ What ┊  1  ┊   2   ┊    3    │
├──────────────────────────────┤
│  ␣   ┊ (▌) ┊ ( ▌ ) ┊ (  ▌  ) │
╰──────────────────────────────╯
```

```
┌──────────────────────────────┐
│ What ┊    1    ┊   2   ┊  3  │
├──────────────────────────────┤
│  ⌫   ┊ (  ▌  ) ┊ ( ▌ ) ┊ (▌) │
╰──────────────────────────────╯
```

### Surround (Around selections)

#### Close pair

```
┌────────────────────────┐
│ What ┊ Input ┊ Output  │
├────────────────────────┤
│  (   ┊ Tchou ┊ (Tchou) │
│      ┊ ‾‾‾‾‾ ┊  ‾‾‾‾‾  │
╰────────────────────────╯
```

#### Delete in pair

```
┌─────────────────────────┐
│ What ┊  Input  ┊ Output │
├─────────────────────────┤
│  ⌫   ┊ (Tchou) ┊ Tchou  │
│      ┊  ‾‾‾‾‾  ┊ ‾‾‾‾‾  │
╰─────────────────────────╯
```

#### Space padding

```
┌──────────────────────────────────────────┐
│ What ┊    1    ┊     2     ┊      3      │
├──────────────────────────────────────────┤
│  ␣   ┊ (Tchou) ┊ ( Tchou ) ┊ (  Tchou  ) │
│      ┊  ‾‾‾‾‾  ┊   ‾‾‾‾‾   ┊    ‾‾‾‾‾    │
╰──────────────────────────────────────────╯
```

```
┌──────────────────────────────────────────┐
│ What ┊      1      ┊     2     ┊    3    │
├──────────────────────────────────────────┤
│  ⌫   ┊ (  Tchou  ) ┊ ( Tchou ) ┊ (Tchou) │
│      ┊    ‾‾‾‾‾    ┊   ‾‾‾‾‾   ┊  ‾‾‾‾‾  │
╰──────────────────────────────────────────╯
```

## Installation

### [Pathogen]

``` kak
pathogen-infect /home/user/repositories/github.com/alexherbo2/auto-pairs.kak
```

## Usage

``` kak
hook global WinCreate .* %{
  auto-pairs-enable
}
```

``` kak
map global user s -docstring 'Surround' ': auto-pairs-surround <lt> <gt><ret>'
```

``` kak
map global user S -docstring 'Surround++' ': auto-pairs-surround <lt> <gt> _ _ * *<ret>'
```

### Custom pairs

``` kak
set-option -add global auto_pairs （ ） ｛ ｝ ［ ］ 〈 〉 『 』 「 」
```

### Per file-type settings

``` kak
hook global WinSetOption filetype=markdown %{
  set-option -add buffer auto_pairs_surround _ _ * *
}
```

### Status line integration

``` kak
set-option global modelinefmt '… %opt(block_auto_pairs) …'

declare-option -hidden str block_auto_pairs

define-command -hidden block-update-auto-pairs %{ evaluate-commands %sh{
  if [ $kak_opt_auto_pairs_surround_enabled = true ]; then
    text=surround
  else
    text="''"
  fi
  echo set-option window block_auto_pairs $text
}}

hook global WinCreate .* %{
  hook window ModeChange 'normal:insert|insert:normal' block-update-auto-pairs
}
```

## Commands

- `auto-pairs-enable`: Enable automatic closing of pairs
- `auto-pairs-disable`: Disable automatic closing of pairs
- `auto-pairs-toggle`: Toggle automatic closing of pairs
- `auto-pairs-surround`: Enable automatic closing of pairs on selection boundaries for the whole insert session

## Options

- `auto_pairs` `str-list`: List of pairs (Default: `` ( ) { } [ ] '"' '"' "'" "'" ` ` ``)
- `auto_pairs_surround` `str-list`: List of pairs (Default: `%opt(auto_pairs)`)
- `auto_pairs_enabled` `bool`: Whether auto-pairs is active (Read-only)
- `auto_pairs_surround_enabled` `bool`: Whether auto-pairs-surround is active (Read-only)

## Credits

Thanks to [maximbaz] for all the good suggestions he did on the extension.

## Collaborators

_Push access to the repository_

- [maximbaz] (2018-10-06)

[Demo]: images/demo.gif
[Kakoune]: https://kakoune.org
[Travis]: https://travis-ci.org/alexherbo2/auto-pairs.kak
[Badge]: https://travis-ci.org/alexherbo2/auto-pairs.kak.svg
[IRC]: https://webchat.freenode.net?channels=kakoune
[IRC Badge]: https://img.shields.io/badge/IRC-%23kakoune-blue.svg
[Pathogen]: https://github.com/alexherbo2/pathogen.kak
[maximbaz]: https://github.com/maximbaz
