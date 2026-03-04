#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
APP_VERSION="${APP_VERSION:-$(sed -nE 's/.*version = "([^"]+)".*/\1/p' "${ROOT_DIR}/Sources/ConnectsMenu/Version.swift")}"
SIGN_MODE="${SIGN_MODE:-adhoc}"
export APP_VERSION SIGN_MODE

rm -rf "${DIST_DIR}"
mkdir -p "${DIST_DIR}"

./scripts/package_app.sh
./scripts/create_dmg.sh
printf "Release artifacts located in %s\n" "${DIST_DIR}"
