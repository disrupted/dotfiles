#!/usr/bin/env bash
# shellcheck disable=SL2001
# Shared launcher for coding agents in nono.
# Source it, add agent-specific flags to `nono_args`, then call
# `nono_exec <profile> <command> [args...]`.
#
# Profiles only expand a fixed set of variables, so everything that depends on the launch
# directory (directory grants, which fnox secrets exist) is added here as CLI flags.
#
# Extra nono flags for one run: NONO_ARGS="--rollback --network-profile developer"

# Physical paths, so prefix matching works through symlinks.
home_dir="$(cd "$HOME" 2>/dev/null && pwd -P)" || home_dir="$HOME"
launch_dir="$(pwd -P)"

launched_in() {
    local dir
    for dir in "$@"; do
        case "$launch_dir" in
        "$home_dir/$dir" | "$home_dir/$dir/"*) return 0 ;;
        esac
    done
    return 1
}

nono_args=(
    --allow-cwd
    --no-rollback-prompt
)

# Everything in $HOME is readable; the profile's deny groups still hide secrets. nono refuses
# grants that cover its own state, so $HOME is granted entry by entry around it.
nono_protected=("$home_dir/.nono" "$home_dir/.local/state/nono")

grant_reads_in() {
    local entry protected
    for entry in "$1"/* "$1"/.*; do
        case "${entry##*/}" in . | .. | '*' | '.*') continue ;; esac
        [ -e "$entry" ] || continue
        for protected in "${nono_protected[@]}"; do
            case "$protected" in
            "$entry") continue 2 ;;
            "$entry"/*)
                grant_reads_in "$entry"
                continue 2
                ;;
            esac
        done
        if [ -d "$entry" ]; then
            nono_args+=(--read "$entry")
        else
            nono_args+=(--read-file "$entry")
        fi
    done
}
grant_reads_in "$home_dir"

if [ -n "${NONO_ARGS:-}" ]; then
    read -r -a extra_nono_args <<<"$NONO_ARGS"
    nono_args+=("${extra_nono_args[@]}")
fi

# dotfiles mode. ~/.local itself can't be granted: it contains nono's state dir.
if launched_in .config .dotfiles dev .local; then
    nono_args+=(
        --allow "$home_dir/.config"
        --allow "$home_dir/.dotfiles"
        --allow "$home_dir/dev"
        --allow "$home_dir/.local/share/nvim"
    )
fi

if [ -n "${WORK:-}" ]; then
    case "$launch_dir" in
    "$home_dir"/*)
        client="${launch_dir#"$home_dir"/}"
        nono_args+=(--allow "$home_dir/${client%%/*}")
        ;;
    esac
fi

# Secrets fnox can resolve here, regardless of their `env` setting. Type "env var" means the
# value comes from the environment (e.g. a masked `env = false` entry): keep those only if set.
fnox_secret_names=" $(fnox list 2>/dev/null | awk 'NR > 1 && !($2 == "env" && $3 == "var") { print $1 }' | tr '\n' ' ') "
while read -r name; do
    if [ -n "$name" ] && [ -n "${!name:-}" ]; then fnox_secret_names+="$name "; fi
done < <(fnox list 2>/dev/null | awk 'NR > 1 && $2 == "env" && $3 == "var" { print $1 }')

# Value of a mise env var, before `mise x` has set it.
mise_env_get() {
    mise x -- printenv "$1" 2>/dev/null || true
}

secret_available() {
    [[ "$fnox_secret_names" == *" $1 "* ]]
}

# Phantom-token route name -> fnox secret.
credential_routes=(
    anthropic:ANTHROPIC_API_KEY
    openai:OPENAI_API_KEY
    gemini:GEMINI_API_KEY
    context7:CONTEXT7_API_KEY
    opencode:OPENCODE_API_KEY
)

nono_exec() {
    local profile="$1" agent="$2" route
    shift

    # Their capture reads ~/fnox.toml explicitly, so they work from any launch dir. nono also
    # needs at least one route, or it refuses to start with the proxy CA settings.
    nono_args+=(--credential github --credential github_git)
    for route in "${credential_routes[@]}"; do
        if secret_available "${route#*:}"; then
            nono_args+=(--credential "${route%%:*}")
        fi
    done

    if [ -n "${NONO_SMOKE_TEST:-}" ]; then
        set -- /bin/bash "$NONO_SMOKE_TEST" "$agent"
    fi

    AI_AGENT="$agent" exec mise x -- nono run --profile "$profile" "${nono_args[@]}" -- "$@"
}
