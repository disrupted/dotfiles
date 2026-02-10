#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$ROOT_DIR"

nvim --headless \
	-u tests/minimal_init.lua \
	-c "PlenaryBustedDirectory tests { minimal_init = 'tests/minimal_init.lua' }" \
	-c "qa"
