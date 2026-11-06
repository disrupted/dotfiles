#!/usr/bin/env bash
# Run by worktree_prune in init.lua once it has fetched and found candidates.
PATH="$HOME/.local/share/mise/shims:$PATH"
export PATH

hold() { printf '\n%s press any key to close' "$*"; read -r -n1; echo; }

wt step prune --dry-run --min-age 0
echo
read -r -n1 -p "Remove these? [y/N] " answer; echo
[[ $answer == [yY] ]] || exit 0
wt step prune --min-age 0 --foreground -y || hold "wt step prune failed (see above)."
