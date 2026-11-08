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
# Extra raw secrets for one run: NONO_RAW_SECRET_NAMES="FOO,BAR"

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

if [ -n "${NONO_ARGS:-}" ]; then
    read -r -a extra_nono_args <<<"$NONO_ARGS"
    nono_args+=("${extra_nono_args[@]}")
fi

# dotfiles mode. ~/.local itself can't be granted: it contains nono's state dir.
if launched_in .config dev .local; then
    nono_args+=(
        --allow "$home_dir/.config"
        --allow "$home_dir/dev"
        --allow "$home_dir/.local/share/nvim"
        --allow "$home_dir/.local/share/yadm/repo.git"
    )
fi

if [ -n "${WORK:-}" ]; then
    case "$launch_dir" in
    "$home_dir"/*)
        client="${launch_dir#"$home_dir"/}"
        nono_args+=(
            --allow "$home_dir/${client%%/*}"
            --read "$home_dir/Downloads"
        )
        ;;
    esac
fi

mise_env_json="$(mise env --json 2>/dev/null)" || mise_env_json='{}'
# Secrets fnox can resolve here, regardless of their `env` setting. Type "env var" means the
# value comes from the environment (e.g. a masked `env = false` entry): keep those only if set.
fnox_secret_names=" $(fnox list 2>/dev/null | awk 'NR > 1 && !($2 == "env" && $3 == "var") { print $1 }' | tr '\n' ' ') "
while read -r name; do
    if [ -n "$name" ] && [ -n "${!name:-}" ]; then fnox_secret_names+="$name "; fi
done < <(fnox list 2>/dev/null | awk 'NR > 1 && $2 == "env" && $3 == "var" { print $1 }')

# Value of a mise env var, before `mise x` has set it.
mise_env_get() {
    jq -r --arg k "$1" '.[$k] // empty' <<<"$mise_env_json"
}

secret_available() {
    [[ "$fnox_secret_names" == *" $1 "* ]]
}

# Phantom-token route name -> fnox secret.
credential_routes=(
    anthropic:ANTHROPIC_API_KEY
    openai:OPENAI_API_KEY
    gemini:GEMINI_API_KEY
    openrouter:OPENROUTER_API_KEY
    context7:CONTEXT7_API_KEY
    github:GITHUB_TOKEN
    github_git:GITHUB_TOKEN
)

# Secrets the agent gets as *real* values because they can't be proxied. Everything else goes
# through a route above or is stripped by `environment.deny_vars`.
# OPENCODE_API_KEY: opencode.ai/inference mixes Bearer, x-api-key and x-goog-api-key auth on
# one host, but a nono route injects a single header style.
raw_secrets=(OPENCODE_API_KEY)

# Runs inside `fnox exec --only ...`. Only maps secrets fnox actually set (it skips
# `env = false` ones), because nono aborts on an unset env:// source.
# Args: <space-separated names> <nono run args...>
# shellcheck disable=SC2016
raw_secrets_trampoline='
names=$1; shift
maps=()
for name in $names; do
    if [ -n "${!name:-}" ]; then maps+=(--env-credential-map "env://$name" "$name"); fi
done
exec nono run ${maps[@]+"${maps[@]}"} "$@"
'

nono_exec() {
    local profile="$1" route name
    shift
    local requested=() raw=() fnox_x=()

    for route in "${credential_routes[@]}"; do
        if secret_available "${route#*:}"; then
            nono_args+=(--credential "${route%%:*}")
        fi
    done

    # `fnox exec` resolves raw secrets the shell doesn't export (`env = "exec"`).
    # --env-credential-map passes them through `environment.deny_vars`.
    IFS=, read -r -a requested <<<"${NONO_RAW_SECRET_NAMES:-}"
    # ${a[@]+...}: empty arrays are "unbound" under set -u in macOS' bash 3.2
    for name in ${raw_secrets[@]+"${raw_secrets[@]}"} ${requested[@]+"${requested[@]}"}; do
        if secret_available "$name"; then
            raw+=("$name")
            fnox_x+=(--only "$name")
        fi
    done

    if [ "${#raw[@]}" -gt 0 ]; then
        exec mise x -- fnox exec "${fnox_x[@]}" -- \
            bash -c "$raw_secrets_trampoline" nono-raw-secrets "${raw[*]}" \
            --profile "$profile" "${nono_args[@]}" -- "$@"
    fi
    exec mise x -- nono run --profile "$profile" "${nono_args[@]}" -- "$@"
}
