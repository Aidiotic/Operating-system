#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Apply NexusOS branding overlays to vendored asahi-installer (no boot-chain changes).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UPSTREAM="${ROOT}/installer/upstream"
PATCHES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { printf '[installer-patches] %s\n' "$*"; }

[[ -d "${UPSTREAM}/src" ]] || { log "upstream missing — run: git submodule update --init installer/upstream"; exit 1; }

log "Applying NexusOS branding to asahi-installer..."

# Downstream docs URL in installer UI (util.py reads DISTRO_DOCS from env at runtime;
# this default helps when running extracted tarball without our bootstrap exports).
if [[ -f "${UPSTREAM}/src/util.py" ]]; then
  sed -i 's|DISTRO_DOCS = os.environ.get("DISTRO_DOCS", "https://alx.sh/w")|DISTRO_DOCS = os.environ.get("DISTRO_DOCS", "https://github.com/Aidiotic/Operating-system")|' \
    "${UPSTREAM}/src/util.py" 2>/dev/null || true
fi

if [[ -f "${PATCHES}/nexusos-logo.icns.placeholder" ]]; then
  export LOGO="${PATCHES}/nexusos-logo.icns.placeholder"
fi

log "Patches applied (dual-boot / APFS logic unchanged)."
