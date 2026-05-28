#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

run_pkg_tests() {
  local label="$1"
  local path="$2"
  echo ""
  echo "==> ${label}"
  cd "${path}"
  flutter pub get
  flutter test
}

echo "BoostDrive mobile test runner"
echo "Root: ${ROOT}"

run_pkg_tests "boostdrive_core" "${ROOT}/packages/boostdrive_core"
run_pkg_tests "boostdrive_services" "${ROOT}/packages/boostdrive_services"
run_pkg_tests "boostdrive_auth" "${ROOT}/packages/boostdrive_auth"
run_pkg_tests "boostdrive_ui" "${ROOT}/packages/boostdrive_ui"
run_pkg_tests "mobile app" "${ROOT}/apps/Mobile"

echo ""
echo "All mobile-related tests passed."
