#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Build NexusOS-branded Asahi kernel .deb for Apple Silicon (aarch64).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=build/kernel/versions.env
source "${ROOT}/build/kernel/versions.env"

OUTPUT="${ROOT}/releases"
WORK="${ROOT}/build/kernel/work"
KERNEL_SRC="${WORK}/linux"
VERSION="$(cat "${ROOT}/VERSION")"

log() { printf '[build-asahi-kernel] %s\n' "$*"; }
die() { printf '[build-asahi-kernel] ERROR: %s\n' "$*" >&2; exit 1; }

build_from_source() {
  log "Building Asahi kernel from source (tag: ${ASAHI_LINUX_TAG})..."
  mkdir -p "$WORK" "$OUTPUT"

  rm -rf "$KERNEL_SRC"
  git clone --depth 1 --branch "$ASAHI_LINUX_TAG" "$ASAHI_LINUX_REPO" "$KERNEL_SRC"

  cd "$KERNEL_SRC"
  make ARCH=arm64 asahi_defconfig
  ./scripts/kconfig/merge_config.sh -m .config "${ROOT}/build/kernel/asahi.config"
  make ARCH=arm64 olddefconfig

  export PATH="/usr/lib/ccache:${PATH}"
  make -j"$(nproc)" ARCH=arm64 Image modules dtbs
  make -j"$(nproc)" ARCH=arm64 bindeb-pkg \
    LOCALVERSION="${KERNEL_LOCALVERSION}" \
    KDEB_PKGVERSION="${VERSION}-1"

  local deb
  deb="$(find .. -maxdepth 1 -name '*image*nexusos*arm64.deb' -print 2>/dev/null | head -1)"
  [[ -n "$deb" ]] || deb="$(find .. -maxdepth 1 -name '*linux-image*arm64.deb' -print 2>/dev/null | head -1)"
  [[ -n "$deb" ]] || die "Kernel .deb not found after bindeb-pkg"

  cp "$deb" "${OUTPUT}/nexusos-asahi-kernel_${VERSION}_arm64.deb"
  log "Built: ${OUTPUT}/nexusos-asahi-kernel_${VERSION}_arm64.deb"
}

fetch_prebuilt() {
  log "Fetching prebuilt Asahi kernel (ASAHI_KERNEL_USE_PREBUILT=1)..."
  mkdir -p "$OUTPUT"
  "${ROOT}/build/kernel/fetch-asahi-platform.sh" --kernel-only
}

main() {
  if [[ "${ASAHI_KERNEL_USE_PREBUILT:-0}" == "1" ]]; then
    fetch_prebuilt
  else
    if [[ "$(uname -m)" != "aarch64" ]]; then
      warn_msg="Not on aarch64 — set ASAHI_KERNEL_USE_PREBUILT=1 or use ubuntu-24.04-arm CI."
      if [[ "${NEXUSOS_ALLOW_CROSS_KERNEL:-0}" != "1" ]]; then
        die "$warn_msg"
      fi
    fi
    build_from_source
  fi
}

main "$@"
