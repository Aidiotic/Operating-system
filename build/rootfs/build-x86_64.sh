#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Build NexusOS x86_64 rootfs (Debian bookworm + GNOME).

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

  log "Stage 1: debootstrap (minbase only)..."
  debootstrap --arch=amd64 --variant=minbase \
    "$SUITE" "$CHROOT" "$MIRROR"

  log "Stage 2: mount chroot and install desktop..."
  setup_chroot_mounts "$CHROOT"
  trap 'teardown_chroot_mounts "$CHROOT"' EXIT

  prepare_chroot_apt "$CHROOT"
  install_desktop_packages "$CHROOT"

  log "Stage 3: NexusOS customization..."
  "${ROOT}/build/rootfs/chroot-setup.sh" "$CHROOT" "x86_64"

  finalize_rootfs "$CHROOT"
  teardown_chroot_mounts "$CHROOT"
  trap - EXIT

  log "Stage 4: packing tarball..."
  pack_rootfs "$CHROOT" "$OUTPUT" "$RELEASE_NAME"

  log "Done: ${OUTPUT}/${RELEASE_NAME}"
}

main "$@"
