declare-option -docstring 'List of pairs' str-list auto_pairs ( ) { } [ ] < > '"' '"' "'" "'" ` `
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
define-command -hidden -params 2 auto-pairs-insert-opener-closer %{ evaluate-commands -save-regs '"/' %{
  try %{
    # Call auto-pairs-insert-closer if cursor matches to _"_
    # Example:
    # ""
    #  ‾
    execute-keys -draft ";<a-K>\Q%arg(1)<ret>"
    # Jump (Backward) 2 characters
    # Call auto-pairs-insert-closer if matches a word character
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
    # And call auto-pairs-insert-opener to close with the same amount of _"_
    # Example:
    # """␤ → """"""
    #    ‾      ‾
    auto-pairs-insert-opener %arg(1) %val(main_reg_dquote)
  } catch %{
    # Used to move right
    # Example:
    # ""␤ → ""␤
    #  ‾      ‾
    auto-pairs-insert-closer %arg(@)
  }
}}

# ┌──────────────────────────┐
# │ What ┊  1  ┊  2  ┊   3   │
# ├──────────────────────────┤
# │  (   ┊  ▌  ┊ (▌) ┊ ((▌)) │
# ╰──────────────────────────╯
# What: We inserted _(_
define-command -hidden -params 2 auto-pairs-insert-opener %{ try %{
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
define-command -hidden -params 2 auto-pairs-insert-closer %{ evaluate-commands -save-regs '"^' %{ try %{
  # Position the cursor on the _)_ we inserted
  # Select to the next _)_ containing zero or more whitespaces
  # Delete _)_ we inserted
  # Position the cursor next to the matching _)_ and mark the position
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
define-command -hidden -params 2 auto-pairs-delete-opener-closer %{ try %{
  auto-pairs-delete-opener %arg(@)
}}

# ┌───────────────────────┐
# │ What ┊ Input ┊ Output │
# ├───────────────────────┤
# │  ⌫   ┊  (▌)  ┊   ▌    │
# ╰───────────────────────╯
# What: We deleted _(_ left to the cursor
define-command -hidden -params 2 auto-pairs-delete-opener %{ try %{
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
define-command -hidden -params 2 auto-pairs-delete-closer %{ try %{
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
define-command -hidden auto-pairs-insert-new-line %{ try %{
  # Select from the cursor to the last character of the previous line
  # and try to match a pair.
  # Example:
  # void main() {␤ → void main() {␤
  # }                }           ‾‾
  # ‾                ‾
  auto-pairs-try-execute-keys '\Q${opener}\E\n\h*\Q${closer}\E' ';KGl'
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
define-command -hidden auto-pairs-delete-new-line %{ try %{
  # Try to match a pair by selecting
  # from the previous character
  # to the first non blank character (skipping eventual indent).
  # Example:
  # void main() {␤ → void main() {␤
  # }            ‾   }           ‾‾
  #                  ‾
  auto-pairs-try-execute-keys '\Q${opener}\E\n\h*\Q${closer}\E' ';hJGi'
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
define-command -hidden auto-pairs-insert-space %[ evaluate-commands -save-regs '"KL' %[ try %[
  # Try to match a pair
  # Example:
  # ( ) → ( )
  #   ‾   ‾‾‾
  auto-pairs-try-execute-keys '\Q${opener}\E\h+\Q${closer}\E' ';<a-?>\H<ret><a-:>H?\H<ret>'
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
define-command -hidden auto-pairs-delete-space %[ evaluate-commands -save-regs '"KL' %[ try %[
  # Try to match a pair with at least one space inside,
  # otherwise nothing to do.
  # Example:
  # (  ) → (  )
  #    ‾   ‾‾‾‾
  auto-pairs-try-execute-keys '\Q${opener}\E\h+\Q${closer}\E' ';<a-?>\H<ret><a-:>H?\H<ret>'
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
define-command -hidden -params 2 auto-pairs-try-execute-keys %{ evaluate-commands -draft -save-regs '/' %{
  execute-keys %arg(2)
  set-register / %sh{
    regex=$1
    eval "set -- $kak_opt_auto_pairs"
    while test $# -ge 2; do
      opener=$1
      closer=$2
      shift 2
      printf '%s\n' "$regex" | sed "
        s/\${opener}/${opener}/g
        s/\${closer}/${closer}/g
      "
    done |
    # --serial
    # --delimiters
    paste -s -d '|'
  }
  execute-keys '<a-k><ret>'
}}

define-command auto-pairs-enable -docstring 'Enable automatic closing of pairs' %{
  evaluate-commands %sh{
    eval "set -- $kak_opt_auto_pairs"
    while test $# -ge 2; do
      opener=$1
      closer=$2
      shift 2
      if [ "$opener" = "$closer" ]; then
        printf '%s\n' "hook window InsertChar %-\Q$opener- -group auto-pairs-insert %(auto-pairs-insert-opener-closer %-$opener- %-$closer-)"
        printf '%s\n' "hook window InsertDelete %-\Q$opener- -group auto-pairs-delete %(auto-pairs-delete-opener-closer %-$opener- %-$closer-)"
      else
        printf '%s\n' "hook window InsertChar %-\Q$opener- -group auto-pairs-insert %(auto-pairs-insert-opener %-$opener- %-$closer-)"
        printf '%s\n' "hook window InsertDelete %-\Q$opener- -group auto-pairs-delete %(auto-pairs-delete-opener %-$opener- %-$closer-)"
        printf '%s\n' "hook window InsertChar %-\Q$closer- -group auto-pairs-insert %(auto-pairs-insert-closer %-$opener- %-$closer-)"
        printf '%s\n' "hook window InsertDelete %-\Q$closer- -group auto-pairs-delete %(auto-pairs-delete-closer %-$opener- %-$closer-)"
      fi
    done
  }
  hook window InsertChar \n -group auto-pairs-insert auto-pairs-insert-new-line
  hook window InsertDelete \n -group auto-pairs-delete auto-pairs-delete-new-line
  hook window InsertChar \h -group auto-pairs-insert auto-pairs-insert-space
  hook window InsertDelete \h -group auto-pairs-delete auto-pairs-delete-space
  set-option window auto_pairs_enabled yes
}

define-command auto-pairs-disable -docstring 'Disable automatic closing of pairs' %{
  remove-hooks window auto-pairs-insert
  remove-hooks window auto-pairs-delete
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
define-command -hidden -params 2 auto-pairs-surround-insert-opener %{
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
define-command -hidden -params 2 auto-pairs-surround-delete-opener %{
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
define-command -hidden auto-pairs-surround-insert-space %{ try %{
  # Try to match a pair
  # Example:
  # (␣Tchou) → (␣Tchou)
  #   ‾‾‾‾‾    ‾‾‾‾‾‾‾‾
  auto-pairs-try-execute-keys '\Q${opener}\E.+\Q${closer}\E' '<a-?>\H<ret><a-:>?\H<ret>'
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
define-command -hidden auto-pairs-surround-delete-space %{ try %{
  # Try to match a pair
  # Example:
  # (␣Tchou␣␣) → (␣Tchou␣␣)
  #   ‾‾‾‾‾      ‾‾‾‾‾‾‾‾‾‾
  auto-pairs-try-execute-keys '\Q${opener}\E.+\Q${closer}\E' '<a-?>\H<ret><a-:>?\H<ret>'
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
        printf '%s\n' "hook window InsertChar %-\Q$opener- -group auto-pairs-surround-insert %(auto-pairs-surround-insert-opener %-$opener- %-$closer-)"
        printf '%s\n' "hook window InsertDelete %-\Q$opener- -group auto-pairs-surround-delete %(auto-pairs-surround-delete-opener %-$opener- %-$closer-)"
      done
    }
    eval "iterate $kak_opt_auto_pairs_surround"
    iterate "$@"
  }
  hook window InsertChar \h -group auto-pairs-surround-insert auto-pairs-surround-insert-space
  hook window InsertDelete \h -group auto-pairs-surround-delete auto-pairs-surround-delete-space
  hook -once window ModeChange insert:normal %{
    evaluate-commands %sh{
      if [ "$kak_opt_auto_pairs_was_enabled" = true ]; then
        echo auto-pairs-enable
      fi
    }
    remove-hooks window auto-pairs-surround-insert
    remove-hooks window auto-pairs-surround-delete
    set-option window auto_pairs_surround_enabled no
  }
  auto-pairs-disable
  set-option window auto_pairs_surround_enabled yes
  execute-keys -with-hooks i
}
