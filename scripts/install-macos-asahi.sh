#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Apple Silicon Mac native dual-boot installer (Asahi downstream).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/common.sh
source "${ROOT}/scripts/common.sh"

main() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    die "Native Mac install must run from macOS."
  fi

  if [[ "$(uname -m)" != "arm64" ]]; then
    die "Native dual-boot requires Apple Silicon (arm64)."
  fi

  log "NexusOS Apple Silicon Native Installer"
  log "======================================="
  echo
  warn "NexusOS is provided AS IS. Installation may cause data loss or an unbootable system."
  warn "Risks include: partition resize, boot-loader changes, and unbootable macOS."
  warn "Apple Silicon builds depend on proprietary Apple firmware via the Asahi Linux platform."
  warn "Maintain Apple Recovery options. Dual-boot stability is not guaranteed."
  warn "Back up your Mac with Time Machine before continuing."
  echo
  read -r -p "Type YES to accept risks and continue: " confirm
  [[ "$confirm" == "YES" ]] || die "Installation cancelled."

  if [[ "${NEXUSOS_FROM_SOURCE:-0}" == "1" ]]; then
    log "Building installer from source..."
    exec "${ROOT}/installer/build-and-run.sh" "$@"
  fi

  log "Launching Asahi-based NexusOS installer..."
  exec "${ROOT}/installer/run-installer.sh" "$@"
}

main "$@"
