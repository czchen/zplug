__zplug::io::cache::create()
{
    local name

    for name in "${(ok)zplugs[@]}"
    do
        # In order to sort $zplugs[$name],
        # do not quate this string
        echo "${name}${zplugs[$name]:+, ${(os:, :)zplugs[$name]}}"
    done
}

__zplug::io::cache::load()
{
    local key

    $ZPLUG_USE_CACHE || return 2

    if [[ -f $ZPLUG_CACHE_FILE ]]; then
        2> >(__zplug::io::log::capture) >/dev/null \
            diff -b \
            <( \
            awk \
            -f "$_ZPLUG_AWKPATH/read_cache.awk" \
            "$ZPLUG_CACHE_FILE" \
            ) \
            <( \
            __zplug::io::cache::create \
            )

        case $status in
            0)
                # same
                source "$ZPLUG_CACHE_FILE"
                return $status
                ;;
            1)
                # differ
                ;;
            2)
                # error
                ;;
        esac
    fi

    # if cache file doesn't find,
    # returns non-zero exit code
    return 1
}

__zplug::io::cache::update()
{
    $ZPLUG_USE_CACHE || return 2

    local load_command

    if [[ ! -d ${ZPLUG_CACHE_FILE:h} ]]; then
        mkdir -p "${ZPLUG_CACHE_FILE:h}"
    fi

    if [[ -f $ZPLUG_CACHE_FILE ]]; then
        chmod a+w "$ZPLUG_CACHE_FILE"
    fi

    {
        __zplug::io::print::put '#!/usr/bin/env zsh\n\n'
        __zplug::io::print::put '# This file was generated by zplug\n'
        __zplug::io::print::put '# *** DO NOT EDIT THIS FILE ***\n\n'
        __zplug::io::print::put '[[ $- =~ i ]] || exit\n'
        __zplug::io::print::put 'export PATH="%s:$PATH"\n' "$ZPLUG_HOME/bin"
        __zplug::io::print::put 'export ZSH=${ZSH:-%s}\n' "$ZPLUG_REPOS/$_ZPLUG_OHMYZSH"
        __zplug::io::print::put 'export ZSH_CACHE_DIR=${ZSH_CACHE_DIR:-$ZSH/cache}/\n\n'

        __zplug::io::print::put 'if $is_verbose; then\n'
        __zplug::io::print::put '  echo "Static loading..." >&2\n'
        __zplug::io::print::put 'fi\n'
        if [[ -o prompt_subst ]]; then
            __zplug::io::print::put '\nsetopt prompt_subst\n'
        fi
        __zplug::io::print::put '\n'
        if (( $#load_commands > 0 )); then
            __zplug::io::print::put '# Commands\n'
            __zplug::io::print::put '\\chmod a=rx "%s"\n' \
                "${(uk)load_commands[@]}"
            for load_command in "${(uk)load_commands[@]}"
            do
                __zplug::io::print::put '\\ln -snf "%s" "%s"\n' \
                    "$load_command" \
                    "$load_commands[$load_command]"
            done
            __zplug::io::print::put '\n'
        fi
        if (( $#load_plugins > 0 )); then
            __zplug::io::print::put '# Plugins\n'
            __zplug::io::print::put 'source %s\n' "${(uqqq)load_plugins[@]}"
            __zplug::io::print::put '\n'
        fi
        if (( $#load_fpaths > 0 )); then
            __zplug::io::print::put '# Fpath\n'
            __zplug::io::print::put 'fpath=(\n'
            __zplug::io::print::put '%s\n' "${(u)load_fpaths[@]}"
            __zplug::io::print::put '$fpath\n'
            __zplug::io::print::put ')\n'
        fi
        __zplug::io::print::put '\n# path\n'
        __zplug::io::print::put 'typeset -U path\n\n'
        __zplug::io::print::put '\ncompinit -C -d %s\n\n' "$ZPLUG_HOME/zcompdump"
        if (( $#nice_plugins > 0 )); then
            __zplug::io::print::put '# Loading after compinit\n'
            __zplug::io::print::put 'source %s\n' "${(qqq)nice_plugins[@]}"
            __zplug::io::print::put '\n'
        fi
        if (( $#lazy_plugins > 0 )); then
            __zplug::io::print::put '\n# Lazy loading plugins\n'
            __zplug::io::print::put 'autoload -Uz %s\n' "${(qqq)lazy_plugins[@]:t}"
            __zplug::io::print::put '\n'
        fi
        if (( $#hook_load_cmds > 0 )); then
            __zplug::io::print::put '\n# Hooks after load\n'
            __zplug::io::print::put '%s\n' "${hook_load_cmds[@]}"
            __zplug::io::print::put '\n'
        fi
        __zplug::io::print::put '\nreturn 0\n'
        __zplug::io::print::put '%s\n' "$(__zplug::io::cache::create)"
    } >|"$ZPLUG_CACHE_FILE"

    if [[ -f $ZPLUG_CACHE_FILE ]]; then
        chmod a-w "$ZPLUG_CACHE_FILE"
    fi
}
