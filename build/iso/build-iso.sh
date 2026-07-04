#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Build bootable x86_64 ISO for dual-boot installation.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK="${ROOT}/build/iso/work"
OUTPUT="${ROOT}/releases"
ISO_NAME="nexusos-x86_64.iso"
ROOTFS="${ROOT}/releases/nexusos-x86_64-rootfs.tar.xz"
FS="${WORK}/live/filesystem"

log() { printf '[build-iso] %s\n' "$*"; }
die() { printf '[build-iso] ERROR: %s\n' "$*" >&2; exit 1; }

[[ "$(id -u)" -eq 0 ]] || die "Run as root: sudo $0"
command -v xorriso >/dev/null 2>&1 || die "Install xorriso: apt install xorriso"
command -v grub-mkrescue >/dev/null 2>&1 || die "Install grub: apt install grub-pc-bin grub-efi-amd64-bin"

extract_kernel() {
  local vmlinuz initrd
  vmlinuz="$(find "$FS/boot" -maxdepth 1 -name 'vmlinuz-*' 2>/dev/null | sort -V | tail -1)"
  initrd="$(find "$FS/boot" -maxdepth 1 -name 'initrd.img-*' 2>/dev/null | sort -V | tail -1)"

  [[ -n "$vmlinuz" && -f "$vmlinuz" ]] || die "No kernel in rootfs. Build full x86_64 rootfs first: sudo NEXUSOS_CI_MINIMAL=0 ./build/rootfs/build-x86_64.sh"
  [[ -n "$initrd" && -f "$initrd" ]] || die "No initrd in rootfs. Ensure initramfs-tools is installed in rootfs."

  cp "$vmlinuz" "$WORK/live/vmlinuz"
  cp "$initrd" "$WORK/live/initrd.img"
  log "Using kernel: $(basename "$vmlinuz")"
}

main() {
  log "Building NexusOS ISO..."

  if [[ ! -f "$ROOTFS" ]]; then
    log "Rootfs not found — building full x86_64 rootfs first..."
    NEXUSOS_CI_MINIMAL=0 "${ROOT}/build/rootfs/build-x86_64.sh"
  fi

  rm -rf "$WORK"
  mkdir -p "$WORK"/{iso,live,boot/grub}
  mkdir -p "$OUTPUT" "$FS"

  log "Extracting rootfs for live boot..."
  tar -xJf "$ROOTFS" -C "$FS"
  extract_kernel

  cat > "$WORK/boot/grub/grub.cfg" <<'EOF'
set timeout=10
set default=0

menuentry "NexusOS Live (try without installing)" {
    linux /live/vmlinuz boot=live quiet splash
    initrd /live/initrd.img
}

menuentry "Install NexusOS (dual-boot)" {
    linux /live/vmlinuz boot=live quiet splash nexusos.install
    initrd /live/initrd.img
}
EOF

  if [[ -f "${ROOT}/configs/grub/theme.txt" ]]; then
    mkdir -p "$WORK/boot/grub/themes/nexusos"
    cp "${ROOT}/configs/grub/theme.txt" "$WORK/boot/grub/themes/nexusos/"
    echo 'set theme=(hd0,msdos1)/boot/grub/themes/nexusos/theme.txt' >> "$WORK/boot/grub/grub.cfg"
  fi

  log "Creating ISO with grub-mkrescue..."
  if ! grub-mkrescue -o "${OUTPUT}/${ISO_NAME}" "$WORK" 2>/dev/null; then
    xorriso -as mkisofs -r -J -b boot/grub/i386-pc/eltorito.img \
      -no-emul-boot -boot-load-size 4 -boot-info-table \
      -o "${OUTPUT}/${ISO_NAME}" "$WORK" || die "ISO creation failed"
  fi

  log "Done: ${OUTPUT}/${ISO_NAME}"
}

main "$@"
