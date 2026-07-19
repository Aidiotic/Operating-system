#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Build bootable x86_64 ISO for dual-boot installation.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK="${ROOT}/build/iso/work"
OUTPUT="${ROOT}/releases"
ISO_NAME="nexusos-x86_64.iso"
ROOTFS="${ROOT}/releases/nexusos-x86_64-rootfs.tar.xz"

log() { printf '[build-iso] %s\n' "$*"; }
die() { printf '[build-iso] ERROR: %s\n' "$*" >&2; exit 1; }

[[ "$(id -u)" -eq 0 ]] || die "Run as root: sudo $0"
command -v xorriso >/dev/null 2>&1 || die "Install xorriso: apt install xorriso"
command -v grub-mkrescue >/dev/null 2>&1 || die "Install grub: apt install grub-pc-bin grub-efi-amd64-bin"

main() {
  log "Building NexusOS ISO..."

  if [[ ! -f "$ROOTFS" ]]; then
    log "Rootfs not found — building first..."
    "${ROOT}/build/rootfs/build-x86_64.sh"
  fi

  rm -rf "$WORK"
  mkdir -p "$WORK"/{iso,live,boot/grub}
  mkdir -p "$OUTPUT"

  log "Extracting rootfs for live boot..."
  mkdir -p "$WORK/live/filesystem"
  tar -xJf "$ROOTFS" -C "$WORK/live/filesystem"

  cat > "$WORK/boot/grub/grub.cfg" <<'EOF'
set timeout=10
set default=0

menuentry "NexusOS Live (try without installing)" {
    linux /live/vmlinuz boot=live quiet splash
    initrd /live/initrd.img
}

# Install entry is a placeholder until a real installer hook exists (preview posture).
menuentry "Install NexusOS (preview — unavailable)" {
    linux /live/vmlinuz boot=live quiet splash
    initrd /live/initrd.img
}
EOF

  cp "${ROOT}/configs/grub/theme.txt" "$WORK/boot/grub/" 2>/dev/null || true

  local vmlinuz initrd
  vmlinuz="$(find "$WORK/live/filesystem" -path '*/boot/vmlinuz*' -type f 2>/dev/null | sort -V | tail -1 || true)"
  initrd="$(find "$WORK/live/filesystem" \( -path '*/boot/initrd.img*' -o -path '*/boot/initrd-*' \) -type f 2>/dev/null | sort -V | tail -1 || true)"

  if [[ -n "$vmlinuz" && -n "$initrd" ]]; then
    cp "$vmlinuz" "$WORK/live/vmlinuz"
    cp "$initrd" "$WORK/live/initrd.img"
    log "Using kernel: $(basename "$vmlinuz")"
  else
    die "No bootable kernel/initrd in rootfs. Install linux-image in rootfs build or run build-x86_64.sh with NEXUSOS_CI_MINIMAL=0"
  fi

  log "Creating ISO with grub-mkrescue..."
  grub-mkrescue -o "${OUTPUT}/${ISO_NAME}" "$WORK" 2>/dev/null || {
    xorriso -as mkisofs -r -J -b boot/grub/i386-pc/eltorito.img \
      -no-emul-boot -boot-load-size 4 -boot-info-table \
      -o "${OUTPUT}/${ISO_NAME}" "$WORK" 2>/dev/null || \
      die "ISO creation failed — install grub-pc-bin xorriso"
  }

  log "Done: ${OUTPUT}/${ISO_NAME}"
}

main "$@"
