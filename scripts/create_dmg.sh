#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
APP_NAME="Connects"
APP_DIR="${DIST_DIR}/${APP_NAME}.app"
VERSION_FILE="${ROOT_DIR}/Sources/ConnectsMenu/Version.swift"
if [[ -z "${APP_VERSION:-}" ]]; then
  APP_VERSION="$(sed -nE 's/.*version = "([^"]+)".*/\1/p' "${VERSION_FILE}")"
fi
DMG_NAME="${APP_NAME}-v${APP_VERSION}.dmg"
DMG_PATH="${DIST_DIR}/${DMG_NAME}"

if [[ ! -d "${APP_DIR}" ]]; then
  echo "App bundle not found: ${APP_DIR}" >&2
  exit 1
fi

rm -f "${DMG_PATH}"
hdiutil create -volname "${APP_NAME}" -srcfolder "${APP_DIR}" -ov -format UDZO "${DMG_PATH}"
shasum -a 256 "${DMG_PATH}" > "${DIST_DIR}/SHA256SUMS.txt"
