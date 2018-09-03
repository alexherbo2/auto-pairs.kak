declare-option -docstring 'List of pairs' str-list auto_pairs ( ) { } [ ] < > '"' '"' <single-quote> <single-quote> ` `
declare-option -docstring 'List of pairs' str-list auto_pairs_surround %opt(auto_pairs)
declare-option -docstring 'Information about the way auto-pairs is active' bool auto_pairs_enabled no
declare-option -docstring 'Information about the way auto-pairs-surround is active' bool auto_pairs_surround_enabled no
declare-option -hidden bool auto_pairs_was_enabled

define-command -hidden -params 2 auto-pairs-insert-opener-closer %{
  try %{
    execute-keys -draft ";<a-K>\Q%arg(1)<ret>"
    execute-keys -draft '2h<a-K>\w<ret>'
    auto-pairs-insert-opener %arg(@)
  } catch %{
    auto-pairs-insert-closer %arg(@)
  }
}

define-command -hidden -params 2 auto-pairs-insert-opener %{ try %{
  evaluate-commands %sh{
    echo execute-keys -draft '\;<a-K>\w<ret>'
    IFS=, read anchor cursor <<EOF
      $kak_selection_desc
EOF
    if test $anchor = $cursor; then
      keys=h
    else
      keys=H
    fi
    printf 'execute-keys "%%arg(2)<a-;>%s"\n' "$keys"
  }
}}

define-command -hidden -params 2 auto-pairs-insert-closer %{ try %{
  execute-keys -draft ";<a-k>\Q%arg(2)<ret>d"
}}

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
  auto-pairs-try-execute-keys '\\Q%s\\E\\n\\h*\\Q%s\\E' ';KGl<a-k>%s<ret>'
  execute-keys <up><end><ret>
}}

define-command -hidden auto-pairs-delete-new-line %{ try %{
  auto-pairs-try-execute-keys '\\Q%s\\E\\n\\h*\\Q%s\\E' ';hJGi<a-k>%s<ret>'
  execute-keys <del>
  execute-keys -draft '<a-i><space>d'
}}

define-command -hidden auto-pairs-insert-space %{ try %{
  auto-pairs-try-execute-keys '\\Q%s\\E\\h\\Q%s\\E' ';2H<a-k>%s<ret>'
  execute-keys <space><left>
}}

define-command -hidden auto-pairs-delete-space %{ try %{
  auto-pairs-try-execute-keys '\\Q%s\\E\\h\\Q%s\\E' ';l2H<a-k>%s<ret>'
  execute-keys <del>
}}

define-command -hidden -params 2 auto-pairs-try-execute-keys %{ evaluate-commands %sh{
  regex=$1
  keys=$2
  regex=$(
    eval "set -- $kak_opt_auto_pairs"
    {
      while [ "$1" ]; do
        opener=$1
        closer=$2
        shift 2
        printf "$regex\n" "$opener" "$closer"
      done
    } |
    paste --serial --delimiters '|'
  )
  regex_keys=$(
    echo "$regex" |
    sed '
      s/</{lt}/g
      s/>/{gt}/g
      s/{lt}/<lt>/g
      s/{gt}/<gt>/g
    '
  )
  printf "execute-keys -draft %%($keys)\n" "$regex_keys"
}}

define-command auto-pairs-enable -docstring 'Enable automatic closing of pairs' %{
  evaluate-commands %sh{
    eval "set -- $kak_opt_auto_pairs"
    while [ "$1" ]; do
      [ "$1" = '<single-quote>' ] && opener="'" || opener=$1
      [ "$2" = '<single-quote>' ] && closer="'" || closer=$2
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

define-command auto-pairs-surround -params .. -docstring 'Enable automatic closing of pairs on selection boundaries for the whole insert session' %{
  evaluate-commands %sh{
    if [ "$kak_opt_auto_pairs_enabled" = true ]; then
      echo set-option window auto_pairs_was_enabled yes
    else
      echo set-option window auto_pairs_was_enabled no
    fi
    proceed() {
      while [ "$1" ]; do
        [ "$1" = '<single-quote>' ] && opener="'" || opener=$1
        [ "$2" = '<single-quote>' ] && closer="'" || closer=$2
        shift 2
        printf '%s\n' "hook window InsertChar %-\Q$opener- -group auto-pairs-surround-insert %(auto-pairs-surround-insert-opener %-$opener- %-$closer-)"
        printf '%s\n' "hook window InsertDelete %-\Q$opener- -group auto-pairs-surround-delete %(auto-pairs-surround-delete-opener %-$opener- %-$closer-)"
      done
    }
    proceed "$@"
    eval "set -- $kak_opt_auto_pairs_surround"
    proceed "$@"
  }
  hook window ModeChange insert:normal -group auto-pairs-surround-insert-end %{
    evaluate-commands %sh{
      if [ "$kak_opt_auto_pairs_was_enabled" = true ]; then
        echo auto-pairs-enable
      fi
    }
    remove-hooks window auto-pairs-surround-insert
    remove-hooks window auto-pairs-surround-delete
    remove-hooks window auto-pairs-surround-insert-end
    set-option window auto_pairs_surround_enabled no
  }
  auto-pairs-disable
  set-option window auto_pairs_surround_enabled yes
  execute-keys -with-hooks i
}
