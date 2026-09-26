#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# PWD-scoped convenience grants
# ---------------------------------------------------------------------------
launch_dir="$(pwd -P)"
extra_grants=()

case "$launch_dir" in
    "$HOME/.config" | "$HOME/.config/"*)
        extra_grants+=(--add-dirs="$HOME/.config")
        ;;
esac

# Work: grant the whole work tree, plus shared bakdata (read-only reference).
for _client in spectrumk bayer bakdata; do
    case "$launch_dir" in
        "$HOME/$_client" | "$HOME/$_client/"*)
            extra_grants+=(--add-dirs="$HOME/$_client")
            extra_grants+=(--add-dirs-ro="$HOME/bakdata")
            break
            ;;
    esac
done
unset _client

# ---------------------------------------------------------------------------
# Guard: refuse to silently fall back to the shared background service
# ---------------------------------------------------------------------------
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

safehouse_args=(
    safehouse
    --append-profile="$HOME/.config/opencode/opencode.sb"
    --append-profile="$HOME/.config/opencode/local-hardening.sb"
)
if [ "${#extra_grants[@]}" -gt 0 ]; then
    safehouse_args+=("${extra_grants[@]}")
fi
safehouse_args+=(
    --env-pass=OPENCODE_PASSWORD,OPENCODE_SERVER_PASSWORD,OPENCODE_SERVER_USERNAME,GITHUB_TOKEN,OPENROUTER_API_KEY,OPENAI_API_KEY,ANTHROPIC_API_KEY,GEMINI_API_KEY
    -- opencode "$@"
)
exec "${safehouse_args[@]}"
