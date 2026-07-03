#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Intel Mac EFI dual-boot helper.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/common.sh
source "${ROOT}/scripts/common.sh"

main() {
  [[ "$(uname -s)" == "Darwin" ]] || die "Intel Mac install requires macOS."

  log "NexusOS Intel Mac Installer"
  log "==========================="
  echo
  warn "Native EFI dual-boot on Intel Mac requires manual partitioning."
  warn "Recommended: use UTM instead: ./install.sh --utm"
  echo
  log "Steps for EFI dual-boot:"
  echo "  1. Download nexusos-x86_64.iso from GitHub Releases"
  echo "  2. Create a Linux partition with Disk Utility or diskutil"
  echo "  3. Boot from USB (hold Option at startup)"
  echo "  4. Follow on-screen installer"
  echo
  log "Release URL: ${NEXUSOS_RELEASES}/nexusos-x86_64.iso"
  echo
  read -r -p "Open UTM installer instead? [Y/n] " use_utm
  if [[ "${use_utm:-Y}" != "n" && "${use_utm:-Y}" != "N" ]]; then
    exec "${ROOT}/scripts/install-macos-utm.sh" "$@"
  fi
}

main "$@"
