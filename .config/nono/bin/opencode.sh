#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/agent.sh
source "$HOME/.config/nono/bin/agent.sh"

# Require an explicit server. OpenCode v2 otherwise hands work to its shared
# background service, which would run outside the sandbox (and is denied).
has_explicit_server=false
is_exempt=false
port=""
prev=""
for arg in "$@"; do
    case "$arg" in
    --standalone | --server | --server=*) has_explicit_server=true ;;
    serve | auth | models | debug | plugin | mcp | stats | upgrade | update | uninstall | --help | -h | --version | -v) is_exempt=true ;;
    --port=*) port="${arg#--port=}" ;;
    esac
    if [ "$prev" = --port ]; then port="$arg"; fi
    prev="$arg"
done

if [ "$has_explicit_server" = false ] && [ "$is_exempt" = false ]; then
    cat >&2 <<'EOF'
nono/opencode.sh: no explicit server requested.

OpenCode v2 would fall back to its user-wide shared background service, which runs
outside the sandbox (and is denied in here). Pass one of:

  --standalone      private, sandboxed server (TUI, `run`)
  serve             foreground server (e.g. for the editor integration)
  --server <url>    connect to an explicit server
EOF
    exit 1
fi

# `serve --port N`: in proxy mode, listening needs an explicit grant on Linux (macOS allows
# any port via the profile).
if [ -n "$port" ] && [ "$port" != 0 ]; then
    nono_args+=(--listen-port "$port")
fi

nono_exec opencode opencode "$@"
