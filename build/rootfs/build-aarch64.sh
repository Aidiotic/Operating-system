#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Build NexusOS aarch64 rootfs (Debian bookworm + GNOME).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=build/rootfs/common.sh
source "${ROOT}/build/rootfs/common.sh"

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
  log "Building NexusOS aarch64 rootfs..."
  rm -rf "$WORK"
  mkdir -p "$WORK" "$OUTPUT"

  log "Stage 1: debootstrap (minbase only)..."
  debootstrap --arch=arm64 --variant=minbase \
    "$SUITE" "$CHROOT" "$MIRROR"

  log "Stage 2: mount chroot and install desktop..."
  setup_chroot_mounts "$CHROOT"
  trap 'teardown_chroot_mounts "$CHROOT"' EXIT

  if [[ "${NEXUSOS_CI_MINIMAL:-0}" == "1" ]]; then
    log "Stage 2b: CI smoke-test (debootstrap only, skip chroot apt)..."
  else
    prepare_chroot_apt "$CHROOT"
    install_desktop_packages "$CHROOT"
  fi

  if [[ "${NEXUSOS_CI_MINIMAL:-0}" == "1" ]]; then
    log "Stage 3: CI smoke-test branding..."
    cp "${ROOT}/os-release" "${CHROOT}/etc/os-release"
    mkdir -p "${CHROOT}/var/log/nexus"
  else
    log "Stage 3: NexusOS customization..."
    "${ROOT}/build/rootfs/chroot-setup.sh" "$CHROOT" "aarch64"
  fi

  finalize_rootfs "$CHROOT"
  teardown_chroot_mounts "$CHROOT"
  trap - EXIT

  log "Stage 4: packing tarball..."
  pack_rootfs "$CHROOT" "$OUTPUT" "$RELEASE_NAME"

  log "Done: ${OUTPUT}/${RELEASE_NAME}"
}

main "$@"
