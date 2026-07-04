#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# NexusOS branding for vendored asahi-installer (no APFS/boot-chain patches).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UPSTREAM="${ROOT}/installer/upstream"
ASSETS="${ROOT}/installer/assets"

log() { printf '[installer-patches] %s\n' "$*"; }

[[ -d "${UPSTREAM}/src" ]] || { log "upstream missing — git submodule update --init installer/upstream"; exit 1; }

log "NexusOS installer branding (downstream of Asahi Linux)..."

# Branding is env-driven at runtime (DISTRO, INSTALLER_DATA, REPO_BASE).
# Optional custom m1n1 logo — never edit upstream tree.
if [[ -f "${ASSETS}/nexusos.icns" ]]; then
  export LOGO="${ASSETS}/nexusos.icns"
  log "Using custom logo: ${LOGO}"
fi

log "Dual-boot / APFS / recoveryOS logic unchanged."
