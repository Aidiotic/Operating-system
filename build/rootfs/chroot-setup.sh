#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Configure NexusOS rootfs inside debootstrap chroot.

set -euo pipefail

CHROOT="${1:?Usage: chroot-setup.sh <chroot-path> <arch>}"
ARCH="${2:?Usage: chroot-setup.sh <chroot-path> <arch>}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

log() { printf '[chroot-setup] %s\n' "$*"; }

enable_unit() {
  local unit="$1"
  local target="${2:-multi-user.target.wants}"
  local unit_file=""
  local search

  for search in \
    "${CHROOT}/lib/systemd/system/${unit}" \
    "${CHROOT}/usr/lib/systemd/system/${unit}"; do
    if [[ -f "$search" ]]; then
      unit_file="$search"
      break
    fi
  done

  if [[ -z "$unit_file" ]]; then
    log "Skipping missing unit: ${unit}"
    return 0
  fi

  local rel="/${unit_file#${CHROOT}/}"
  mkdir -p "${CHROOT}/etc/systemd/system/${target}"
  ln -sf "$rel" "${CHROOT}/etc/systemd/system/${target}/${unit}"
}

log "Configuring NexusOS in ${CHROOT} (${ARCH})..."

cp "${ROOT}/os-release" "${CHROOT}/etc/os-release"
cp -a "${ROOT}/build/rootfs/overlays/." "${CHROOT}/" 2>/dev/null || true

for pkg_dir in "${ROOT}"/packages/nexus-*; do
  [[ -d "$pkg_dir" ]] || continue
  pkg_name="$(basename "$pkg_dir")"
  log "Installing ${pkg_name}..."
  mkdir -p "${CHROOT}/usr/share/nexusos/${pkg_name}"
  cp -a "${pkg_dir}/." "${CHROOT}/usr/share/nexusos/${pkg_name}/"
  if [[ -f "${pkg_dir}/install.sh" ]]; then
    chroot "$CHROOT" /bin/bash "/usr/share/nexusos/${pkg_name}/install.sh" || true
  fi
  if [[ -d "${pkg_dir}/bin" ]]; then
    mkdir -p "${CHROOT}/usr/local/bin"
    for bin in "${pkg_dir}"/bin/*; do
      [[ -f "$bin" ]] || continue
      cp "$bin" "${CHROOT}/usr/local/bin/"
      chmod +x "${CHROOT}/usr/local/bin/$(basename "$bin")"
    done
  fi
done

if ! grep -q '^nexus:' "${CHROOT}/etc/passwd" 2>/dev/null; then
  chroot "$CHROOT" useradd -m -s /bin/bash -G sudo,adm,cdrom,dip,plugdev nexus || true
  echo 'nexus:nexus' | chroot "$CHROOT" chpasswd || true
fi

# Enable services via symlinks (systemctl hangs in build chroots without dbus).
enable_unit "NetworkManager.service"
enable_unit "gdm3.service" "graphical.target.wants"
enable_unit "gdm.service" "graphical.target.wants"
enable_unit "nexus-welcome.service"

mkdir -p "${CHROOT}/var/log/nexus"
chmod 755 "${CHROOT}/var/log/nexus"

log "Chroot configuration complete."
