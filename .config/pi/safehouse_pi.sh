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
"$home_dir/.config" | "$home_dir/.config/"* | "$home_dir/dev" | "$home_dir/dev/"* | "$home_dir/.local" | "$home_dir/.local/"*)
    extra_grants+=(--add-dirs="$home_dir/.config")
    extra_grants+=(--add-dirs="$home_dir/dev")
    extra_grants+=(--add-dirs-ro="$home_dir/.local")
    extra_grants+=(--add-dirs="$home_dir/.local/share/nvim")
    extra_grants+=(--add-dirs="$home_dir/.local/share/yadm/repo.git")
    ;;
esac

# Work: grant the whole work tree, plus shared bakdata (read-only reference).
# Launching inside bakdata grants it read-write
for _client in spectrumk bayer bakdata; do
    case "$launch_dir" in
    "$home_dir/$_client" | "$home_dir/$_client/"*)
        extra_grants+=(--add-dirs="$home_dir/$_client")
        extra_grants+=(--add-dirs-ro="$home_dir/bakdata")
        extra_grants+=(--add-dirs-ro="$home_dir/Downloads")
        break
        ;;
    esac
done
unset _client

safehouse_args=(
    safehouse
    --enable="1password,ssh,kubectl,docker,keychain,playwright-chrome"
    # local overlays
    --add-dirs="$PI_CODING_AGENT_DIR"
    --append-profile="$home_dir/.config/safehouse/local-ssh.sb"
    --append-profile="$home_dir/.config/safehouse/local-dev.sb"
)
if [ "${#extra_grants[@]}" -gt 0 ]; then
    safehouse_args+=("${extra_grants[@]}")
fi
safehouse_args+=(
    --env-pass="PI_CODING_AGENT_DIR,PI_SERVER_PASSWORD,PI_SERVER_USERNAME,CONTEXT7_API_KEY,GITHUB_TOKEN,OPENCODE_API_KEY,OPENAI_API_KEY,ANTHROPIC_API_KEY,GEMINI_API_KEY,VIRTUAL_ENV,REUSE_CONTAINERS"
    -- pi "$@"
)
exec "${safehouse_args[@]}"
