#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Build NexusOS rootfs (x86_64 / WSL / ISO).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=build/rootfs/common.sh
source "${ROOT}/build/rootfs/common.sh"

WORK="${ROOT}/build/rootfs/work/x86_64"
CHROOT="${WORK}/chroot"
OUTPUT="${ROOT}/releases"
RELEASE_NAME="nexusos-x86_64-rootfs.tar.xz"
SUITE="bookworm"
MIRROR="${DEBIAN_MIRROR:-http://deb.debian.org/debian}"

log() { printf '[build-x86_64] %s\n' "$*"; }
die() { printf '[build-x86_64] ERROR: %s\n' "$*" >&2; exit 1; }

[[ "$(id -u)" -eq 0 ]] || die "Run as root: sudo $0"
command -v debootstrap >/dev/null 2>&1 || die "Missing: debootstrap"

main() {
  log "Building NexusOS x86_64 rootfs..."
  rm -rf "$WORK"
  mkdir -p "$WORK" "$OUTPUT"

  "${ROOT}/build/packages/build-debs.sh" 2>/dev/null || log "Skipping deb build"

  debootstrap --arch=amd64 --variant=minbase \
    "$SUITE" "$CHROOT" "$MIRROR"

  if [[ "${NEXUSOS_CI_MINIMAL:-0}" == "1" ]]; then
    cp "${ROOT}/os-release" "${CHROOT}/etc/os-release"
    mkdir -p "${CHROOT}/var/log/nexus" "${CHROOT}/etc/nexusos"
    echo "generic" > "${CHROOT}/etc/nexusos/platform"
  else
    setup_chroot_mounts "$CHROOT"
    trap 'teardown_chroot_mounts "$CHROOT"' EXIT

    prepare_chroot_apt "$CHROOT"
    install_desktop_packages "$CHROOT"
    log "Installing x86_64 kernel for ISO/WSL..."
    chroot "$CHROOT" env DEBIAN_FRONTEND=noninteractive \
      apt-get install -y --no-install-recommends linux-image-amd64 initramfs-tools
    chroot "$CHROOT" update-initramfs -u -k all 2>/dev/null || true
    install_nexus_debs "$CHROOT"
    apply_theme_and_branding "$CHROOT"
    mkdir -p "${CHROOT}/etc/nexusos"
    echo "generic" > "${CHROOT}/etc/nexusos/platform"
    "${ROOT}/build/rootfs/chroot-setup.sh" "$CHROOT" "x86_64"
    finalize_rootfs "$CHROOT"

    teardown_chroot_mounts "$CHROOT"
    trap - EXIT
  fi

  pack_rootfs "$CHROOT" "$OUTPUT" "$RELEASE_NAME"
  log "Done: ${OUTPUT}/${RELEASE_NAME}"
}

main "$@"
