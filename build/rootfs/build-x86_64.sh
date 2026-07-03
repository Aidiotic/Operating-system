#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Build NexusOS x86_64 rootfs (Debian bookworm + GNOME).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK="${ROOT}/build/rootfs/work/x86_64"
CHROOT="${WORK}/chroot"
OUTPUT="${ROOT}/releases"
RELEASE_NAME="nexusos-x86_64-rootfs.tar.xz"

SUITE="bookworm"
MIRROR="${DEBIAN_MIRROR:-http://deb.debian.org/debian}"

log() { printf '[build-x86_64] %s\n' "$*"; }
die() { printf '[build-x86_64] ERROR: %s\n' "$*" >&2; exit 1; }

[[ "$(id -u)" -eq 0 ]] || die "Run as root: sudo $0"

need_cmd() { command -v "$1" >/dev/null 2>&1 || die "Missing: $1"; }
need_cmd debootstrap
need_cmd tar
need_cmd xz

PACKAGES=(
  systemd systemd-sysv
  network-manager sudo bash-completion
  gnome-core gdm3
  firefox-esr
  gnome-terminal nautilus
  gnome-calculator gnome-text-editor
  gnome-software
  apt-transport-https ca-certificates curl wget
  neofetch htop
  locales
)

main() {
  log "Building NexusOS x86_64 rootfs..."
  rm -rf "$WORK"
  mkdir -p "$WORK" "$OUTPUT"

  log "Stage 1: debootstrap..."
  debootstrap --arch=amd64 --variant=minbase \
    --include="$(IFS=,; echo "${PACKAGES[*]}")" \
    "$SUITE" "$CHROOT" "$MIRROR"

  log "Stage 2: chroot setup..."
  mount --bind /dev "$CHROOT/dev"
  mount --bind /dev/pts "$CHROOT/dev/pts"
  mount -t proc proc "$CHROOT/proc"
  mount -t sysfs sys "$CHROOT/sys"

  trap 'umount -R "$CHROOT" 2>/dev/null || true' EXIT

  echo 'deb http://deb.debian.org/debian bookworm-updates main' >> "$CHROOT/etc/apt/sources.list"
  echo 'deb http://security.debian.org/debian-security bookworm-security main' >> "$CHROOT/etc/apt/sources.list"

  chroot "$CHROOT" apt-get update
  chroot "$CHROOT" apt-get install -y --no-install-recommends locales
  chroot "$CHROOT" sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
  chroot "$CHROOT" locale-gen

  "${ROOT}/build/rootfs/chroot-setup.sh" "$CHROOT" "x86_64"

  chroot "$CHROOT" apt-get clean
  rm -rf "$CHROOT/var/lib/apt/lists"/*

  umount -R "$CHROOT" 2>/dev/null || true
  trap - EXIT

  log "Stage 3: packing tarball..."
  tar -C "$CHROOT" -cJf "${OUTPUT}/${RELEASE_NAME}" .

  log "Done: ${OUTPUT}/${RELEASE_NAME}"
  sha256sum "${OUTPUT}/${RELEASE_NAME}" >> "${OUTPUT}/SHA256SUMS" 2>/dev/null || \
    shasum -a 256 "${OUTPUT}/${RELEASE_NAME}" >> "${OUTPUT}/SHA256SUMS"
}

main "$@"
