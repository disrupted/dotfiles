#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=SCRIPTDIR/agent.sh
source "$HOME/.config/nono/bin/agent.sh"

nono_exec maki maki "$@"
