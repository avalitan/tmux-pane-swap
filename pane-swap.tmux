#!/bin/sh
# TPM executes executable *.tmux files at the plugin root.
set -eu
plugin_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
key=$(tmux show-option -gqv @pane-swap-key)
key=${key:-M-s}
# Quote the installation path for the shell used by run-shell.
quoted_script=$(printf '%s' "$plugin_dir/scripts/pane-swap.sh" | sed "s/'/'\\\\''/g")
tmux bind-key "$key" run-shell "'$quoted_script' open #{q:socket_path} #{pane_id} #{q:client_name}"
