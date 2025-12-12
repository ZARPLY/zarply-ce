#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

log() {
  printf '\n==> %s\n' "$*"
}

run() {
  log "Running: $*"
  "$@"
}

run_yes() {
  log "Running (auto-yes): $*"
  set +o pipefail
  if ! yes | "$@"; then
    local status=$?
    set -o pipefail
    return "${status}"
  fi
  set -o pipefail
}

run_yes flutter pub cache clean
run rm -rfv "${HOME}/.gradle/caches/build-cache-1/"

run flutter doctor -v
run_yes flutter doctor --android-licenses
run flutter config --enable-web
run flutter config --enable-android
run flutter precache --web
run flutter precache --android
