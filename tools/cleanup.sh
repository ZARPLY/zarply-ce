#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[cleanup] Running clean_repo.sh"
"${SCRIPT_DIR}/clean_repo.sh"

echo "[cleanup] Running clean_env.sh"
"${SCRIPT_DIR}/clean_env.sh"
