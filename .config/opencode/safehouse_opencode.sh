#!/usr/bin/env bash
set -euo pipefail

# Resolve $HOME physically so the prefix matching below works even when $HOME is
# reached through a symlink (e.g. /var -> /private/var on macOS).
home_dir="$(cd "$HOME" 2>/dev/null && pwd -P)" || home_dir="$HOME"

# ---------------------------------------------------------------------------
# PWD-scoped convenience grants
# ---------------------------------------------------------------------------
launch_dir="$(pwd -P)"
extra_grants=()

case "$launch_dir" in
    "$home_dir/.config" | "$home_dir/.config/"*)
        extra_grants+=(--add-dirs="$home_dir/.config")
        ;;
esac

# Work: grant the whole work tree, plus shared bakdata (read-only reference).
# Launching inside bakdata grants it read-write
for _client in spectrumk bayer bakdata; do
    case "$launch_dir" in
        "$home_dir/$_client" | "$home_dir/$_client/"*)
            extra_grants+=(--add-dirs="$home_dir/$_client")
            extra_grants+=(--add-dirs-ro="$home_dir/bakdata")
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
    --enable=1password,ssh,kubectl,docker,keychain
    # local overlays
    --append-profile="$home_dir/.config/opencode/opencode.sb"
    --append-profile="$home_dir/.config/opencode/local-hardening.sb"
)
if [ "${#extra_grants[@]}" -gt 0 ]; then
    safehouse_args+=("${extra_grants[@]}")
fi
safehouse_args+=(
    --env-pass=OPENCODE_PASSWORD,OPENCODE_SERVER_PASSWORD,OPENCODE_SERVER_USERNAME,GITHUB_TOKEN,OPENROUTER_API_KEY,OPENAI_API_KEY,ANTHROPIC_API_KEY,GEMINI_API_KEY
    -- opencode "$@"
)
exec "${safehouse_args[@]}"
