provide-module auto-pairs %{

  # Modules ────────────────────────────────────────────────────────────────────

  require-module prelude

  # Options ────────────────────────────────────────────────────────────────────

  declare-option -docstring 'List of surrounding pairs' str-list auto_pairs ( ) { } [ ] '"' '"' "'" "'" ` ` “ ” ‘ ’ « » ‹ ›

  declare-option -hidden str-list auto_pairs_saved_pairs
  declare-option -hidden str auto_pairs_match_pairs
  declare-option -hidden str auto_pairs_match_nestable_pairs

  # Commands ───────────────────────────────────────────────────────────────────

  define-command auto-pairs-enable -docstring 'Enable auto-pairs' %{
    auto-pairs-save-settings
    # Create mappings for padding and deleting pairs.
    map global insert <ret> '<a-;>: auto-pairs-insert-new-line<ret>'
    map global insert <space> '<a-;>: auto-pairs-insert-space<ret>'
    map global insert <backspace> '<a-;>: auto-pairs-delete-with-backspace<ret>'
    # map global insert <del> '<a-;>: auto-pairs-delete-with-delete<ret>'
    # Update auto-pairs on option changes
    hook -group auto-pairs global WinSetOption auto_pairs=.* %{
      auto-pairs-save-settings
    }
  }

  define-command auto-pairs-disable -docstring 'Disable auto-pairs' %{
    # Remove mappings
    evaluate-commands %sh{
      . "$kak_opt_prelude_path"
      eval "set -- $kak_quoted_opt_auto_pairs"
      for key do
        kak_escape unmap global insert "$key"
      done
    }
    unmap global insert <ret>
    unmap global insert <space>
    unmap global insert <backspace>
    # unmap global insert <del>
    # Unset options
    set-option global auto_pairs_saved_pairs
    set-option global auto_pairs_match_pairs ''
    set-option global auto_pairs_match_nestable_pairs ''
  }

  # Option commands ────────────────────────────────────────────────────────────

  define-command -hidden auto-pairs-save-settings %{
    # Create mappings for auto-paired characters.
    # Build regexes for matching surrounding pairs.
    evaluate-commands %sh{
      . "$kak_opt_prelude_path"
      # Remove mappings from the previous set.
      eval "set -- $kak_quoted_opt_auto_pairs_saved_pairs"
      for key do
        kak_escape unmap global insert "$key"
      done
      # Initialization
      eval "set -- $kak_quoted_opt_auto_pairs"
      # Regexes
      match_pairs=''
      match_nestable_pairs=''
      while test $# -ge 2; do
        opening=$1 closing=$2
        shift 2
        # Create mappings for auto-paired characters.
        if test "$opening" = "$closing"; then
          auto_pairs_insert_pairing=$(kak_escape auto-pairs-insert-pairing "$opening" "$closing")
          kak_escape map global insert "$opening" "<a-;>: $auto_pairs_insert_pairing<ret>"
        else
          auto_pairs_insert_opening=$(kak_escape auto-pairs-insert-opening "$opening" "$closing")
          auto_pairs_insert_closing=$(kak_escape auto-pairs-insert-closing "$opening" "$closing")
          kak_escape map global insert "$opening" "<a-;>: $auto_pairs_insert_opening<ret>"
          kak_escape map global insert "$closing" "<a-;>: $auto_pairs_insert_closing<ret>"
          # Build regex for matching nestable pairs.
          match_nestable_pairs="$match_nestable_pairs|(\\A\\Q$opening\\E\s*\\Q$closing\\E\\z)"
        fi
        # Build regex for matching surrounding pairs.
        match_pairs="$match_pairs|(\\A\\Q$opening\\E\s*\\Q$closing\\E\\z)"
      done
      # Set regex options
      match_pairs=${match_pairs#|}
      match_nestable_pairs=${match_nestable_pairs#|}
      kak_escape set-option global auto_pairs_match_pairs "$match_pairs"
      kak_escape set-option global auto_pairs_match_nestable_pairs "$match_nestable_pairs"
    }
    # Save surrounding pairs
    set-option global auto_pairs_saved_pairs %opt{auto_pairs}
  }

  # Implementation commands ────────────────────────────────────────────────────

  define-command -hidden auto-pairs-insert-pairing -params 2 %{
    try %{
      # Move right in pair
      # "▌" ⇒ ""▌
      auto-pairs-cursor-keep-fixed-string %arg{2}
      auto-pairs-move-right
    } catch %{
      # Insert post pair
      # ""▌ ⇒ ""▌
      auto-pairs-cursor-keep-fixed-string %arg{2} 'h'
      execute-keys %arg{1}
    } catch %{
      # Insert closing pair
      # Skip escaped pairs
      auto-pairs-cursor-reject-fixed-string '\' 'h'
      # Skip **on** or **preceded** by a word character.
      # 🄹🄾🅹🄾
      auto-pairs-cursor-reject '\w'
      # JoJo▌
      auto-pairs-cursor-reject '\w' 'h'
      # Commit auto-pairing
      auto-pairs-insert-pair %arg{1} %arg{2}
    } catch %{
      execute-keys -with-hooks %arg{1}
    }
  }

  define-command -hidden auto-pairs-insert-opening -params 2 %{
    try %{
      # Skip escaped pairs
      auto-pairs-cursor-reject-fixed-string '\' 'h'
      # Skip **on** a word character.
      # 🅹🄾🄹🄾
      auto-pairs-cursor-reject '\w'
      # Commit auto-pairing
      # main▌ ⇒ main(▌)
      auto-pairs-insert-pair %arg{1} %arg{2}
    } catch %{
      execute-keys -with-hooks %arg{1}
    }
  }

  define-command -hidden auto-pairs-insert-closing -params 2 %{
    try %{
      # Move right in pair
      # (▌) ⇒ ()▌
      auto-pairs-cursor-keep-fixed-string %arg{2}
      auto-pairs-move-right
    } catch %{
      execute-keys -with-hooks %arg{2}
    }
  }

  define-command -hidden auto-pairs-insert-new-line %{
    try %{
      # Insert an additional line in pair
      # main() {▌}
      auto-pairs-keep-surrounding-pairs ';H'
      # main() {
      #   ▌
      # }
      execute-keys '<ret><ret><esc>KK<a-&>j<a-gt>A<esc>'
      execute-keys -with-hooks 'i'
    } catch %{
      execute-keys -with-hooks '<ret>'
    }
  }

  # Space padding in pair (only nestable pairs and with a padding already balanced).
  define-command -hidden auto-pairs-insert-space %{
    try %{
      # Empty content
      # (▌)
      auto-pairs-keep-nestable-pairs ';H'
      # (␣▌␣)
      auto-pairs-insert-pair ' ' ' '
    } catch %{
      # Only with a padding already balanced
      # (␣▌␣)
      auto-pairs-keep-nestable-pairs '<a-i><space>L<a-;>H'
      auto-pairs-keep-balanced-space-padding
      # (␣␣▌␣␣)
      auto-pairs-insert-pair ' ' ' '
    } catch %{
      execute-keys -with-hooks '<space>'
    }
  }

  # Delete in pair: "▌"
  # Delete post pair: ()▌
  define-command -hidden auto-pairs-delete-with-backspace %{
    auto-pairs-delete-implementation '<backspace>' ';H' 'hH'
  }

  # Delete in pair: "▌"
  # Delete pre pair: ▌()
  define-command -hidden auto-pairs-delete-with-delete %{
    auto-pairs-delete-implementation '<del>' ';H' ';L'
  }

  # auto-pairs-delete-implementation <delete-key> <select-in-pair-delete> <select-near-pair-delete>
  define-command -hidden auto-pairs-delete-implementation -params 3 %{
    try %{
      # Delete in pair
      # "▌" ⇒ ▌
      auto-pairs-keep-surrounding-pairs %arg{2}
      execute-keys -draft "%arg{2}d"
    } catch %{
      # Delete near nestable pairs
      #
      # Post pair with Backspace:
      # ()▌ ⇒ ▌
      #
      # Pre pair with Delete:
      # ▌() ⇒ ▌
      auto-pairs-keep-nestable-pairs %arg{3}
      execute-keys -draft "%arg{3}d"
    } catch %{
      # Delete empty line
      auto-pairs-cursor-keep '^\n'
      # Test a surrounding pair with the surrounding characters.
      # main() {
      # ▌
      # }
      auto-pairs-keep-surrounding-pairs ';JGl<a-;>KGl'
      # Join in pair
      # main() {▌}
      execute-keys -draft '<a-a><space>d'
    } catch %{
      # Space padding in pair (only nestable pairs)
      # (␣␣▌␣␣)
      auto-pairs-keep-nestable-pairs '<a-i><space>L<a-;>H'
      auto-pairs-keep-balanced-space-padding
      # Commit padding
      # (␣▌␣)
      execute-keys '<backspace><del>'
    } catch %{
      execute-keys -with-hooks %arg{1}
    }
  }

  # Utility commands ───────────────────────────────────────────────────────────

  # Keep surrounding pairs
  define-command -hidden auto-pairs-keep-surrounding-pairs -params ..1 %{
    auto-pairs-keep %opt{auto_pairs_match_pairs} %arg{1}
  }

  # Keep nestable pairs
  define-command -hidden auto-pairs-keep-nestable-pairs -params ..1 %{
    auto-pairs-keep %opt{auto_pairs_match_nestable_pairs} %arg{1}
  }

  # Insert pair
  # Jump backwards in pair, before inserting.
  define-command -hidden auto-pairs-insert-pair -params 2 %{
    auto-pairs-insert-text "%arg{1}%arg{2}"
    auto-pairs-move-left
  }

  # Insert text
  define-command -hidden auto-pairs-insert-text -params 1 %{
    # A bit verbose, but more robust than passing text to execute-keys.
    evaluate-commands -save-regs '"' %{
      set-register '"' %arg{1}
      execute-keys '<c-r>"'
    }
  }

  # Commands to move the cursor and preserve the anchor position.
  define-command -hidden auto-pairs-move-left %{
    auto-pairs-move-in-pair-implementation 'h' 'H'
  }
  define-command -hidden auto-pairs-move-right %{
    auto-pairs-move-in-pair-implementation 'l' 'L'
  }
  define-command -hidden auto-pairs-move-in-pair-implementation -params 2 %{
    # If something is selected (i.e. the selection is not just the cursor),
    # preserve the anchor position.
    try %{
      # Test if extending
      execute-keys -draft '<a-k>.{2,}<ret>'
      # Preserve anchor position
      execute-keys '<a-;>' %arg{2}
    } catch %{
      # Jump without preserving
      execute-keys '<a-;>' %arg{1}
    }
  }

  # Keep balanced space padding.
  define-command -hidden auto-pairs-keep-balanced-space-padding %{
    evaluate-commands -draft -save-regs '/' %{
      execute-keys -draft -save-regs '' 'h[<space>*'
      set-register / "\A%reg{/}\z"
      execute-keys -draft ']<space><a-k><ret>'
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
  define-command -hidden auto-pairs-keep-fixed-string -params 1..2 %{
    auto-pairs-keep "\Q%arg{1}\E" %arg{2}
  }
  define-command -hidden auto-pairs-cursor-keep-fixed-string -params 1..2 %{
    auto-pairs-keep-fixed-string %arg{1} ";%arg{2}"
  }

  # Reject
  define-command -hidden auto-pairs-reject -params 1..2 %{
    auto-pairs-keep-implementation '<a-K>' %arg{@}
  }
  define-command -hidden auto-pairs-cursor-reject -params 1..2 %{
    auto-pairs-reject %arg{1} ";%arg{2}"
  }
  define-command -hidden auto-pairs-reject-fixed-string -params 1..2 %{
    auto-pairs-reject "\Q%arg{1}\E" %arg{2}
  }
  define-command -hidden auto-pairs-cursor-reject-fixed-string -params 1..2 %{
    auto-pairs-reject-fixed-string %arg{1} ";%arg{2}"
  }
}
