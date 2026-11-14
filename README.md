# tmux pane swap

Press **prefix + Alt-s**, pick a pane with fzf, and press **Enter** to swap it
with the pane you started from. Search by session, window, command, or directory.
The popup previews the highlighted pane. **Esc** / **Ctrl-c** cancels.

Panes from every session on the same tmux server are listed, including other
panes in your current window. The source pane is excluded. A swap moves the
running programs, without restarting them. tmux's normal `swap-pane` focus
behavior applies; your client stays in its current window.

Requires tmux **3.2+**, **fzf**, and a POSIX shell. Install fzf on the machine
running tmux (including remote machines).

## TPM installation

Push this repository to your own Git host, then add its repository to your tmux
config **before** the existing TPM initialization line:

```tmux
set -g @plugin 'avalitan/tmux-pane-swap'
```

Replace the placeholder with the published repository. Press **prefix + I** to
install. All implementation stays in the plugin, separate from your config.
TPM's executable `*.tmux` entrypoint convention is documented
[here](https://github.com/tmux-plugins/tpm/blob/master/docs/how_to_create_plugin.md).

Without TPM, add `run-shell '/absolute/path/to/pane-swap.tmux'` to your config.

## Change the shortcut

Set this before the plugin is loaded:

```tmux
set -g @pane-swap-key 'S'
```

This changes the shortcut to **prefix + Shift-s**. An existing binding on the
chosen key will be replaced. Reloading with a different key doesn't remove the
old binding; use `unbind-key M-s` to remove the default if already loaded.

The picker uses tmux's [popup and swap-pane commands](https://man.openbsd.org/tmux).
No tmux configuration files are modified by the plugin.
