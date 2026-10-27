#!/bin/sh
# Per-window persistent scratch terminal for the tmux popup.
#
#   scratch-popup.sh               attach to the scratch session of the current window
#   scratch-popup.sh <window-id>   same, for an explicit @N window id
#   scratch-popup.sh --prune       kill sessions whose window is gone

set -eu

prune() {
	windows=" $(tmux list-windows -a -F '#{window_id}' | tr '\n' ' ') "
	tmux list-sessions -F '#{session_name}' |
		grep '^scratch-@' |
		while IFS= read -r session; do
			id="${session#scratch-}"
			case "$windows" in
			*" $id "*) ;;
			# "=" avoids prefix matches (scratch-@4 vs scratch-@41)
			*) tmux kill-session -t "=$session" 2>/dev/null || true ;;
			esac
		done || true
}

case "${1:-}" in
--prune)
	prune
	exit 0
	;;
-*)
	echo "usage: $0 [window-id] | --prune" >&2
	exit 2
	;;
esac

if [ "$#" -ge 1 ]; then
	key="$1"
else
	# display-popup doesn't expand formats, but TMUX_PANE points at the popup
	# pane, which belongs to the originating window
	key="$(tmux display-message -p '#{window_id}' 2>/dev/null || true)"
fi

case "$key" in
@[0-9]*) ;;
*)
	echo "usage: $0 [window-id] | --prune" >&2
	exit 2
	;;
esac

session="scratch-$key"

if ! tmux has-session -t "=$session" 2>/dev/null; then
	tmux new-session -d -s "$session" -c "${PWD:-$HOME}" -n shell
fi

# set-option parses a bare name as a pane, so the trailing ":" forces a session
tmux set-option -t "=$session:" status off

# The global detach-on-destroy is off, which would leave the popup attached to
# another session after "exit"
tmux set-option -t "=$session:" detach-on-destroy on

# tmux refuses to attach from inside a tmux client without this
unset TMUX TMUX_PANE

exec tmux attach-session -t "=$session"
