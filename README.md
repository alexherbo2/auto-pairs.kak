[![IRC][shields/kakoune/badge]][freenode/kakoune]

[Kakoune][] extension to enable automatic closing of pairs.

Installation
------------

``` sh
ln --symbolic $PWD/rc $XDG_CONFIG_HOME/kak/autoload/auto-pairs
```

Testing
-------

To test, just type `run` in the [test/](test) directory.

Usage
-----

``` kak
hook global WinCreate .* %{
  auto-pairs-enable
}
```

``` kak
map global user s :auto-pairs-surround<ret>
```

Commands
--------

- `auto-pairs-enable`: enable automatic closing of pairs
- `auto-pairs-disable`: disable automatic closing of pairs
- `auto-pairs-toggle`: toggle automatic closing of pairs
- `auto-pairs-surround`: enable automatic closing of pairs on selection boundaries for the whole insert session

Options
-------

- `auto_pairs` `str-list`: list of pairs (default: `(,):{,}:[,]:<,>:",":',':<grave-quote>,<grave-quote>`)
- `auto_pairs_enabled` `bool`: information about the way auto-pairs is active (read-only)
- `auto_pairs_surround_enabled` `bool`: information about the way auto-pairs-surround is active (read-only)

[Kakoune]: https://github.com/mawww/kakoune
[freenode/kakoune]: https://webchat.freenode.net?channels=kakoune
[shields/kakoune/badge]: https://img.shields.io/badge/IRC-%23kakoune-blue.svg
