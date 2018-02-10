declare-option str-list auto_pairs %((,):{,}:[,]:<,>:",":',':`,`)
declare-option bool auto_pairs_enabled no
declare-option bool auto_pairs_surround_enabled no
declare-option -hidden bool auto_pairs_was_enabled

define-command -hidden -params 2 auto-pairs-insert-opener %{ try %{
  %sh{
    if [ "$1" = "$2" ]; then
      echo execute-keys -draft '2h<a-K>[[:alnum:]]<ret>'
    fi
  }
  execute-keys -draft ';<a-K>[[:alnum:]]<ret>'
  execute-keys -no-hooks "%arg{2}<a-;>H"
}}

define-command -hidden -params 2 auto-pairs-insert-closer %{ try %{
  execute-keys -draft ";<a-k>\Q%arg{2}<ret>d"
}}

define-command -hidden -params 2 auto-pairs-delete-opener %{ try %{
  execute-keys -draft ";<a-k>\Q%arg{2}<ret>d"
}}

define-command -hidden -params 2 auto-pairs-delete-closer %{ try %{
  execute-keys -draft "h<a-k>\Q%arg{1}<ret>d"
}}

define-command -hidden auto-pairs-insert-new-line %{ try %{
  %sh{
    regex=$(printf '\Q%s\E' "$kak_opt_auto_pairs" | sed s/:/'\\E|\\Q'/g';'s/'<,>'/'<lt>,<gt>'/g';'s/,/'\\E\\n\\h*\\Q'/g)
    printf '%s\n' "execute-keys -draft %(;KGl<a-k>$regex<ret>)"
  }
  execute-keys <up><end><ret>
}}

define-command -hidden auto-pairs-delete-new-line %{ try %{
  %sh{
    regex=$(printf '\Q%s\E' "$kak_opt_auto_pairs" | sed s/:/'\\E|\\Q'/g';'s/'<,>'/'<lt>,<gt>'/g';'s/,/'\\E\\n\\h*\\Q'/g)
    printf '%s\n' "execute-keys -draft %(;JGi<a-k>$regex<ret>)"
  }
  execute-keys -no-hooks <del>
  execute-keys -draft '<a-i><space>d'
}}

define-command -hidden auto-pairs-insert-space %{ try %{
  %sh{
    regex=$(printf '\Q%s\E' "$kak_opt_auto_pairs" | sed s/:/'\\E|\\Q'/g';'s/'<,>'/'<lt>,<gt>'/g';'s/,/'\\E\\h\\Q'/g)
    printf '%s\n' "execute-keys -draft %(;2H<a-k>$regex<ret>)"
  }
  execute-keys -no-hooks <space><left>
}}

define-command -hidden auto-pairs-delete-space %{ try %{
  %sh{
    regex=$(printf '\Q%s\E' "$kak_opt_auto_pairs" | sed s/:/'\\E|\\Q'/g';'s/'<,>'/'<lt>,<gt>'/g';'s/,/'\\E\\h\\Q'/g)
    printf '%s\n' "execute-keys -draft %(;l2H<a-k>$regex<ret>)"
  }
  execute-keys -no-hooks <del>
}}

define-command auto-pairs-enable -docstring 'auto-pairs-enable: Enable automatic closing of pairs' %{
  %sh{
    IFS='
'
    for pair in $(printf %s "$kak_opt_auto_pairs" | tr : '\n'); do
      opener=$(printf %s "$pair" | cut -d , -f 1)
      closer=$(printf %s "$pair" | cut -d , -f 2)
      printf '%s\n' "hook window InsertChar %-\Q$opener- -group auto-pairs-insert %(auto-pairs-insert-opener %-$opener- %-$closer-)"
      printf '%s\n' "hook window InsertDelete %-\Q$opener- -group auto-pairs-delete %(auto-pairs-delete-opener %-$opener- %-$closer-)"
      if [ "$opener" != "$closer" ]; then
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

define-command auto-pairs-disable -docstring 'auto-pairs-disable: Disable automatic closing of pairs' %{
  remove-hooks window auto-pairs-insert
  remove-hooks window auto-pairs-delete
  set-option window auto_pairs_enabled no
}

define-command auto-pairs-toggle -docstring 'auto-pairs-toggle: Toggle automatic closing of pairs' %{ %sh{
  if [ "$kak_opt_auto_pairs_enabled" = true ]; then
    echo auto-pairs-disable
  else
    echo auto-pairs-enable
  fi
}}

define-command -hidden -params 2 auto-pairs-surround-insert-opener %{
  execute-keys -draft "<a-;>a%arg{2}"
}

define-command -hidden -params 2 auto-pairs-surround-delete-opener %{
  execute-keys -draft "<a-;>l<a-k>\Q%arg{2}<ret>d"
}

define-command auto-pairs-surround -docstring 'auto-pairs-surround: Enable automatic closing of pairs on selection boundaries for the whole insert session' %{
  %sh{
    IFS='
'
    if [ "$kak_opt_auto_pairs_enabled" = true ]; then
      echo set-option window auto_pairs_was_enabled yes
    else
      echo set-option window auto_pairs_was_enabled no
    fi
    for pair in $(printf %s "$kak_opt_auto_pairs" | tr : '\n'); do
      opener=$(printf %s "$pair" | cut -d , -f 1)
      closer=$(printf %s "$pair" | cut -d , -f 2)
      printf '%s\n' "hook window InsertChar %-\Q$opener- -group auto-pairs-surround-insert %(auto-pairs-surround-insert-opener %-$opener- %-$closer-)"
      printf '%s\n' "hook window InsertDelete %-\Q$opener- -group auto-pairs-surround-delete %(auto-pairs-surround-delete-opener %-$opener- %-$closer-)"
    done
  }
  hook window ModeChange insert:normal -group auto-pairs-surround-insert-end %{
    %sh{
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
  execute-keys i
}
