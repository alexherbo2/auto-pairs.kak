declare-option -docstring 'List of pairs' str-list auto_pairs ( ) { } [ ] < > '"' '"' "'" "'" ` `
declare-option -docstring 'List of pairs' str-list auto_pairs_surround %opt(auto_pairs)
declare-option -docstring 'Whether auto-pairs is active' bool auto_pairs_enabled no
declare-option -docstring 'Whether auto-pairs-surround is active' bool auto_pairs_surround_enabled no
declare-option -hidden bool auto_pairs_was_enabled

define-command -hidden -params 2 auto-pairs-insert-opener-closer %{ evaluate-commands -save-regs '"/' %{
  try %{
    execute-keys -draft ";<a-K>\Q%arg(1)<ret>"
    execute-keys -draft '2h<a-K>\w<ret>'
    execute-keys -draft -save-regs '' ";<a-/>\Q%arg(1)\E+<ret>y"
    auto-pairs-insert-opener %arg(1) %val(main_reg_dquote)
  } catch %{
    auto-pairs-insert-closer %arg(@)
  }
}}

define-command -hidden -params 2 auto-pairs-insert-opener %{ try %{
  execute-keys -draft ';<a-K>\w<ret>'
  execute-keys %arg(2)
  # Length
  set-register L %sh(echo ${#2})
  try %{
    execute-keys -draft '<a-k>..<ret>'
    execute-keys "<a-;>%reg(L)H"
  } catch %{
    execute-keys "<a-;>%reg(L)h"
  }
}}

define-command -hidden -params 2 auto-pairs-insert-closer %{ evaluate-commands -save-regs '"^' %{ try %{
  execute-keys -draft -save-regs '' "hF%arg(2)<a-k>\A\Q%arg(2)\E\s*\Q%arg(2)\E\z<ret>Z<a-;>;dz<a-:>lZ"
  try %{
    execute-keys -draft '<a-k>..<ret>'
    execute-keys '<a-;><a-z>u'
  } catch %{
    execute-keys '<a-;>z'
  }
  # Hide message from the status line
  echo
}}}

define-command -hidden -params 2 auto-pairs-delete-opener-closer %{ try %{
  auto-pairs-delete-opener %arg(@)
}}

define-command -hidden -params 2 auto-pairs-delete-opener %{ try %{
  execute-keys -draft ";<a-k>\Q%arg(2)<ret>d"
}}

define-command -hidden -params 2 auto-pairs-delete-closer %{ try %{
  execute-keys -draft "h<a-k>\Q%arg(1)<ret>d"
}}

define-command -hidden auto-pairs-insert-new-line %{ try %{
  auto-pairs-try-execute-keys '\Q${opener}\E\n\h*\Q${closer}\E' ';KGl'
  execute-keys <up><end><ret>
}}

define-command -hidden auto-pairs-delete-new-line %{ try %{
  auto-pairs-try-execute-keys '\Q${opener}\E\n\h*\Q${closer}\E' ';hJGi'
  execute-keys <del>
  execute-keys -draft '<a-i><space>d'
}}

define-command -hidden auto-pairs-insert-space %[ evaluate-commands -save-regs '"KL' %[ try %[
  auto-pairs-try-execute-keys '\Q${opener}\E\h+\Q${closer}\E' ';<a-?>\H<ret><a-:>H?\H<ret>'
  execute-keys -draft -save-regs '' ';h{<space>y'
  # Length
  set-register L %sh(echo ${#kak_main_reg_dquote})
  # Key
  try %[ execute-keys -draft '<a-k>..<ret>'
    set-register K H
  ] catch %[
    set-register K h
  ]
  try %(execute-keys -draft ';}<space>d')
  execute-keys "<c-r>""<a-;>%reg(L)%reg(K)"
]]]

define-command -hidden auto-pairs-delete-space %[ evaluate-commands -save-regs '"KL' %[ try %[
  auto-pairs-try-execute-keys '\Q${opener}\E\h+\Q${closer}\E' ';<a-?>\H<ret><a-:>H?\H<ret>'
  try %[
    execute-keys -draft -save-regs '' ';h{<space>y'
    # Length
    set-register L %sh(echo ${#kak_main_reg_dquote})
    # Key
    try %[ execute-keys -draft '<a-k>..<ret>'
      set-register K H
    ] catch %[
      set-register K h
    ]
    try %(execute-keys -draft ';}<space>d')
    execute-keys "<c-r>""<a-;>%reg(L)%reg(K)"
  ] catch %[
    execute-keys '<del>'
  ]
]]]

define-command -hidden -params 2 auto-pairs-try-execute-keys %{ evaluate-commands -draft -save-regs '/' %{
  execute-keys %arg(2)
  set-register / %sh{
    regex=$1
    eval "set -- $kak_opt_auto_pairs"
    while test $# -ge 2; do
      opener=$1
      closer=$2
      shift 2
      eval echo "$regex"
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

define-command -hidden -params 2 auto-pairs-surround-insert-opener %{
  execute-keys -draft "<a-;>a%arg(2)"
}

define-command -hidden -params 2 auto-pairs-surround-delete-opener %{
  execute-keys -draft "<a-;>l<a-k>\Q%arg(2)<ret>d"
}

define-command -hidden auto-pairs-surround-insert-space %{ try %{
  auto-pairs-try-execute-keys '\Q${opener}\E.+\Q${closer}\E' '<a-?>\H<ret><a-:>?\H<ret>'
  try %{
    execute-keys -draft 'Zh<a-i><space>yz<a-:>l<a-i><space>R'
  } catch %{
    execute-keys -draft 'a<space>'
  }
}}

define-command -hidden auto-pairs-surround-delete-space %{ try %{
  auto-pairs-try-execute-keys '\Q${opener}\E.+\Q${closer}\E' '<a-?>\H<ret><a-:>?\H<ret>'
  try %{
    execute-keys -draft 'Zh<a-i><space>yz<a-:>l<a-i><space>R'
  } catch %{
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
