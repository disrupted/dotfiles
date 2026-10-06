#!/usr/bin/env bash
#
# overwrite-node-with-bun-runtime
#
# mise tool postinstall hook. Makes an npm:* CLI run on the Bun runtime instead
# of Node.js by retargeting whatever launches `node`. Two install layouts are
# handled:
#
#   * bin/ layout (bun/npm/pnpm global install):
#       <root>/bin/<name> is a symlink to the package's JS entry, which starts
#       with a `node` shebang. Rewrite that shebang to `bun`.
#
#   * aube layout:
#       <root>/node_modules/.bin/<name> is a POSIX sh wrapper ("aube-bin-shim")
#       that `exec`s node. Rewrite those exec calls to `bun`.
#
# Invoked once per tool during `mise install` with MISE_TOOL_INSTALL_PATH set to
# the tool's install directory, e.g.
#   ~/.local/share/mise/installs/npm-astrojs-language-server/2.17.1
set -u

root="${MISE_TOOL_INSTALL_PATH:-}"
[ -n "$root" ] || exit 0

shopt -s nullglob

# --- Layout 1: <root>/bin/* symlinks to a JS entry with a node shebang --------
for link in "$root"/bin/*; do
    # Resolve the bin symlink to its real JS entry. macOS has no `readlink -f`, so
    # use Perl's abs_path, which also resolves relative and chained symlinks.
    target="$(perl -MCwd=abs_path -e 'print abs_path($ARGV[0]) // ""' "$link" 2>/dev/null)"
    [ -n "$target" ] && [ -f "$target" ] || continue
    # Handles "#!/usr/bin/env node", "#! /usr/bin/env node" and "#!/usr/bin/node".
    # Idempotent: once the first line says `bun`, it no longer matches.
    perl -i -pe 's{^#!\s*(?:/usr/bin/env\s+)?node\b}{#!/usr/bin/env bun} if $. == 1' "$target"
done

# --- Layout 2: aube <root>/node_modules/.bin/* POSIX wrappers -----------------
for shim in "$root"/node_modules/.bin/*; do
    [ -f "$shim" ] || continue
    # Only touch POSIX sh wrappers; skip symlinks to JS entries (those are handled
    # by the shebang path above if present).
    [ "$(head -n1 "$shim")" = "#!/bin/sh" ] || continue
    # aube-bin-shim emits: `exec "$basedir/node" <entry> "$@"` and
    # `exec node <entry> "$@"`. Idempotent once rewritten to `exec bun`.
    perl -i -pe 's{\bexec "\$basedir/node" }{exec bun }; s{\bexec node }{exec bun }' "$shim"
done
