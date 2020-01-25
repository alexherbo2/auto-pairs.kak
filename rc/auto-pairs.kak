hook global ModuleLoaded auto-pairs %{
  auto-pairs-enable
}

provide-module auto-pairs %{

  # Options ────────────────────────────────────────────────────────────────────

  declare-option -docstring 'List of surrounding pairs' str-list auto_pairs ( ) { } [ ] '"' '"' "'" "'" ` ` “ ” ‘ ’ « » ‹ ›
  declare-option -docstring 'List of punctuation marks' str-list auto_pairs_punctuation_marks "'"

  declare-option -hidden str auto_pairs_to_regex
  declare-option -hidden str auto_pairs_punctuation_marks_to_regex

  # Commands ───────────────────────────────────────────────────────────────────

  define-command auto-pairs-enable -docstring 'Enable auto-pairs' %{
    # Generate hooks for auto-paired characters.
    # Also build regexes for matching a surrounding pair and punctuation marks.
    evaluate-commands %sh{
      main() {
        eval "set -- $kak_quoted_opt_auto_pairs"
        build_hooks "$@"
        build_regex "$@"
        eval "set -- $kak_quoted_opt_auto_pairs_punctuation_marks"
        build_punctuation_regex "$@"
      }
      build_hooks() {
        while test $# -ge 2; do
          opening=$1 closing=$2
          shift 2
          kak_quoted_opening=$(kak_escape "$opening")
          kak_quoted_closing=$(kak_escape "$closing")
          kak_quoted_opening_regex=$(kak_escape "\\Q$opening\\E")
          kak_quoted_closing_regex=$(kak_escape "\\Q$closing\\E")
          if test "$opening" = "$closing"; then
            echo "
              hook -group auto-pairs global InsertChar $kak_quoted_opening_regex %(auto-pairs-opening-or-closing-inserted $kak_quoted_opening)
              hook -group auto-pairs global InsertDelete $kak_quoted_opening_regex %(auto-pairs-opening-or-closing-deleted $kak_quoted_opening)
            "
          else
            echo "
              hook -group auto-pairs global InsertChar $kak_quoted_opening_regex %(auto-pairs-opening-inserted $kak_quoted_opening $kak_quoted_closing)
              hook -group auto-pairs global InsertDelete $kak_quoted_opening_regex %(auto-pairs-opening-deleted $kak_quoted_opening $kak_quoted_closing)
              hook -group auto-pairs global InsertChar $kak_quoted_closing_regex %(auto-pairs-closing-inserted $kak_quoted_opening $kak_quoted_closing)
              hook -group auto-pairs global InsertDelete $kak_quoted_closing_regex %(auto-pairs-closing-deleted $kak_quoted_opening $kak_quoted_closing)
            "
          fi
        done
      }
      build_regex() {
        regex=''
        while test $# -ge 2; do
          opening=$1 closing=$2
          shift 2
          regex="$regex|(\\A\\Q$opening\\E\s*\\Q$closing\\E\\z)"
        done
        regex=${regex#|}
        kak_quoted_regex=$(kak_escape "$regex")
        printf 'set-option global auto_pairs_to_regex %s\n' "$kak_quoted_regex"
      }
      build_punctuation_regex() {
        regex='['
        for punctuation do
          regex="${regex}${punctuation}"
        done
        regex="${regex}]"
        kak_quoted_regex=$(kak_escape "$regex")
        printf 'set-option global auto_pairs_punctuation_marks_to_regex %s\n' "$kak_quoted_regex"
      }
      kak_escape() {
        for argument do
          printf "'"
          printf '%s' "$argument" | sed "s/'/''/g"
          printf "'"
          printf ' '
        done
      }
      main "$@"
    }
    hook -group auto-pairs global InsertChar '\n' auto-pairs-new-line-inserted
    hook -group auto-pairs global InsertDelete '\n' auto-pairs-new-line-deleted
    hook -group auto-pairs global InsertChar ' ' auto-pairs-space-inserted
    hook -group auto-pairs global InsertDelete ' ' auto-pairs-space-deleted
    # Update auto-pairs on option changes
    hook -group auto-pairs global WinSetOption '(auto_pairs|auto_pairs_punctuation_marks)=.*' %{
      auto-pairs-disable
      auto-pairs-enable
    }
  }

  define-command auto-pairs-disable -docstring 'Disable auto-pairs' %{
    remove-hooks global auto-pairs
  }

  # Implementation commands ────────────────────────────────────────────────────

  # ╭─────────────────────────────╮
  # │ What ┊ 0 ┊  1  ┊  2  ┊  3   │
  # ├─────────────────────────────┤
  # │  "   ┊ ▌ ┊ "▌" ┊ ""▌ ┊ """▌ │
  # ╰─────────────────────────────╯
  define-command -hidden auto-pairs-opening-or-closing-inserted -params 1 %{
    try %{
      # Case 2: Closing inserted
      auto-pairs-cursor-keep-fixed-string %arg{1}
      auto-pairs-closing-inserted %arg{1} %arg{1}
    } catch %{
      # Case 3: Skip post pair
      auto-pairs-cursor-reject-fixed-string %arg{1} '2h'
      # Case 1: Opening inserted
      auto-pairs-opening-inserted %arg{1} %arg{1}
    } catch ''
  }

  # ╭────────────────────────╮
  # │ What ┊ 0 ┊  1  ┊   2   │
  # ├────────────────────────┤
  # │  (   ┊ ▌ ┊ (▌) ┊ ((▌)) │
  # ╰────────────────────────╯
  define-command -hidden auto-pairs-opening-inserted -params 2 %{
    try %{
      # Skip escaped pairs
      auto-pairs-cursor-reject-fixed-string '\' '2h'
      # Abort if opening pair is a punctuation mark and surrounded by word characters
      # JoJo's Bizarre Adventure
      #    ‾ ‾
      auto-pairs-reject "\A\w%opt{auto_pairs_punctuation_marks_to_regex}|%opt{auto_pairs_punctuation_marks_to_regex}\w\z" ';2H'
      # Insert the closing pair
      auto-pairs-insert-text-in-pair %arg{2}
    }
  }

  # ╭───────────────────────╮
  # │ What ┊ Input ┊ Output │
  # ├───────────────────────┤
  # │  )   ┊  (▌)  ┊  ()▌   │
  # ╰───────────────────────╯
  define-command -hidden auto-pairs-closing-inserted -params 2 %{
    try %{
      auto-pairs-cursor-keep-fixed-string %arg{2}
      execute-keys '<backspace>'
      auto-pairs-move-in-pair
    }
  }

  # ╭───────────────────────╮
  # │ What ┊ Input ┊ Output │
  # ├───────────────────────┤
  # │  ⌫   ┊  "▌"  ┊   ▌    │
  # ╰───────────────────────╯
  define-command -hidden auto-pairs-opening-or-closing-deleted -params 1 %{
    auto-pairs-opening-deleted %arg{1} %arg{1}
  }

  # ╭───────────────────────╮
  # │ What ┊ Input ┊ Output │
  # ├───────────────────────┤
  # │  ⌫   ┊  (▌)  ┊   ▌    │
  # ╰───────────────────────╯
  define-command -hidden auto-pairs-opening-deleted -params 2 %{
    try %{
      auto-pairs-cursor-keep-fixed-string %arg{2}
      execute-keys '<del>'
    }
  }

  # ╭───────────────────────╮
  # │ What ┊ Input ┊ Output │
  # ├───────────────────────┤
  # │  ⌫   ┊  ()▌  ┊   ▌    │
  # ╰───────────────────────╯
  define-command -hidden auto-pairs-closing-deleted -params 2 %{
    try %{
      auto-pairs-cursor-keep-fixed-string %arg{1} 'h'
      execute-keys '<backspace>'
    }
  }

  # ╭────────────────────────────────────────╮
  # │ What ┊      Input      ┊    Output     │
  # ├────────────────────────────────────────┤
  # │      ┊ void main() {▌} ┊ void main() { │
  # │  ⏎   ┊                 ┊   ▌           │
  # │      ┊                 ┊ }             │
  # ╰────────────────────────────────────────╯
  define-command -hidden auto-pairs-new-line-inserted %{
    try %{
      # Test a surrounding pair with the chunks of the previous line.
      auto-pairs-keep-surrounding-pair 'giKGl'
      # Copy previous line indent
      execute-keys -draft 'K<a-&>'
      # Insert a new line above
      execute-keys '<up><end><ret>'
      # And indent it
      execute-keys -draft 'K<a-&>j<a-gt>'
    }
  }

  # ╭────────────────────────────────────────╮
  # │ What ┊     Input     ┊     Output      │
  # ├────────────────────────────────────────┤
  # │      ┊ void main() { ┊ void main() {▌} │
  # │  ⌫   ┊ ▌             ┊                 │
  # │      ┊ }             ┊                 │
  # ╰────────────────────────────────────────╯
  define-command -hidden auto-pairs-new-line-deleted %{
    try %{
      # Test a surrounding pair with the chunks of the current and next lines.
      auto-pairs-keep-surrounding-pair ';<a-/>\H<ret>?\S<ret>'
      # Join surrounding pair
      execute-keys -draft '<a-a><space>d'
    }
  }

  # ╭──────────────────────────────╮
  # │ What ┊  0  ┊   1   ┊    2    │
  # ├──────────────────────────────┤
  # │  ␣   ┊ (▌) ┊ (␣▌␣) ┊ (␣␣▌␣␣) │
  # ╰──────────────────────────────╯
  define-command -hidden auto-pairs-space-inserted %{
    try %{
      # Test surrounding line content.
      auto-pairs-keep-surrounding-pair ';<a-/>\H<ret>?\H<ret>'
      auto-pairs-insert-text-in-pair ' '
    }
  }

  # ╭──────────────────────────────╮
  # │ What ┊    0    ┊   1   ┊  2  │
  # ├──────────────────────────────┤
  # │  ⌫   ┊ (␣␣▌␣␣) ┊ (␣▌␣) ┊ (▌) │
  # ╰──────────────────────────────╯
  define-command -hidden auto-pairs-space-deleted %{
    try %{
      # Test surrounding line content.
      auto-pairs-keep-surrounding-pair ';<a-/>\H<ret>?\H<ret>'
      execute-keys '<del>'
    }
  }

  # Utility commands ───────────────────────────────────────────────────────────

  define-command -hidden auto-pairs-keep-surrounding-pair -params ..1 %{
    auto-pairs-keep %opt{auto_pairs_to_regex} %arg{1}
  }

  define-command -hidden auto-pairs-insert-text-in-pair -params 1 %{
    auto-pairs-insert-text %arg{1}
    # Jump backwards in pair, before inserting.
    # If something is selected (i.e. the selection is not just the cursor),
    # preserve the anchor position.
    evaluate-commands -save-regs 'l' %{
      # Length of inserted text
      # Note: ${#1} is unreliable with UTF-8.
      set-register l %sh(printf '%s' "$1" | wc -m)
      try %{
        # Test if extending
        execute-keys -draft '<a-k>.{2,}<ret>'
        # Preserve anchor position
        execute-keys "<a-;>%reg{l}H"
      } catch %{
        # Jump without preserving
        execute-keys "<a-;>%reg{l}h"
      }
    }
  }

  define-command -hidden auto-pairs-insert-text -params 1 %{
    # A bit verbose, but more robust than passing text to execute-keys.
    evaluate-commands -save-regs '"' %{
      set-register '"' %arg{1}
      execute-keys '<c-r>"'
    }
  }

  define-command -hidden auto-pairs-move-in-pair %{
    try %{
      # Test if extending
      execute-keys -draft '<a-k>.{2,}<ret>'
      # Preserve anchor position
      execute-keys '<a-;>L'
    } catch %{
      # Jump without preserving
      execute-keys '<a-;>l'
    }
  }

  # Keep
  define-command -hidden auto-pairs-keep-implementation -params 2..3 %{
    evaluate-commands -draft -save-regs '/' %{
      execute-keys %arg{3}
      set-register / %arg{2}
      execute-keys %arg{1} '<ret>'
    }
  }
  define-command -hidden auto-pairs-keep -params 1..2 %{
    auto-pairs-keep-implementation '<a-k>' %arg{@}
  }
  define-command -hidden auto-pairs-cursor-keep -params 1..2 %{
    auto-pairs-keep %arg{1} ";%arg{2}"
  }
  define-command -hidden auto-pairs-cursor-keep-fixed-string -params 1..2 %{
    auto-pairs-cursor-keep "\Q%arg{1}\E" %arg{2}
  }

  # Reject
  define-command -hidden auto-pairs-reject -params 1..2 %{
    auto-pairs-keep-implementation '<a-K>' %arg{@}
  }
  define-command -hidden auto-pairs-cursor-reject -params 1..2 %{
    auto-pairs-reject %arg{1} ";%arg{2}"
  }
  define-command -hidden auto-pairs-cursor-reject-fixed-string -params 1..2 %{
    auto-pairs-cursor-reject "\Q%arg{1}\E" %arg{2}
  }
}

require-module auto-pairs
