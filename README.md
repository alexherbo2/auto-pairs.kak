# Auto-pairs

[![Build Status][Badge]][Travis]
[![IRC][IRC Badge]][IRC]

###### [Usage](#usage) | [Documentation](#commands) | [Contributing](CONTRIBUTING)

> [Kakoune] extension to enable automatic closing of pairs.

## Installation

``` sh
ln --symbolic $PWD/rc $XDG_CONFIG_HOME/kak/autoload/auto-pairs
```

## Usage

``` kak
hook global WinCreate .* %{
  auto-pairs-enable
}
```

``` kak
map global user s :auto-pairs-surround<ret>
```

``` kak
map global user S ':auto-pairs-surround _ _ * *<ret>'
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

- `auto_pairs` `str-list`: List of pairs (Default: `( ) { } [ ] < > '"' '"' <single-quote> <single-quote> <grave-quote> <grave-quote>`)
- `auto_pairs_surround` `str-list`: List of pairs (Default: `%opt(auto_pairs)`)
- `auto_pairs_enabled` `bool`: Information about the way auto-pairs is active (Read-only)
- `auto_pairs_surround_enabled` `bool`: Information about the way auto-pairs-surround is active (Read-only)

## Credits

Thanks to [maximbaz] for all the good suggestions he did on the extension.

[Kakoune]: http://kakoune.org
[Travis]: https://travis-ci.org/alexherbo2/auto-pairs.kak
[Badge]: https://travis-ci.org/alexherbo2/auto-pairs.kak.svg
[IRC]: https://webchat.freenode.net?channels=kakoune
[IRC Badge]: https://img.shields.io/badge/IRC-%23kakoune-blue.svg
[maximbaz]: https://github.com/maximbaz
