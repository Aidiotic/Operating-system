#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Run NexusOS native installer (Asahi boot chain, dual-boot preserved).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/common.sh
source "${ROOT}/scripts/common.sh"

INSTALLER_DIR="${ROOT}/installer/upstream"
RELEASES="${ROOT}/installer/releases"
TMP="${NEXUSOS_INSTALLER_TMP:-/tmp/nexusos-install}"

configure_nexusos_branding() {
  export DISTRO="NexusOS"
  export DISTRO_DOCS="${NEXUSOS_GITHUB}"
  export REPO_BASE="${NEXUSOS_RELEASES}"
  export VERSION_FLAG="${NEXUSOS_RELEASES}/installer-latest"
  export INSTALLER_BASE="${NEXUSOS_RELEASES}"
  export INSTALLER_DATA="${NEXUSOS_GITHUB}/raw/main/installer/nexusos-installer-data.json"
  export INSTALLER_DATA_ALT="${NEXUSOS_RELEASES}/nexusos-installer-data.json"
  export EXPERT="${EXPERT:-0}"
}

run_from_release_tarball() {
  local pkg_ver pkg
  mkdir -p "$TMP"
  cd "$TMP"

  if [[ -f "${RELEASES}/latest" ]]; then
    pkg_ver="$(cat "${RELEASES}/latest")"
    pkg="${RELEASES}/installer-${pkg_ver}.tar.gz"
    if [[ -f "$pkg" ]]; then
      log "Using local installer build: $(basename "$pkg")"
      rm -rf ./*
      tar xzf "$pkg"
      cp "${ROOT}/installer/nexusos-installer-data.json" ./installer_data.json
      return 0
    fi
  fi

  log "Downloading installer from GitHub Releases..."
  pkg_ver="$(curl -fsSL "${NEXUSOS_RELEASES}/installer-latest" 2>/dev/null || echo "$NEXUSOS_VERSION")"
  pkg="installer-${pkg_ver}.tar.gz"
  curl -fsSL -o "$pkg" "${NEXUSOS_RELEASES}/${pkg}" || return 1
  curl -fsSL -o SHA256SUMS "${NEXUSOS_RELEASES}/SHA256SUMS" || return 1
  verify_checksum "$pkg" SHA256SUMS
  curl -fsSL -o installer_data.json "$INSTALLER_DATA" || \
    curl -fsSL -o installer_data.json "$INSTALLER_DATA_ALT"
  tar xf "$pkg"
}

run_from_upstream() {
  if [[ ! -d "${INSTALLER_DIR}/.git" ]]; then
    need_cmd git
    log "Fetching Asahi Linux installer submodule..."
    git -C "$ROOT" submodule update --init --depth 1 installer/upstream
  fi

  "${ROOT}/installer/patches/apply.sh"
  configure_nexusos_branding

  cd "$INSTALLER_DIR"
  if [[ -f build.sh ]] && [[ ! -f releases/latest ]]; then
    log "Building branded installer (first run)..."
    ./build.sh
  fi

  local pkg_ver
  pkg_ver="$(cat releases/latest 2>/dev/null || echo "$NEXUSOS_VERSION")"
  mkdir -p "$TMP"
  cd "$TMP"
  rm -rf ./*
  tar xzf "${INSTALLER_DIR}/releases/installer-${pkg_ver}.tar.gz"
  cp "${ROOT}/installer/nexusos-installer-data.json" ./installer_data.json
}

main() {
  [[ "$(uname -s)" == "Darwin" ]] || die "Asahi installer requires macOS."

  configure_nexusos_branding

  log "Starting NexusOS native installer (m1n1 → U-Boot → NexusOS kernel)..."
  log "Installer is built from this repository (release tarballs are not redistributed)."
  echo

  if [[ "${NEXUSOS_SKIP_RELEASE_INSTALLER:-1}" == "1" ]]; then
    run_from_upstream
  elif run_from_release_tarball 2>/dev/null; then
    :
  elif run_from_upstream; then
    :
  else
    die "Could not obtain NexusOS installer — build with ./installer/build.sh on macOS"
  fi

  cd "$TMP"
  if [[ -f install.sh ]]; then
    if [[ "$EUID" -ne 0 ]]; then
      log "Installer requires root — requesting sudo..."
      exec sudo ./install.sh "$@"
    else
      exec ./install.sh "$@"
    fi
  fi

  die "install.sh not found in ${TMP}"
}

main "$@"
