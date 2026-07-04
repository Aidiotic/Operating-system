#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Configure NexusOS rootfs inside debootstrap chroot.

set -euo pipefail

CHROOT="${1:?Usage: chroot-setup.sh <chroot-path> <arch>}"
ARCH="${2:?Usage: chroot-setup.sh <chroot-path> <arch>}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERSION="$(cat "${ROOT}/VERSION")"

log() { printf '[chroot-setup] %s\n' "$*"; }

enable_unit() {
  local unit="$1"
  local target="${2:-multi-user.target.wants}"
  local unit_file="" search

  for search in \
    "${CHROOT}/lib/systemd/system/${unit}" \
    "${CHROOT}/usr/lib/systemd/system/${unit}"; do
    [[ -f "$search" ]] && unit_file="$search" && break
  done

  [[ -n "$unit_file" ]] || { log "Skipping missing unit: ${unit}"; return 0; }
  local rel="/${unit_file#"${CHROOT}"/}"
  mkdir -p "${CHROOT}/etc/systemd/system/${target}"
  ln -sf "$rel" "${CHROOT}/etc/systemd/system/${target}/${unit}"
}

log "Configuring NexusOS in ${CHROOT} (${ARCH})..."

cp "${ROOT}/os-release" "${CHROOT}/etc/os-release"
cp -a "${ROOT}/build/rootfs/overlays/." "${CHROOT}/" 2>/dev/null || true

mkdir -p "${CHROOT}/etc/nexusos"
if [[ "$ARCH" == "aarch64" ]]; then
  echo "asahi" > "${CHROOT}/etc/nexusos/platform"
else
  echo "generic" > "${CHROOT}/etc/nexusos/platform"
fi

cat > "${CHROOT}/etc/nexusos/release" <<EOF
VERSION=${VERSION}
CHANNEL=stable
BUILD_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

if [[ -f "${ROOT}/packages/nexus-keyring/nexusos-archive-keyring.gpg" ]]; then
  mkdir -p "${CHROOT}/usr/share/keyrings"
  cp "${ROOT}/packages/nexus-keyring/nexusos-archive-keyring.gpg" \
    "${CHROOT}/usr/share/keyrings/"
fi

if ! grep -q '^nexus:' "${CHROOT}/etc/passwd" 2>/dev/null; then
  chroot "$CHROOT" useradd -m -s /bin/bash -G sudo,adm,cdrom,dip,plugdev nexus || true
  echo 'nexus:nexus' | chroot "$CHROOT" chpasswd || true
fi

enable_unit "NetworkManager.service"
enable_unit "gdm3.service" "graphical.target.wants"
enable_unit "gdm.service" "graphical.target.wants"
enable_unit "nexus-welcome.service"

mkdir -p "${CHROOT}/var/log/nexus"
chmod 755 "${CHROOT}/var/log/nexus"

log "Chroot configuration complete."
