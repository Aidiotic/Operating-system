#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Build branded NexusOS Asahi installer tarball for GitHub Releases.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RELEASES="${ROOT}/installer/releases"
UPSTREAM="${ROOT}/installer/upstream"
VERSION="$(cat "${ROOT}/VERSION")"

log() { printf '[installer-build] %s\n' "$*"; }
die() { printf '[installer-build] ERROR: %s\n' "$*" >&2; exit 1; }

mkdir -p "$RELEASES"

if [[ ! -d "${UPSTREAM}/.git" ]]; then
  log "Initializing asahi-installer submodule..."
  git -C "$ROOT" submodule update --init --depth 1 installer/upstream
fi

"${ROOT}/installer/patches/apply.sh"

if [[ -f "${ROOT}/installer/assets/nexusos.icns" ]]; then
  export LOGO="${ROOT}/installer/assets/nexusos.icns"
fi

cd "$UPSTREAM"
git submodule update --init --depth 1 m1n1 artwork asahi_firmware 2>/dev/null || \
  log "Submodule init partial — build may fetch deps online"

if [[ "$(uname -s)" != "Darwin" ]]; then
  log "Not on macOS — creating metadata-only installer bundle for CI/releases."
  PKG="installer-${VERSION}.tar.gz"
  STAGE="${ROOT}/installer/stage"
  rm -rf "$STAGE"
  mkdir -p "$STAGE"
  cp -a "${UPSTREAM}/src/." "$STAGE/"
  cp "${ROOT}/installer/nexusos-installer-data.json" "$STAGE/installer_data.json"
  echo "$VERSION" > "$STAGE/version.tag"
  tar czf "${RELEASES}/${PKG}" -C "$STAGE" .
  echo "$VERSION" > "${RELEASES}/latest"
  cp "${ROOT}/installer/nexusos-installer-data.json" "${RELEASES}/nexusos-installer-data.json"
  log "Built (linux stub): ${RELEASES}/${PKG}"
  exit 0
fi

./build.sh

PKG_VER="$(cat "${UPSTREAM}/releases/latest" 2>/dev/null || echo "$VERSION")"
PKG="installer-${PKG_VER}.tar.gz"

if [[ -f "${UPSTREAM}/releases/${PKG}" ]]; then
  cp "${UPSTREAM}/releases/${PKG}" "${RELEASES}/"
  echo "$PKG_VER" > "${RELEASES}/latest"
  cp "${ROOT}/installer/nexusos-installer-data.json" "${RELEASES}/nexusos-installer-data.json"
  log "Built: ${RELEASES}/${PKG}"
else
  die "Expected ${UPSTREAM}/releases/${PKG} after build"
fi
