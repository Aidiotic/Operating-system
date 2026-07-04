#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Build NexusOS aarch64 rootfs with Asahi platform integration.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=build/rootfs/common.sh
source "${ROOT}/build/rootfs/common.sh"
# shellcheck source=build/rootfs/common-asahi.sh
source "${ROOT}/build/rootfs/common-asahi.sh"

WORK="${ROOT}/build/rootfs/work/aarch64"
CHROOT="${WORK}/chroot"
OUTPUT="${ROOT}/releases"
RELEASE_NAME="nexusos-aarch64-rootfs.tar.xz"
SUITE="bookworm"
MIRROR="${DEBIAN_MIRROR:-http://deb.debian.org/debian}"

log() { printf '[build-aarch64] %s\n' "$*"; }
die() { printf '[build-aarch64] ERROR: %s\n' "$*" >&2; exit 1; }

[[ "$(id -u)" -eq 0 ]] || die "Run as root: sudo $0"
command -v debootstrap >/dev/null 2>&1 || die "Missing: debootstrap"

main() {
  log "Building NexusOS aarch64 rootfs (Asahi platform)..."
  rm -rf "$WORK"
  mkdir -p "$WORK" "$OUTPUT"

  "${ROOT}/build/packages/build-debs.sh" 2>/dev/null || log "Skipping deb build (build-debs unavailable)"

  log "Stage 1: debootstrap (minbase)..."
  debootstrap --arch=arm64 --variant=minbase \
    "$SUITE" "$CHROOT" "$MIRROR"

  if [[ "${NEXUSOS_CI_MINIMAL:-0}" == "1" ]]; then
    log "Stage 2: CI smoke-test branding..."
    cp "${ROOT}/os-release" "${CHROOT}/etc/os-release"
    mkdir -p "${CHROOT}/var/log/nexus" "${CHROOT}/etc/nexusos"
    echo "asahi" > "${CHROOT}/etc/nexusos/platform"
  else
    log "Stage 2: mount chroot, install packages..."
    setup_chroot_mounts "$CHROOT"
    trap 'teardown_chroot_mounts "$CHROOT"' EXIT

    prepare_chroot_apt "$CHROOT"
    install_desktop_packages "$CHROOT"
    install_asahi_kernel_deb "$CHROOT"
    install_asahi_platform "$CHROOT"
    install_nexus_debs "$CHROOT"
    apply_asahi_overlays "$CHROOT"
    apply_theme_and_branding "$CHROOT"
    "${ROOT}/build/rootfs/chroot-setup.sh" "$CHROOT" "aarch64"
    finalize_rootfs "$CHROOT"

    teardown_chroot_mounts "$CHROOT"
    trap - EXIT
  fi

  log "Stage 3: packing tarball..."
  pack_rootfs "$CHROOT" "$OUTPUT" "$RELEASE_NAME"
  log "Done: ${OUTPUT}/${RELEASE_NAME}"
}

main "$@"
