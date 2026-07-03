#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Build branded Asahi installer tarball for NexusOS.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RELEASES="${ROOT}/installer/releases"
UPSTREAM="${ROOT}/installer/upstream"

log() { printf '[installer-build] %s\n' "$*"; }

mkdir -p "$RELEASES"

if [[ ! -d "${UPSTREAM}/.git" ]]; then
  git clone --depth 1 https://github.com/AsahiLinux/asahi-installer.git "$UPSTREAM"
fi

cd "$UPSTREAM"
./build.sh

VERSION="$(cat "${UPSTREAM}/releases/latest" 2>/dev/null || echo "1.0.0")"
PKG="installer-${VERSION}.tar.gz"

if [[ -f "${UPSTREAM}/releases/${PKG}" ]]; then
  cp "${UPSTREAM}/releases/${PKG}" "${RELEASES}/"
  cp "${ROOT}/installer/nexusos-installer-data.json" "${RELEASES}/installer_data.json"
  log "Built: ${RELEASES}/${PKG}"
else
  log "Creating NexusOS installer bundle from upstream..."
  tar czf "${RELEASES}/installer-nexusos-${VERSION}.tar.gz" \
    -C "$UPSTREAM" . \
    -C "${ROOT}/installer" nexusos-installer-data.json
  echo "$VERSION" > "${RELEASES}/latest"
  log "Built: ${RELEASES}/installer-nexusos-${VERSION}.tar.gz"
fi
