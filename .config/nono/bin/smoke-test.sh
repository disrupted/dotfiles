#!/usr/bin/env bash
# Runs everyday agent workflows through the real launchers, to catch sandbox regressions
# after updating nono, mise or an agent.
#
# Usage: smoke-test.sh [--network] [agent...]   (default: every launcher in this dir)
# --network adds checks that go through the credential proxy.
set -euo pipefail

bin_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
network=""
if [ "${1:-}" = "--network" ]; then
    network=1
    shift
fi
if [ $# -eq 0 ]; then
    for launcher in "$bin_dir"/*.sh; do
        case "$(basename "$launcher")" in
        agent.sh | smoke-test.sh) ;;
        *) set -- "$@" "$(basename "$launcher" .sh)" ;;
        esac
    done
fi

tmp="$(mktemp -d "${TMPDIR:-/tmp}/nono-smoke.XXXXXX")"
tmp="$(cd "$tmp" && pwd -P)"
repo="$tmp/repo"
mise_state="${XDG_STATE_HOME:-$HOME/.local/state}/mise"

cleanup() {
    local link agent
    # the host-side `mise x` in the launcher records trust for the launch dir
    for link in "$mise_state"/trusted-configs/* "$mise_state"/tracked-configs/*; do
        case "$(readlink "$link" 2>/dev/null)" in
        "$tmp"/*) rm -f "$link" ;;
        esac
    done
    # mise names each project's history dir after its root
    for agent in "$@"; do
        rm -rf "$mise_state/task-history/$(printf '%s' "$repo/.wt/$agent" | shasum -a 256 | cut -c1-16)"
    done
    rm -rf "$tmp"
}
# shellcheck disable=SC2064 # expand the agent list now
trap "cleanup $(printf '%q ' "$@")" EXIT

git init -q "$repo"
cat >"$repo/mise.toml" <<'EOF'
[env]
SMOKE_ROOT = "{{config_root}}"

[tasks.smoke]
run = "test -n \"$SMOKE_ROOT\""
EOF
git -C "$repo" add mise.toml
git -C "$repo" -c commit.gpgsign=false commit -q -m init
echo .wt >>"$repo/.git/info/exclude"

for agent in "$@"; do
    git -C "$repo" worktree add -q "$repo/.wt/$agent"
done

# After the worktrees exist, so git doesn't run it on the host
cat >"$repo/.git/hooks/pre-commit" <<'EOF'
#!/bin/sh
exec mise x -- true
EOF
chmod +x "$repo/.git/hooks/pre-commit"

cat >"$tmp/checks.sh" <<'EOF'
agent="$1"
fails=0

check() {
    local name="$1" out
    shift
    if out="$("$@" 2>&1)"; then
        printf '  ok    %s\n' "$name"
    else
        printf '  FAIL  %s\n' "$name"
        printf '%s\n' "$out" | tail -n 5 | sed 's/^/          /'
        fails=$((fails + 1))
    fi
}

# For tools that report a denial on stderr but still exit 0
quiet() {
    local err
    err="$("$@" 2>&1 >/dev/null)" && [ -z "$err" ] && return
    printf '%s\n' "$err"
    return 1
}

recorded_in_history() {
    [ "$(mise tasks history "$1" --json)" != "[]" ]
}

# Untrusted unless the launcher's temp-dir trust works: hooks and templates need trust
throwaway_project() {
    local dir
    dir="$(mktemp -d /tmp/nono-smoke-project.XXXXXX)"
    printf '[env]\nROOT = "{{config_root}}"\n\n[hooks]\nenter = "true"\n' >"$dir/mise.toml"
    (cd "$dir" && mise x -- true)
    local status=$?
    rm -rf "$dir"
    return "$status"
}

check "$agent --version" "$agent" --version
check "mise x in a throwaway project in /tmp" throwaway_project
cd "$SMOKE_WORKTREE"
check "mise x in a fresh worktree" mise x -- true
check "mise run" mise run smoke
check "mise records task history" recorded_in_history smoke
check "git commit through a mise hook" git commit -q --allow-empty -m smoke
# --config like the maki nu tool: plain `nu -c` skips the plugin registry
check "nu loads its plugin registry" quiet nu --config /dev/null -c 'plugin list | ignore'
if [ -n "$SMOKE_NETWORK" ]; then
    check "gh api" gh api /rate_limit --jq .rate.limit
    check "git over https" git ls-remote https://github.com/cli/cli HEAD
fi
exit "$fails"
EOF

failed=0
for agent in "$@"; do
    echo "$agent"
    if ! (
        cd "$repo"
        NONO_SMOKE_TEST="$tmp/checks.sh" \
            SMOKE_WORKTREE="$repo/.wt/$agent" \
            SMOKE_NETWORK="$network" \
            MISE_TRUSTED_CONFIG_PATHS="$tmp" \
            NONO_ARGS="--silent ${NONO_ARGS:-}" \
            "$bin_dir/$agent.sh"
    ); then
        failed=1
    fi
done
exit "$failed"
