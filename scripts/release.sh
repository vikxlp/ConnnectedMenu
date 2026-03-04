#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
rm -rf "${DIST_DIR}"
mkdir -p "${DIST_DIR}"
APP_VERSION="${APP_VERSION:-$(sed -nE 's/.*version = "([^"]+)".*/\1/p' "${ROOT_DIR}/Sources/ConnectsMenu/Version.swift")}" \
  SIGN_MODE="${SIGN_MODE:-adhoc}" APP_VERSION="${APP_VERSION}" ./scripts/package_app.sh
./scripts/create_dmg.sh
printf "Release artifacts located in %s\n" "${DIST_DIR}"
