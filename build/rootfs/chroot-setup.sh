#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Configure NexusOS rootfs inside debootstrap chroot.

set -euo pipefail

CHROOT="${1:?Usage: chroot-setup.sh <chroot-path> <arch>}"
ARCH="${2:?Usage: chroot-setup.sh <chroot-path> <arch>}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

log() { printf '[chroot-setup] %s\n' "$*"; }

log "Configuring NexusOS in ${CHROOT} (${ARCH})..."

# Copy os-release and overlays
cp "${ROOT}/os-release" "${CHROOT}/etc/os-release"
cp -a "${ROOT}/build/rootfs/overlays/." "${CHROOT}/" 2>/dev/null || true

# Install NexusOS custom packages
for pkg_dir in "${ROOT}"/packages/nexus-*; do
  [[ -d "$pkg_dir" ]] || continue
  pkg_name="$(basename "$pkg_dir")"
  log "Installing ${pkg_name}..."
  mkdir -p "${CHROOT}/usr/share/nexusos/${pkg_name}"
  cp -a "${pkg_dir}/." "${CHROOT}/usr/share/nexusos/${pkg_name}/"
  if [[ -f "${pkg_dir}/install.sh" ]]; then
    chroot "$CHROOT" /bin/bash "/usr/share/nexusos/${pkg_name}/install.sh" || true
  fi
  # Link binaries
  if [[ -d "${pkg_dir}/bin" ]]; then
    mkdir -p "${CHROOT}/usr/local/bin"
    for bin in "${pkg_dir}"/bin/*; do
      [[ -f "$bin" ]] || continue
      cp "$bin" "${CHROOT}/usr/local/bin/"
      chmod +x "${CHROOT}/usr/local/bin/$(basename "$bin")"
    done
  fi
done

# Create nexus user
if ! grep -q '^nexus:' "${CHROOT}/etc/passwd" 2>/dev/null; then
  chroot "$CHROOT" useradd -m -s /bin/bash -G sudo,adm,cdrom,dip,plugdev nexus || true
  echo 'nexus:nexus' | chroot "$CHROOT" chpasswd || true
fi

# Enable services
chroot "$CHROOT" systemctl enable NetworkManager 2>/dev/null || true
chroot "$CHROOT" systemctl enable gdm3 2>/dev/null || true
chroot "$CHROOT" systemctl enable nexus-welcome.service 2>/dev/null || true

# Log directory
mkdir -p "${CHROOT}/var/log/nexus"
chmod 755 "${CHROOT}/var/log/nexus"

log "Chroot configuration complete."
