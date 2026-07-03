#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Linux bare-metal / ISO install helper.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/common.sh
source "${ROOT}/scripts/common.sh"

show_iso_instructions() {
  cat <<EOF

NexusOS Dual-Boot ISO Installation
===================================

1. Download the ISO:
   ${NEXUSOS_RELEASES}/nexusos-x86_64.iso

2. Verify checksum:
   ${NEXUSOS_RELEASES}/SHA256SUMS

3. Write to USB (Linux):
   sudo dd if=nexusos-x86_64.iso of=/dev/sdX bs=4M status=progress

   Or use Ventoy / Rufus on Windows.

4. Boot from USB and follow the installer.

5. The installer will offer dual-boot with existing OS when detected.

Build ISO locally:
   ./build/iso/build-iso.sh

EOF
}

main() {
  if [[ "${1:-}" == "--iso-only" ]]; then
    show_iso_instructions
    exit 0
  fi

  log "NexusOS Linux Installer"
  log "======================="

  if [[ "$(id -u)" -eq 0 ]]; then
    die "Do not run as root. Boot from ISO for bare-metal install."
  fi

  show_iso_instructions

  if [[ -f "${ROOT}/releases/nexusos-x86_64.iso" ]]; then
    log "Local ISO found: ${ROOT}/releases/nexusos-x86_64.iso"
  fi
}

main "$@"
