declare-option -docstring 'List of pairs' str-list auto_pairs ( ) { } [ ] '"' '"' "'" "'" ` `
declare-option -docstring 'List of pairs' str-list auto_pairs_surround %opt(auto_pairs)
declare-option -docstring 'Whether auto-pairs is active' bool auto_pairs_enabled no
declare-option -docstring 'Whether auto-pairs-surround is active' bool auto_pairs_surround_enabled no
declare-option -hidden bool auto_pairs_was_enabled

# ┌──────────────────────────────────────────────────────────────────────────────┐
# │ What ┊  1  ┊  2  ┊  3  ┊   4    ┊   5    ┊   6    ┊    7    ┊       8        │
# ├──────────────────────────────────────────────────────────────────────────────┤
# │  "   ┊  ▌  ┊ ""  ┊ ""  ┊ """""" ┊ """""" ┊ """""" ┊ """"""  ┊ """""""""""""" │
# │      ┊     ┊  ‾  ┊   ‾ ┊    ‾   ┊     ‾  ┊      ‾ ┊       ‾ ┊ ⁷     ¹‾     ⁷ │
# ╰──────────────────────────────────────────────────────────────────────────────╯
# What: We inserted _"_
define-command -hidden auto-pairs-opener-or-closer-inserted -params 2 %{ evaluate-commands -save-regs '"/' %{
  try %{
    # Call auto-pairs-closer-inserted if cursor matches to _"_
    # Example:
    # ""
    #  ‾
    execute-keys -draft ";<a-K>\Q%arg(1)<ret>"
    # Jump (Backward) 2 characters
    # Call auto-pairs-closer-inserted if matches a word character
    # Example:
    # JoJo's Bizarre Adventure
    #    ↑ ‾
    execute-keys -draft '2h<a-K>\w<ret>'
    # Select previous consecutive _"_
    # and copy to the copy register.
    # Example:
    # """␤ → """␤
    #    ‾   ‾‾‾
    execute-keys -draft -save-regs '' ";<a-/>\Q%arg(1)\E+<ret>y"
    # And call auto-pairs-opener-inserted to close with the same amount of _"_
    # Example:
    # """␤ → """"""
    #    ‾      ‾
    auto-pairs-opener-inserted %arg(1) %val(main_reg_dquote)
  } catch %{
    # Used to move right
    # Example:
    # ""␤ → ""␤
    #  ‾      ‾
    auto-pairs-closer-inserted %arg(@)
  }
}}

# ┌──────────────────────────┐
# │ What ┊  1  ┊  2  ┊   3   │
# ├──────────────────────────┤
# │  (   ┊  ▌  ┊ (▌) ┊ ((▌)) │
# ╰──────────────────────────╯
# What: We inserted _(_
define-command -hidden auto-pairs-opener-inserted -params 2 %{ try %{
  # Abort if cursor matches a word character
  # Example:
  # (Tchou
  #  ‾
  execute-keys -draft ';<a-K>\w<ret>'
  # Insert closing pair
  # Example:
  # """␤ → """"""␤
  #    ‾   ³ ¹¹ ³‾
  execute-keys %arg(2)
  # Jump to the position before inserting the closing pair
  # Length (Closer)
  set-register L %sh(echo ${#2})
  try %{
    # If selections extend
    execute-keys -draft '<a-k>..<ret>'
    # Preserve anchor position
    # Example:
    # """"""␤ → """"""␤
    # ------‾   ---‾
    execute-keys "<a-;>%reg(L)H"
  } catch %{
    # Jump without preserving
    # Example:
    # """"""␤ → """"""␤
    # ³ ¹¹ ³‾      ‾
    execute-keys "<a-;>%reg(L)h"
  }
}}

# ┌───────────────────────┐
# │ What ┊ Input ┊ Output │
# ├───────────────────────┤
# │  )   ┊  (▌)  ┊  ()▌   │
# ╰───────────────────────╯
# ┌─────────────────────────────────────────┐
# │ What ┊      Input      ┊     Output     │
# ├─────────────────────────────────────────┤
# │      ┊ void main() {   ┊ void main() {  │
# │  }   ┊   return null;▌ ┊   return null; │
# │      ┊ }               ┊ }▌             │
# ╰─────────────────────────────────────────╯
# What: We inserted _)_
define-command -hidden auto-pairs-closer-inserted -params 2 %{ evaluate-commands -save-regs '"^' %{ try %{
  # Position the cursor on the _)_ we inserted
  # Select to the next _)_ containing zero or more whitespaces
  # Delete _)_ we inserted
  # Position the cursor next to the matching _)_ and mark the position
  execute-keys -draft "<a-x><a-K>^\h*\Q%arg(2)\E$<ret>"
  execute-keys -draft -save-regs '' "hF%arg(2)<a-k>\A\Q%arg(2)\E\s*\Q%arg(2)\E\z<ret>Z<a-;>;dz<a-:>lZ"
  try %{
    # If selections extend
    execute-keys -draft '<a-k>..<ret>'
    # Preserve anchor position by extending the selection to the mark
    execute-keys '<a-;><a-z>u'
  } catch %{
    # Jump without preserving
    execute-keys '<a-;>z'
  }
  # Hide message from the status line
  echo
}}}

# ┌───────────────────────┐
# │ What ┊ Input ┊ Output │
# ├───────────────────────┤
# │  ⌫   ┊  "▌"  ┊   ▌    │
# ╰───────────────────────╯
# What: We deleted _"_ left to the cursor
define-command -hidden auto-pairs-opener-or-closer-deleted -params 2 %{ try %{
  auto-pairs-opener-deleted %arg(@)
}}

# ┌───────────────────────┐
# │ What ┊ Input ┊ Output │
# ├───────────────────────┤
# │  ⌫   ┊  (▌)  ┊   ▌    │
# ╰───────────────────────╯
# What: We deleted _(_ left to the cursor
define-command -hidden auto-pairs-opener-deleted -params 2 %{ try %{
  # Try to delete _)_ under the cursor
  # Example:
  # ) → ▌
  # ‾
  execute-keys -draft ";<a-k>\Q%arg(2)<ret>d"
}}

# ┌───────────────────────┐
# │ What ┊ Input ┊ Output │
# ├───────────────────────┤
# │  ⌫   ┊  ()▌  ┊   ▌    │
# ╰───────────────────────╯
# What: We deleted _)_ left to the cursor
define-command -hidden auto-pairs-closer-deleted -params 2 %{ try %{
  # Try to delete _(_ left to the cursor
  # Example:
  # (␤ → ▌
  #  ‾
  execute-keys -draft "h<a-k>\Q%arg(1)<ret>d"
}}

# ┌─────────────────────────────────────────┐
# │ What ┊      Input      ┊     Output     │
# ├─────────────────────────────────────────┤
# │      ┊ void main() {▌} ┊ void main() {  │
# │  ⏎   ┊                 ┊   ▌            │
# │      ┊                 ┊ }              │
# ╰─────────────────────────────────────────╯
# What: We inserted a new line
define-command -hidden auto-pairs-new-line-inserted %{ try %{
  # Select from the cursor to the last character of the previous line
  # and try to match a pair.
  # Example:
  # void main() {␤ → void main() {␤
  # }                }           ‾‾
  # ‾                ‾
  evaluate-commands -draft %{
    execute-keys ';KGl'
    auto-pairs-match-pair '\Q${opener}\E\n\h*\Q${closer}\E'
  }
  # Issue: Indentation is wrong when inserting in pair
  # https://github.com/mawww/kakoune/issues/2806
  execute-keys -draft 'K<a-&>'
  # Insert a new line again
  execute-keys <up><end><ret>
}}

# ┌─────────────────────────────────────────┐
# │ What ┊     Input      ┊     Output      │
# ├─────────────────────────────────────────┤
# │      ┊ void main() {  ┊ void main() {▌} │
# │  ⌫   ┊ ▌              ┊                 │
# │      ┊ }              ┊                 │
# ╰─────────────────────────────────────────╯
# What: We deleted a new line character
define-command -hidden auto-pairs-new-line-deleted %{ try %{
  # Try to match a pair by selecting
  # from the previous character
  # to the first non blank character (skipping eventual indent).
  # Example:
  # void main() {␤ → void main() {␤
  # }            ‾   }           ‾‾
  #                  ‾
  evaluate-commands -draft %{
    execute-keys ';hJGi'
    auto-pairs-match-pair '\Q${opener}\E\n\h*\Q${closer}\E'
  }
  # Example:
  # void main() {▌ → void main() {▌}
  # }
  execute-keys <del>
  # Try to delete eventual spaces, used for indentation
  execute-keys -draft '<a-i><space>d'
}}

# ┌──────────────────────────────┐
# │ What ┊  1  ┊   2   ┊    3    │
# ├──────────────────────────────┤
# │  ␣   ┊ (▌) ┊ ( ▌ ) ┊ (  ▌  ) │
# ╰──────────────────────────────╯
# What: We inserted a space
define-command -hidden auto-pairs-space-inserted %[ evaluate-commands -save-regs '"KL' %[ try %[
  # Try to match a pair
  # Example:
  # ( ) → ( )
  #   ‾   ‾‾‾
  evaluate-commands -draft %{
    execute-keys ';<a-?>\H<ret><a-:>H?\H<ret>'
    auto-pairs-match-pair '\Q${opener}\E\h+\Q${closer}\E'
  }
  # Select previous consecutive spaces
  # and copy to the copy register
  # Example:
  # (  ) → (  ) → (  )
  #    ‾     ‾     ‾‾
  execute-keys -draft -save-regs '' ';h{<space>y'
  # Length (Padding)
  set-register L %sh(echo ${#kak_main_reg_dquote})
  # Key (Extend)
  # If selections extend
  try %[ execute-keys -draft '<a-k>..<ret>'
    # Preserve anchor position
    set-register K H
  ] catch %[
    # Jump without preserving
    set-register K h
  ]
  # Delete spaces right to the cursor
  try %(execute-keys -draft ';}<space>d')
  # Adjust padding
  execute-keys "<c-r>""<a-;>%reg(L)%reg(K)"
]]]

# ┌──────────────────────────────┐
# │ What ┊    1    ┊   2   ┊  3  │
# ├──────────────────────────────┤
# │  ⌫   ┊ (  ▌  ) ┊ ( ▌ ) ┊ (▌) │
# ╰──────────────────────────────╯
# What: We deleted a space left to the cursor
define-command -hidden auto-pairs-space-deleted %[ evaluate-commands -save-regs '"KL' %[ try %[
  # Try to match a pair with at least one space inside,
  # otherwise nothing to do.
  # Example:
  # (  ) → (  )
  #    ‾   ‾‾‾‾
  evaluate-commands -draft %{
    execute-keys ';<a-?>\H<ret><a-:>H?\H<ret>'
    auto-pairs-match-pair '\Q${opener}\E\h+\Q${closer}\E'
  }
  try %[
    # Select previous consecutive spaces
    # and copy to the copy register
    # Example:
    # (  ) → (  ) → (  )
    #    ‾     ‾     ‾‾
    execute-keys -draft -save-regs '' ';h{<space>y'
    # Length (Padding)
    set-register L %sh(echo ${#kak_main_reg_dquote})
    # Key (Extend)
    # If selections extend
    try %[ execute-keys -draft '<a-k>..<ret>'
      # Preserve anchor position
      set-register K H
    ] catch %[
      # Jump without preserving
      set-register K h
    ]
    # Delete spaces right to the cursor
    try %(execute-keys -draft ';}<space>d')
    # Adjust padding
    execute-keys "<c-r>""<a-;>%reg(L)%reg(K)"
  ] catch %[
    execute-keys '<del>'
  ]
]]]

# Try to match a pair against selections
define-command -hidden auto-pairs-match-pair -params 1 %{
  evaluate-commands -save-regs '/' %{
    set-register / %sh{
      regex=$1
      eval "set -- $kak_quoted_opt_auto_pairs"
      while test $# -ge 2; do
        opener=$1
        closer=$2
        shift 2
        printf '%s\n' "$regex" | sed "
          s/\${opener}/${opener}/g
          s/\${closer}/${closer}/g
        "
      done | paste -s -d '|' -
    }
    execute-keys '<a-k><ret>'
  }
}

hook global WinSetOption auto_pairs=.* %{ evaluate-commands %sh{
  if test $kak_opt_auto_pairs_enabled = true; then
    printf 'auto-pairs-%s;' disable enable
  fi
}}

define-command auto-pairs-enable -docstring 'Enable automatic closing of pairs' %{
  evaluate-commands %sh{
    eval "set -- $kak_quoted_opt_auto_pairs"
    while test $# -ge 2; do
      opener=$1
      closer=$2
      shift 2
      if [ "$opener" = "$closer" ]; then
        printf '%s\n' "hook window InsertChar %-\Q$opener- -group auto-pairs %(auto-pairs-opener-or-closer-inserted %-$opener- %-$closer-)"
        printf '%s\n' "hook window InsertDelete %-\Q$opener- -group auto-pairs %(auto-pairs-opener-or-closer-deleted %-$opener- %-$closer-)"
      else
        printf '%s\n' "hook window InsertChar %-\Q$opener- -group auto-pairs %(auto-pairs-opener-inserted %-$opener- %-$closer-)"
        printf '%s\n' "hook window InsertDelete %-\Q$opener- -group auto-pairs %(auto-pairs-opener-deleted %-$opener- %-$closer-)"
        printf '%s\n' "hook window InsertChar %-\Q$closer- -group auto-pairs %(auto-pairs-closer-inserted %-$opener- %-$closer-)"
        printf '%s\n' "hook window InsertDelete %-\Q$closer- -group auto-pairs %(auto-pairs-closer-deleted %-$opener- %-$closer-)"
      fi
    done
  }
  hook window InsertChar \n -group auto-pairs auto-pairs-new-line-inserted
  hook window InsertDelete \n -group auto-pairs auto-pairs-new-line-deleted
  hook window InsertChar \h -group auto-pairs auto-pairs-space-inserted
  hook window InsertDelete \h -group auto-pairs auto-pairs-space-deleted
  set-option window auto_pairs_enabled yes
}

define-command auto-pairs-disable -docstring 'Disable automatic closing of pairs' %{
  remove-hooks window auto-pairs
  set-option window auto_pairs_enabled no
}

define-command auto-pairs-toggle -docstring 'Toggle automatic closing of pairs' %{ evaluate-commands %sh{
  if [ "$kak_opt_auto_pairs_enabled" = true ]; then
    echo auto-pairs-disable
  else
    echo auto-pairs-enable
  fi
}}

# ┌────────────────────────┐
# │ What ┊ Input ┊ Output  │
# ├────────────────────────┤
# │  (   ┊ Tchou ┊ (Tchou) │
# │      ┊ ‾‾‾‾‾ ┊  ‾‾‾‾‾  │
# ╰────────────────────────╯
# What: We inserted _(_ in insert (i) mode
define-command -hidden auto-pairs-surround-opener-inserted -params 2 %{
  # Insert closing pair
  execute-keys -draft "<a-;>a%arg(2)"
}

# ┌─────────────────────────┐
# │ What ┊  Input  ┊ Output │
# ├─────────────────────────┤
# │  ⌫   ┊ (Tchou) ┊ Tchou  │
# │      ┊  ‾‾‾‾‾  ┊ ‾‾‾‾‾  │
# ╰─────────────────────────╯
# What: We deleted _(_ in insert (i) mode
define-command -hidden auto-pairs-surround-opener-deleted -params 2 %{
  # Try to delete the closing pair
  execute-keys -draft "<a-;>l<a-k>\Q%arg(2)<ret>d"
}

# ┌──────────────────────────────────────────┐
# │ What ┊    1    ┊     2     ┊      3      │
# ├──────────────────────────────────────────┤
# │  ␣   ┊ (Tchou) ┊ ( Tchou ) ┊ (  Tchou  ) │
# │      ┊  ‾‾‾‾‾  ┊   ‾‾‾‾‾   ┊    ‾‾‾‾‾    │
# ╰──────────────────────────────────────────╯
# What: We inserted a space in insert (i) mode
define-command -hidden auto-pairs-surround-space-inserted %{ try %{
  # Try to match a pair
  # Example:
  # (␣Tchou) → (␣Tchou)
  #   ‾‾‾‾‾    ‾‾‾‾‾‾‾‾
  evaluate-commands -draft %{
    execute-keys '<a-?>\H<ret><a-:>?\H<ret>'
    auto-pairs-match-pair '\Q${opener}\E.+\Q${closer}\E'
  }
  try %{
    # Copy padding left
    # and apply to the right
    execute-keys -draft 'Zh<a-i><space>yz<a-:>l<a-i><space>R'
  } catch %{
    execute-keys -draft 'a<space>'
  }
}}

# ┌──────────────────────────────────────────┐
# │ What ┊      1      ┊     2     ┊    3    │
# ├──────────────────────────────────────────┤
# │  ⌫   ┊ (  Tchou  ) ┊ ( Tchou ) ┊ (Tchou) │
# │      ┊    ‾‾‾‾‾    ┊   ‾‾‾‾‾   ┊  ‾‾‾‾‾  │
# ╰──────────────────────────────────────────╯
# What: We deleted a space in insert (i) mode
define-command -hidden auto-pairs-surround-space-deleted %{ try %{
  # Try to match a pair
  # Example:
  # (␣Tchou␣␣) → (␣Tchou␣␣)
  #   ‾‾‾‾‾      ‾‾‾‾‾‾‾‾‾‾
  evaluate-commands -draft %{
    execute-keys '<a-?>\H<ret><a-:>?\H<ret>'
    auto-pairs-match-pair '\Q${opener}\E.+\Q${closer}\E'
  }
  try %{
    # Copy padding left
    # and apply to the right
    execute-keys -draft 'Zh<a-i><space>yz<a-:>l<a-i><space>R'
  } catch %{
    # Delete right spaces
    execute-keys -draft '<a-:>l<a-i><space>d'
  }
}}

define-command auto-pairs-surround -params .. -docstring 'Enable automatic closing of pairs on selection boundaries for the whole insert session' %{
  evaluate-commands %sh{
    if [ "$kak_opt_auto_pairs_enabled" = true ]; then
      echo set-option window auto_pairs_was_enabled yes
    else
      echo set-option window auto_pairs_was_enabled no
    fi
    # Issue: No way to access %arg(@) from shell
    # https://github.com/mawww/kakoune/issues/2353
    iterate() {
      while test $# -ge 2; do
        opener=$1
        closer=$2
        shift 2
        printf '%s\n' "hook window InsertChar %-\Q$opener- -group auto-pairs-surround %(auto-pairs-surround-opener-inserted %-$opener- %-$closer-)"
        printf '%s\n' "hook window InsertDelete %-\Q$opener- -group auto-pairs-surround %(auto-pairs-surround-opener-deleted %-$opener- %-$closer-)"
      done
    }
    eval "iterate $kak_quoted_opt_auto_pairs_surround"
    iterate "$@"
  }
  hook window InsertChar \h -group auto-pairs-surround auto-pairs-surround-space-inserted
  hook window InsertDelete \h -group auto-pairs-surround auto-pairs-surround-space-deleted
  hook -once window ModeChange insert:normal %{
    evaluate-commands %sh{
      if [ "$kak_opt_auto_pairs_was_enabled" = true ]; then
        echo auto-pairs-enable
      fi
    }
    remove-hooks window auto-pairs-surround
    set-option window auto_pairs_surround_enabled no
  }
  auto-pairs-disable
  set-option window auto_pairs_surround_enabled yes
  execute-keys -with-hooks i
}
