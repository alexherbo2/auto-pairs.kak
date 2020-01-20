# Auto-pairs

**Surround** has moved to [surround.kak].

[surround.kak]: https://github.com/alexherbo2/surround.kak

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

### Custom pairs

``` kak
set-option -add global auto_pairs （ ） ｛ ｝ ［ ］ 〈 〉 『 』 「 」
```

## Commands

- `auto-pairs-enable`: Enable automatic closing of pairs
- `auto-pairs-disable`: Disable automatic closing of pairs
- `auto-pairs-toggle`: Toggle automatic closing of pairs

## Options

- `auto_pairs` `str-list`: List of pairs (Default: `` ( ) { } [ ] '"' '"' "'" "'" ` ` “ ” ‘ ’ « » ‹ › ``)
- `auto_pairs_enabled` `bool`: Whether auto-pairs is active (Read-only)

## Credits

Thanks to [maximbaz] for all the good suggestions he did on the extension.

## Collaborators

_Push access to the repository_

- [maximbaz] (2018-10-06)

[Demo]: images/demo.gif
[Kakoune]: https://kakoune.org
[Travis]: https://travis-ci.org/alexherbo2/auto-pairs.kak
[Badge]: https://travis-ci.org/alexherbo2/auto-pairs.kak.svg
[IRC]: https://webchat.freenode.net/#kakoune
[IRC Badge]: https://img.shields.io/badge/IRC-%23kakoune-blue.svg
[Pathogen]: https://github.com/alexherbo2/pathogen.kak
[maximbaz]: https://github.com/maximbaz
