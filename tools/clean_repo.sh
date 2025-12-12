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

TARGETS=(
  "android/.gradle"
  "android/.kotlin"
  "android/gradlew"
  "android/gradlew.bat"
  "android/local.properties"
  "android/gradle/gradle-wrapper.jar"
  "android/app/src/main/java"
)

log "Removing Android build artifacts"
for rel_path in "${TARGETS[@]}"; do
  full_path="${REPO_ROOT}/${rel_path}"
  if [[ -e "${full_path}" ]]; then
    rm -rf "${full_path}"
    printf '  removed %s\n' "${rel_path}"
  else
    printf '  skipped %s (not found)\n' "${rel_path}"
  fi
done

run flutter clean
run find . -type f -name "*.g.dart" -delete
run find . -type f -name "*.freezed.dart" -delete
