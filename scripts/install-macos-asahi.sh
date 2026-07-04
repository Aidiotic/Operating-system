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
  warn "This will resize your macOS partition and install NexusOS for dual-boot."
  warn "Back up your Mac with Time Machine before continuing."
  echo
  read -r -p "Continue? [y/N] " confirm
  [[ "${confirm,,}" == "y" ]] || die "Installation cancelled."

  if [[ "${NEXUSOS_FROM_SOURCE:-0}" == "1" ]]; then
    log "Building installer from vendored submodule..."
    exec "${ROOT}/installer/run-installer.sh" --from-source "$@"
  fi

  log "Launching Asahi-based NexusOS installer..."
  exec "${ROOT}/installer/run-installer.sh" "$@"
}

main "$@"
