#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Install Asahi platform packages (kernel, firmware, Mesa) into aarch64 chroot or releases/.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=build/kernel/versions.env
source "${ROOT}/build/kernel/versions.env"

CHROOT="${1:-}"
KERNEL_ONLY=0

log() { printf '[fetch-asahi-platform] %s\n' "$*"; }
die() { printf '[fetch-asahi-platform] ERROR: %s\n' "$*" >&2; exit 1; }

[[ "${1:-}" == "--kernel-only" ]] && { KERNEL_ONLY=1; CHROOT=""; shift || true; }

ASAHI_PACKAGES=(
  linux-image-asahi
  linux-headers-asahi
)

PLATFORM_PACKAGES=(
  asahi-audio
  asahi-wifi
  mesa-asahi
)

install_into_chroot() {
  local target="$1"
  local list=("${ASAHI_PACKAGES[@]}")
  [[ "$KERNEL_ONLY" == "0" ]] && list+=("${PLATFORM_PACKAGES[@]}")

  cat > "${target}/etc/apt/sources.list.d/asahi.list" <<EOF
deb [trusted=yes] ${ASAHI_REPO_URL} ${ASAHI_REPO_SUITE} main
EOF

  chroot "$target" apt-get update
  chroot "$target" env DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends "${list[@]}"
}

fetch_kernel_deb() {
  local tmp="${ROOT}/build/kernel/work/fetch"
  mkdir -p "$tmp" "${ROOT}/releases"
  cd "$tmp"

  echo "deb [trusted=yes] ${ASAHI_REPO_URL} ${ASAHI_REPO_SUITE} main" > asahi.list
  apt-get update -o Dir::Etc::sourcelist=asahi.list -o Dir::Etc::sourceparts=- -o APT::Architecture=arm64 2>/dev/null || \
    apt-get update

  apt-get download -o Dir::Etc::sourcelist=asahi.list linux-image-asahi 2>/dev/null || \
    die "Could not download linux-image-asahi from ${ASAHI_REPO_URL}"

  local deb
  deb="$(ls -1 linux-image-asahi*.deb | head -1)"
  cp "$deb" "${ROOT}/releases/nexusos-asahi-kernel_$(cat "${ROOT}/VERSION")_arm64.deb"
  log "Fetched: releases/nexusos-asahi-kernel_*_arm64.deb"
}

main() {
  if [[ -n "$CHROOT" ]]; then
    install_into_chroot "$CHROOT"
  elif [[ "$KERNEL_ONLY" == "1" ]]; then
    fetch_kernel_deb
  else
    die "Usage: fetch-asahi-platform.sh <chroot-path> | --kernel-only"
  fi
}

main "$@"
