#!/usr/bin/env bash
#
# install-tinycast
#
# mise postinstall hook for `http:tinycast`. The GitHub release zip is extracted
# (strip_components = 0) so $MISE_TOOL_INSTALL_PATH/Tinycast.app is the bundle.
# This copies that bundle into the app directory and strips the quarantine flag,
# replicating what the Homebrew cask did — without Homebrew or Ruby.
#
# Upgrade with:  mise upgrade http:tinycast
# (the `when = "always"` hook re-runs on every install/upgrade)
#
# Set TINYCAST_APPDIR to override the destination (used for testing).
set -euo pipefail

src="${MISE_TOOL_INSTALL_PATH:-}/Tinycast.app"
if [ ! -d "$src" ]; then
	echo "tinycast: app bundle not found at $src" >&2
	exit 1
fi

dest_dir="${TINYCAST_APPDIR:-/Applications}"
dest="$dest_dir/Tinycast.app"

# Quit a running instance before replacing the bundle, otherwise the live
# process keeps helper handles into the old bundle.
if pgrep -x Tinycast >/dev/null 2>&1; then
	osascript -e 'quit app "Tinycast"' >/dev/null 2>&1 || pkill -x Tinycast >/dev/null 2>&1 || true
	sleep 1
fi

mkdir -p "$dest_dir"
rm -rf "$dest"
ditto "$src" "$dest"
xattr -dr com.apple.quarantine "$dest" >/dev/null 2>&1 || true
echo "tinycast: installed $dest"
