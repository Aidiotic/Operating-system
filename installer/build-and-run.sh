#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Build and run NexusOS installer from source (development).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/common.sh
source "${ROOT}/scripts/common.sh"

main() {
  log "Building NexusOS release artifacts from source..."

  if [[ "$(uname -s)" == "Linux" && "$(id -u)" -eq 0 ]]; then
    "${ROOT}/build/rootfs/build-aarch64.sh"
  else
    warn "Skipping rootfs build (requires Linux root). Using existing releases/ if present."
  fi

  exec "${ROOT}/installer/run-installer.sh" "$@"
}

main "$@"
