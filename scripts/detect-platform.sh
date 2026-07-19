#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Detect host platform for NexusOS installer routing.

set -euo pipefail

detect_os() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux) echo "linux" ;;
    MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
    *) echo "unknown" ;;
  esac
}

detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64) echo "x86_64" ;;
    arm64|aarch64) echo "aarch64" ;;
    *) uname -m ;;
  esac
}

detect_wsl() {
  if [[ -f /proc/version ]] && grep -qi microsoft /proc/version; then
    echo "true"
  else
    echo "false"
  fi
}

main() {
  local os arch wsl
  os="$(detect_os)"
  arch="$(detect_arch)"
  wsl="false"

  if [[ "$os" == "linux" ]]; then
    wsl="$(detect_wsl)"
  fi

  echo "${os} ${arch} ${wsl}"
}

main "$@"
