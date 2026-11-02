#!/usr/bin/env bash
set -euo pipefail
# Lives in ~/.config/nono/bin, outside every agent-writable directory, so an agent can't
# rewrite its own launcher (unlike ~/.config/pi = PI_CODING_AGENT_DIR).
# shellcheck source=SCRIPTDIR/agent.sh
source "$HOME/.config/nono/bin/agent.sh"

: "${PI_CODING_AGENT_DIR:=$(mise_env_get PI_CODING_AGENT_DIR)}"
: "${PI_CODING_AGENT_DIR:=$HOME/.pi/agent}"

nono_args+=(--allow "$PI_CODING_AGENT_DIR")

nono_exec pi pi "$@"
