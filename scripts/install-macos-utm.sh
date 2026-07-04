#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# macOS UTM virtual machine installer.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/common.sh
source "${ROOT}/scripts/common.sh"

UTM_APP="/Applications/UTM.app"
INSTALL_DIR="${HOME}/Applications/NexusOS"
ARTIFACT="nexusos-aarch64.utm"
ROOTFS_ARTIFACT="nexusos-aarch64-rootfs.tar.xz"

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

fetch_utm_bundle() {
  local dest_dir="$1"
  mkdir -p "$dest_dir"
  local utm_path="${dest_dir}/${ARTIFACT}"

  if [[ "${NEXUSOS_FROM_SOURCE:-0}" == "1" ]]; then
    log "Building UTM bundle from source..."
    "${ROOT}/build/utm/build-utm.sh"
    cp "${ROOT}/releases/${ARTIFACT}" "$utm_path"
    return 0
  fi

  local tmp
  tmp="$(mktemp -d)"
  if ! download_release "$ARTIFACT" "${tmp}/${ARTIFACT}" 2>/dev/null; then
    warn "No release artifact found at ${NEXUSOS_RELEASES}/${ARTIFACT}"
    warn "Build locally: ./build/utm/build-utm.sh  or wait for GitHub Release v${NEXUSOS_VERSION}"
    die "Download failed — tag v${NEXUSOS_VERSION} may not be published yet."
  fi
  download_release "SHA256SUMS" "${tmp}/SHA256SUMS" || true
  verify_checksum "${tmp}/${ARTIFACT}" "${tmp}/SHA256SUMS"
  cp "${tmp}/${ARTIFACT}" "$utm_path"
  rm -rf "$tmp"
}

main() {
  [[ "$(uname -s)" == "Darwin" ]] || die "UTM install requires macOS."

  log "NexusOS UTM Virtual Machine Installer"
  log "======================================"

  install_utm
  mkdir -p "$INSTALL_DIR"
  fetch_utm_bundle "$INSTALL_DIR"

  local utm_bundle="${INSTALL_DIR}/${ARTIFACT}"
  [[ -e "$utm_bundle" ]] || die "UTM bundle not found at ${utm_bundle}"

  log "Opening NexusOS VM in UTM..."
  open "$utm_bundle"

  echo
  log "Done! Start the NexusOS VM from UTM."
  log "Default login: nexus / nexus (change on first boot)"
  log "Run 'nexus-welcome' inside the VM for setup wizard."
}

main "$@"
