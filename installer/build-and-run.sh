#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Build and run NexusOS installer from source (development).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/common.sh
source "${ROOT}/scripts/common.sh"

main() {
  log "NexusOS installer — build from source (development)"

  if [[ "$(uname -s)" == "Darwin" ]]; then
  exec "${ROOT}/installer/run-installer.sh" --from-source "$@"
  fi

  if [[ "$(uname -s)" == "Linux" && "$(id -u)" -eq 0 ]]; then
    warn "On Linux, building aarch64 rootfs for release artifacts..."
    ASAHI_KERNEL_USE_PREBUILT=1 "${ROOT}/build/rootfs/build-aarch64.sh"
  else
    warn "Skipping rootfs build (requires Linux root). Using existing releases/ if present."
  fi

  exec "${ROOT}/installer/run-installer.sh" --from-source "$@"
}

main "$@"
