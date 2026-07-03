#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Run Asahi-based NexusOS installer (downloads upstream asahi-installer).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/common.sh
source "${ROOT}/scripts/common.sh"

INSTALLER_DIR="${ROOT}/installer/upstream"
ASAHI_INSTALLER_REPO="${ASAHI_INSTALLER_REPO:-https://github.com/AsahiLinux/asahi-installer.git}"
ASAHI_INSTALLER_REF="${ASAHI_INSTALLER_REF:-main}"

fetch_asahi_installer() {
  if [[ -d "${INSTALLER_DIR}/.git" ]]; then
    log "Using cached asahi-installer."
    return 0
  fi

  need_cmd git
  log "Fetching Asahi Linux installer..."
  mkdir -p "${ROOT}/installer"
  git clone --depth 1 -b "$ASAHI_INSTALLER_REF" "$ASAHI_INSTALLER_REPO" "$INSTALLER_DIR"
}

configure_nexusos_branding() {
  export DISTRO="NexusOS"
  export REPO_BASE="${NEXUSOS_RELEASES}"
  export VERSION_FLAG="${NEXUSOS_RELEASES}/latest"
  export INSTALLER_BASE="${NEXUSOS_RELEASES}"
  export INSTALLER_DATA="${NEXUSOS_GITHUB}/raw/main/installer/nexusos-installer-data.json"
  export EXPERT="${EXPERT:-0}"
}

main() {
  [[ "$(uname -s)" == "Darwin" ]] || die "Asahi installer requires macOS."

  fetch_asahi_installer
  configure_nexusos_branding

  log "Starting NexusOS native installer (Asahi boot chain)..."
  log "Release artifacts: ${NEXUSOS_RELEASES}"
  echo

  cd "$INSTALLER_DIR"

  if [[ -f build.sh ]]; then
    log "Building branded installer..."
    ./build.sh
  fi

  if [[ -f install.sh ]]; then
    if [[ "$EUID" -ne 0 ]]; then
      log "Installer requires root — requesting sudo..."
      exec sudo -E ./install.sh "$@"
    else
      exec ./install.sh "$@"
    fi
  fi

  die "Asahi installer not found in ${INSTALLER_DIR}"
}

main "$@"
