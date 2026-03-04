#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
APP_NAME="Connects"
EXECUTABLE_NAME="ConnectsMenu"
APP_DIR="${DIST_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
TEMPLATE_PLIST="${ROOT_DIR}/metadata/Info.plist"
PLIST_FILE="${CONTENTS_DIR}/Info.plist"
VERSION_FILE="${ROOT_DIR}/Sources/ConnectsMenu/Version.swift"
SIGN_MODE="${SIGN_MODE:-adhoc}"
BUNDLE_IDENTIFIER="${BUNDLE_IDENTIFIER:-me.vikalp.connects}"

if [[ ! -f "${VERSION_FILE}" ]]; then
  echo "Version file not found: ${VERSION_FILE}" >&2
  exit 1
fi

if [[ -z "${APP_VERSION:-}" ]]; then
  APP_VERSION="$(sed -nE 's/.*version = "([^"]+)".*/\1/p' "${VERSION_FILE}" | head -n 1)"
fi

if [[ -z "${APP_VERSION:-}" ]]; then
  echo "Could not resolve APP_VERSION." >&2
  exit 1
fi

echo "Building ${EXECUTABLE_NAME} (${APP_VERSION})"
swift build -c release --package-path "${ROOT_DIR}"

rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

cp "${ROOT_DIR}/.build/release/${EXECUTABLE_NAME}" "${MACOS_DIR}/${EXECUTABLE_NAME}"
chmod +x "${MACOS_DIR}/${EXECUTABLE_NAME}"

sed \
  -e "s/__VERSION__/${APP_VERSION}/g" \
  -e "s/__BUNDLE_IDENTIFIER__/${BUNDLE_IDENTIFIER}/g" \
  "${TEMPLATE_PLIST}" > "${PLIST_FILE}"

case "${SIGN_MODE}" in
  adhoc)
    echo "Signing app with ad-hoc signature"
    codesign --force --deep --sign - "${APP_DIR}"
    ;;
  developer-id)
    if [[ -z "${CODESIGN_IDENTITY:-}" ]]; then
      echo "CODESIGN_IDENTITY is required when SIGN_MODE=developer-id" >&2
      exit 1
    fi
    echo "Signing app with Developer ID identity: ${CODESIGN_IDENTITY}"
    codesign --force --deep --options runtime --timestamp --sign "${CODESIGN_IDENTITY}" "${APP_DIR}"
    ;;
  none)
    echo "Skipping code signing"
    ;;
  *)
    echo "Unknown SIGN_MODE: ${SIGN_MODE}" >&2
    exit 1
    ;;
esac

echo "Packaged app: ${APP_DIR}"
