#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/../safehouse/agent.sh
source "$HOME/.config/safehouse/agent.sh"

: "${PI_CODING_AGENT_DIR:=$(mise_env_get PI_CODING_AGENT_DIR)}"

safehouse_args+=(
    --add-dirs="$PI_CODING_AGENT_DIR"
    --env-pass="PI_SERVER_USERNAME,PI_SERVER_PASSWORD"
)

safehouse_exec pi "$@"
