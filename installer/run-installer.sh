#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Run NexusOS native installer (downstream of Asahi Linux; dual-boot preserved).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/common.sh
source "${ROOT}/scripts/common.sh"

INSTALLER_DIR="${ROOT}/installer/upstream"
RELEASES="${ROOT}/installer/releases"
TMP="${NEXUSOS_INSTALLER_TMP:-/tmp/nexusos-install}"
FROM_SOURCE=0

usage() {
  cat <<EOF
NexusOS native installer (downstream of Asahi Linux)

Usage:
  ./installer/run-installer.sh              Download branded installer from Releases
  ./installer/run-installer.sh --from-source  Build from vendored submodule (dev)
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --from-source) FROM_SOURCE=1; shift ;;
      -h|--help) usage; exit 0 ;;
      *) break ;;
    esac
  done
  REMAINING_ARGS=("$@")
}

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

  log "Downloading branded NexusOS installer from GitHub Releases..."
  pkg_ver="$(curl -fsSL "${NEXUSOS_RELEASES}/installer-latest" 2>/dev/null || echo "$NEXUSOS_VERSION")"
  pkg="installer-${pkg_ver}.tar.gz"
  curl -fsSL -o "$pkg" "${NEXUSOS_RELEASES}/${pkg}" || return 1
  curl -fsSL -o installer_data.json "$INSTALLER_DATA" || \
    curl -fsSL -o installer_data.json "$INSTALLER_DATA_ALT"
  tar xf "$pkg"
}

run_from_source() {
  log "Building from vendored asahi-installer submodule (--from-source)..."
  if [[ ! -d "${INSTALLER_DIR}/.git" ]]; then
    need_cmd git
    git -C "$ROOT" submodule update --init --recursive installer/upstream
  fi

  "${ROOT}/installer/build.sh"

  local pkg_ver
  pkg_ver="$(cat "${RELEASES}/latest" 2>/dev/null || echo "$NEXUSOS_VERSION")"
  mkdir -p "$TMP"
  cd "$TMP"
  rm -rf ./*
  tar xzf "${RELEASES}/installer-${pkg_ver}.tar.gz"
  cp "${ROOT}/installer/nexusos-installer-data.json" ./installer_data.json
}

main() {
  parse_args "$@"
  set -- "${REMAINING_ARGS[@]}"

  [[ "$(uname -s)" == "Darwin" ]] || die "Asahi installer requires macOS."

  configure_nexusos_branding

  log "NexusOS installer (downstream of Asahi Linux)"
  log "Boot chain: m1n1 → U-Boot → NexusOS kernel (dual-boot with macOS preserved)"
  log "Release artifacts: ${NEXUSOS_RELEASES}"
  echo

  if [[ "$FROM_SOURCE" == "1" ]]; then
    run_from_source
  elif run_from_release_tarball; then
    :
  else
    die "Could not download NexusOS installer — use --from-source after: git submodule update --init installer/upstream"
  fi

  cd "$TMP"
  if [[ -f install.sh ]]; then
    if [[ "$EUID" -ne 0 ]]; then
      log "Installer requires root — requesting sudo..."
      exec sudo -E ./install.sh "$@"
    else
      exec ./install.sh "$@"
    fi
  fi

  die "install.sh not found in ${TMP}"
}

main "$@"
