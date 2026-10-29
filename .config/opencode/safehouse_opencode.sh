#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/../safehouse/agent.sh
source "$HOME/.config/safehouse/agent.sh"

# Require standalone server mode. OpenCode v2 otherwise falls back to its shared background service, which safehouse blocks.
has_explicit_server=false
is_exempt=false
for arg in "$@"; do
    case "$arg" in
    --standalone | --server | --server=*) has_explicit_server=true ;;
    serve | auth | models | debug | plugin | mcp | stats | upgrade | update | uninstall | --help | -h | --version | -v) is_exempt=true ;;
    esac
done

if [ "$has_explicit_server" = false ] && [ "$is_exempt" = false ]; then
    cat >&2 <<'EOF'
safehouse_opencode: no explicit server requested.

OpenCode v2 would fall back to its user-wide shared background service, which is
blocked under safehouse. Pass one of:

  --standalone      private, sandboxed server (TUI)
  serve             foreground server (e.g. for the editor integration)
  --server <url>    connect to an explicit server

Examples:
  safehouse_opencode.sh --standalone
  safehouse_opencode.sh serve
EOF
    exit 1
fi

safehouse_args+=(
    --append-profile="$home_dir/.config/opencode/opencode.sb"
    --append-profile="$home_dir/.config/opencode/local-opencode.sb"
    --env-pass="OPENCODE_CONFIG,OPENCODE_PASSWORD,OPENCODE_SERVER_PASSWORD,OPENCODE_SERVER_USERNAME"
)

safehouse_exec opencode "$@"
