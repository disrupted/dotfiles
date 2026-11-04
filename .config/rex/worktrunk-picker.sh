#!/bin/sh
# Rex can't read a login environment from Nushell, so commands started from Lua
# get a bare PATH without mise's tools (fzf, jq, wt).
PATH="$HOME/.local/share/mise/shims:$PATH"
export PATH
exec "$HOME/.config/rex/rex-worktrunk/worktrunk.sh" "$@"
