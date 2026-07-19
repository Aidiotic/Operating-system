#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# macOS UTM virtual machine installer (Apple Silicon — build from git clone).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/common.sh
source "${ROOT}/scripts/common.sh"

UTM_APP="/Applications/UTM.app"
INSTALL_DIR="${HOME}/Applications/NexusOS"
ARTIFACT="nexusos-aarch64.utm"

install_utm() {
  if [[ -d "$UTM_APP" ]]; then
    log "UTM already installed."
    return 0
  fi

  if ! command -v brew >/dev/null 2>&1; then
    die "Install UTM manually from https://mac.getutm.app or install Homebrew first."
  fi

  log "Installing UTM via Homebrew..."
  brew install --cask utm
}

build_utm_bundle() {
  local dest_dir="$1"
  mkdir -p "$dest_dir"
  local utm_path="${dest_dir}/${ARTIFACT}"
  local rootfs="${ROOT}/releases/nexusos-aarch64-rootfs.tar.xz"

  if [[ -f "${ROOT}/releases/${ARTIFACT}" ]]; then
    log "Using local build: releases/${ARTIFACT}"
    cp "${ROOT}/releases/${ARTIFACT}" "$utm_path"
    return 0
  fi

  if [[ ! -f "$rootfs" ]]; then
    cat <<EOF >&2

UTM requires an aarch64 rootfs tarball at:
  releases/nexusos-aarch64-rootfs.tar.xz

Build on Linux (or CI), then copy into your clone:
  sudo ./build/rootfs/build-aarch64.sh
  ./build/utm/build-utm.sh

See docs/REDISTRIBUTION_POLICY.md — UTM bundles are not downloaded from Releases.

EOF
    die "Missing ${rootfs}"
  fi

  log "Packaging UTM bundle from local rootfs..."
  "${ROOT}/build/utm/build-utm.sh"
  cp "${ROOT}/releases/${ARTIFACT}" "$utm_path"
}

main() {
  [[ "$(uname -s)" == "Darwin" ]] || die "UTM install requires macOS."

  if [[ "$(uname -m)" != "arm64" ]]; then
    die "UTM install is only supported on Apple Silicon. Intel Mac: run ./install.sh --iso"
  fi

  log "NexusOS UTM Virtual Machine Installer"
  log "======================================"
  echo
  warn "NexusOS is provided AS IS without warranty. See docs/DISCLAIMER.md."
  warn "UTM bundles are built from your git clone — not downloaded from GitHub Releases."
  echo

  install_utm
  mkdir -p "$INSTALL_DIR"
  build_utm_bundle "$INSTALL_DIR"

  local utm_bundle="${INSTALL_DIR}/${ARTIFACT}"
  [[ -e "$utm_bundle" ]] || die "UTM bundle not found at ${utm_bundle}"

  log "Opening NexusOS VM in UTM..."
  open "$utm_bundle"

  echo
  log "Done! Start the NexusOS VM from UTM."
  log "Default login: nexus (password expires on first login — run nexus-welcome)"
  log "Run 'nexus-welcome' inside the VM for setup wizard."
}

main "$@"
