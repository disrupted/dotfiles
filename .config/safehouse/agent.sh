#!/usr/bin/env bash
# shellcheck disable=SL2001
# Shared launcher for coding agents in agent-safehouse.
# Source it, add agent-specific flags to `safehouse_args`, then call
# `safehouse_exec <agent> "$@"`.
#
# Env vars come from mise (incl. fnox secrets via `[secrets.fnox]` in the
# project's mise.toml), so nothing project-specific is hardcoded here.

# Physical paths, so prefix matching works through symlinks.
home_dir="$(cd "$HOME" 2>/dev/null && pwd -P)" || home_dir="$HOME"
launch_dir="$(pwd -P)"

# True if launched in or below any of the given dirs (relative to $HOME).
launched_in() {
    local dir
    for dir in "$@"; do
        case "$launch_dir" in
        "$home_dir/$dir" | "$home_dir/$dir/"*) return 0 ;;
        esac
    done
    return 1
}

dotfiles_grants=(
    --add-dirs="$home_dir/.config"
    --add-dirs="$home_dir/dev"
    --add-dirs-ro="$home_dir/.local"
    --add-dirs="$home_dir/.local/share/nvim"
    --add-dirs="$home_dir/.local/share/yadm/repo.git"
)

safehouse_args=(
    --enable="1password,ssh,kubectl,docker,keychain,playwright-chrome"
    --append-profile="$home_dir/.config/safehouse/local-ssh.sb"
    --append-profile="$home_dir/.config/safehouse/local-dev.sb"
)

if launched_in .config dev .local; then
    safehouse_args+=("${dotfiles_grants[@]}")
fi

for client in spectrumk bayer bakdata; do
    if launched_in "$client"; then
        safehouse_args+=(
            --add-dirs="$home_dir/$client"
            --add-dirs-ro="$home_dir/bakdata"
            --add-dirs-ro="$home_dir/Downloads"
        )
        break
    fi
done

# Env from mise for this directory. PATH is skipped; safehouse builds its own.
mise_env_json="$(mise env --json 2>/dev/null)" || mise_env_json='{}'
mise_secrets_json="$(mise secrets ls --json 2>/dev/null)" || mise_secrets_json='{}'
mise_env_names="$(jq -r 'del(.PATH) | keys | join(",")' <<<"$mise_env_json")"
# Same selection as `mise x --secrets-all` (no file secrets).
mise_secret_names="$(jq -r '[.keys[]? | select(.as_file | not) | select(.scopes | index("exec")) | .key] | join(",")' <<<"$mise_secrets_json")"

# Value of a mise env var, before `mise x` has set it.
mise_env_get() {
    jq -r --arg k "$1" '.[$k] // empty' <<<"$mise_env_json"
}

safehouse_exec() {
    local names
    for names in "$mise_env_names" "$mise_secret_names"; do
        if [ -n "$names" ]; then safehouse_args+=(--env-pass="$names"); fi
    done

    # `mise x` sets the values on the host; safehouse only passes the names in.
    local mise_x=(mise x)
    if [ -n "$mise_secret_names" ]; then mise_x+=(--secrets-all); fi
    exec "${mise_x[@]}" -- safehouse "${safehouse_args[@]}" -- "$@"
}
