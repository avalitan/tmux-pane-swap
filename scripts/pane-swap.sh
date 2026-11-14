#!/bin/sh
set -eu

mode=${1:-}
socket=${2:-}
source=${3:-}
client=${4:-}
self=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)/pane-swap.sh

tm() { tmux -S "$socket" "$@"; }
quote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"; }
message() { tm display-message -c "$client" "pane-swap: $*"; }

case "$mode" in
    open)
        if ! command -v fzf >/dev/null 2>&1; then
            message 'install fzf to use the pane picker'
            exit 1
        fi
        command="$(quote "$self") pick $(quote "$socket") $(quote "$source") $(quote "$client")"
        tm display-popup -c "$client" -E -w 85% -h 80% "$command"
        ;;
    pick)
        # IDs remain stable even if a pane is moved while the picker is open.
        rows=$(tm list-panes -a -F '#{pane_id} #{session_name}:#{window_index}.#{pane_index}  #{window_name}  [#{pane_current_command}]  #{pane_current_path}' |
            awk -v source="$source" '$1 != source')
        [ -n "$rows" ] || exit 0
        preview="$(quote "$self") preview $(quote "$socket") {1}"
        # Ignore user fzf defaults: multi-select, bindings, or output options can
        # otherwise change the meaning of the selected row.
        if selection=$(printf '%s\n' "$rows" | FZF_DEFAULT_OPTS='' FZF_DEFAULT_OPTS_FILE='' fzf \
            --no-multi --layout=reverse --border --prompt='Swap with > ' \
            --header='Enter: swap panes | Esc: cancel' --with-nth=2.. \
            --preview="$preview" --preview-window=down:55%:wrap); then
            target=${selection%% *}
            case "$target" in
                %*[!0-9]*|'%'|'') exit 1 ;;
                %*) ;;
                *) exit 1 ;;
            esac
            [ "$target" != "$source" ] || exit 0
            if ! tm swap-pane -s "$source" -t "$target"; then
                message 'could not swap; a pane may have closed'
                exit 1
            fi
        else
            status=$?
            case "$status" in
                1|130) exit 0 ;;
                *) message "picker failed (exit $status)"; exit "$status" ;;
            esac
        fi
        ;;
    preview)
        tm capture-pane -p -t "$source" -S -100 2>/dev/null || :
        ;;
    *)
        printf 'Usage: %s {open|pick|preview} SOCKET PANE [CLIENT]\n' "$0" >&2
        exit 2
        ;;
esac
