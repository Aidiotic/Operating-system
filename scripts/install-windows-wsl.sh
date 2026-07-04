#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Windows WSL2 installer for NexusOS.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/common.sh
source "${ROOT}/scripts/common.sh"

DISTRO_NAME="NexusOS"
INSTALL_PATH="${NEXUSOS_WSL_PATH:-C:\\NexusOS}"
ARTIFACT="nexusos-x86_64-rootfs.tar.xz"

check_wsl() {
  if ! command -v wsl.exe >/dev/null 2>&1 && ! command -v wsl >/dev/null 2>&1; then
    die "WSL not found. Enable WSL2: wsl --install"
  fi

  local wsl_cmd="wsl"
  command -v wsl.exe >/dev/null 2>&1 && wsl_cmd="wsl.exe"

  if ! $wsl_cmd --status >/dev/null 2>&1; then
    warn "WSL may not be configured. Run: wsl --install"
  fi
}

fetch_rootfs() {
  local dest="$1"

  if [[ "${NEXUSOS_FROM_SOURCE:-0}" == "1" ]]; then
    if [[ "$(uname -s)" != "Linux" ]]; then
      die "--from-source rootfs build requires Linux. On Windows, build with: sudo ./build/rootfs/build-x86_64.sh"
    fi
    log "Building x86_64 rootfs from source (requires root)..."
    sudo env NEXUSOS_CI_MINIMAL=0 "${ROOT}/build/rootfs/build-x86_64.sh"
    cp "${ROOT}/releases/${ARTIFACT}" "$dest"
    return 0
  fi

  local tmp
  tmp="$(mktemp -d)"
  if ! download_release "$ARTIFACT" "${tmp}/${ARTIFACT}" 2>/dev/null; then
    warn "No release at ${NEXUSOS_RELEASES}/${ARTIFACT}"
    warn "Publish a release (git tag v${NEXUSOS_VERSION}) or run: sudo ./build/rootfs/build-x86_64.sh"
    die "Download failed."
  fi
  download_release "SHA256SUMS" "${tmp}/SHA256SUMS" || true
  verify_checksum "${tmp}/${ARTIFACT}" "${tmp}/SHA256SUMS"
  cp "${tmp}/${ARTIFACT}" "$dest"
  rm -rf "$tmp"
}

configure_wsl() {
  local wsl_cmd="wsl"
  command -v wsl.exe >/dev/null 2>&1 && wsl_cmd="wsl.exe"

  log "Configuring NexusOS for systemd and WSLg..."
  $wsl_cmd -d "$DISTRO_NAME" -- bash -c '
    set -e
    mkdir -p /var/log/nexus
    if ! grep -q "\[boot\]" /etc/wsl.conf 2>/dev/null; then
      cat >> /etc/wsl.conf <<EOF
[boot]
systemd=true

[user]
default=nexus
EOF
    fi
    nexus-welcome --non-interactive || true
  ' || warn "Post-install config will run on first login."
}

main() {
  log "NexusOS WSL2 Installer"
  log "======================"

  check_wsl

  local wsl_cmd="wsl"
  command -v wsl.exe >/dev/null 2>&1 && wsl_cmd="wsl.exe"

  if $wsl_cmd -l -q 2>/dev/null | grep -qx "$DISTRO_NAME"; then
    warn "Distro '${DISTRO_NAME}' already exists."
    read -r -p "Remove and reinstall? [y/N] " reinstall
    [[ "${reinstall,,}" == "y" ]] || die "Aborted."
    $wsl_cmd --unregister "$DISTRO_NAME" || true
  fi

  local tmp
  tmp="$(mktemp -d)"
  fetch_rootfs "${tmp}/${ARTIFACT}"

  log "Importing NexusOS into WSL2 at ${INSTALL_PATH}..."
  $wsl_cmd --import "$DISTRO_NAME" "$INSTALL_PATH" "${tmp}/${ARTIFACT}"
  rm -rf "$tmp"

  configure_wsl

  echo
  log "NexusOS installed successfully!"
  log "Launch with:  wsl -d NexusOS"
  log "Default user: nexus (password: nexus — change with passwd)"
  log "GUI apps:     export DISPLAY (WSLg auto-configures on Win11)"
  log "Software:     nexus-store  or  sudo apt install <package>"
  log "Updates:      nexus-update"
}

main "$@"
