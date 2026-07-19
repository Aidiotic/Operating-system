#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# NexusOS universal installer entrypoint.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/common.sh
source "${ROOT}/scripts/common.sh"

MODE="auto"
FROM_SOURCE=0

usage() {
  cat <<EOF
NexusOS Installer v${NEXUSOS_VERSION}

Install NexusOS on Mac or Windows:

  ./install.sh              Auto-detect platform and install
  ./install.sh --utm          macOS: install UTM virtual machine
  ./install.sh --native       macOS Apple Silicon: native dual-boot
  ./install.sh --wsl          Windows: import WSL2 distro
  ./install.sh --iso          Dual-boot ISO instructions

One-liner (clone + install):
  curl -fsSL ${NEXUSOS_GITHUB}/raw/main/scripts/bootstrap.sh | sh

Documentation: ${NEXUSOS_GITHUB}#readme
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --utm) MODE="utm"; shift ;;
      --native) MODE="native"; shift ;;
      --wsl) MODE="wsl"; shift ;;
      --iso) MODE="iso"; shift ;;
      --from-source) FROM_SOURCE=1; shift ;;
      --help|-h) usage; exit 0 ;;
      *) die "Unknown option: $1 (try --help)" ;;
    esac
  done
}

route_installer() {
  read -r host_os host_arch host_wsl < <("${ROOT}/scripts/detect-platform.sh")

  log "NexusOS Installer v${NEXUSOS_VERSION}"
  log "https://github.com/${NEXUSOS_REPO}"
  log "Detected: os=${host_os} arch=${host_arch} wsl=${host_wsl}"
  echo
  warn "NexusOS is provided AS IS without warranty. See docs/DISCLAIMER.md."
  echo
  export NEXUSOS_FROM_SOURCE="${FROM_SOURCE}"

  case "$MODE" in
    auto)
      case "$host_os" in
        macos)
          if [[ "$host_arch" == "aarch64" ]]; then
            log "Apple Silicon Mac — starting native dual-boot installer."
            log "Use --utm for a virtual machine instead."
            exec "${ROOT}/scripts/install-macos-asahi.sh" "$@"
          elif [[ "$host_arch" == "x86_64" ]]; then
            log "Intel Mac — installing UTM virtual machine."
            exec "${ROOT}/scripts/install-macos-utm.sh" "$@"
          else
            die "Unsupported Mac architecture: ${host_arch}"
          fi
          ;;
        windows)
          exec "${ROOT}/scripts/install-windows-wsl.sh" "$@"
          ;;
        linux)
          if [[ "$host_wsl" == "true" ]]; then
            die "Already inside WSL. Run from Windows PowerShell instead."
          fi
          exec "${ROOT}/scripts/install-linux.sh" "$@"
          ;;
        *)
          die "Unsupported OS. NexusOS installs on macOS or Windows."
          ;;
      esac
      ;;
    utm)
      [[ "$host_os" == "macos" ]] || die "--utm requires macOS"
      exec "${ROOT}/scripts/install-macos-utm.sh" "$@"
      ;;
    native)
      [[ "$host_os" == "macos" && "$host_arch" == "aarch64" ]] \
        || die "--native requires Apple Silicon Mac"
      exec "${ROOT}/scripts/install-macos-asahi.sh" "$@"
      ;;
    wsl)
      exec "${ROOT}/scripts/install-windows-wsl.sh" "$@"
      ;;
    iso)
      exec "${ROOT}/scripts/install-linux.sh" --iso-only "$@"
      ;;
  esac
}

parse_args "$@"
route_installer "$@"
