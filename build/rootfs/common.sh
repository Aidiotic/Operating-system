#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Shared rootfs build helpers.

set -euo pipefail

ROOT_COMMON="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

CHROOT_BASE_PACKAGES=(
  network-manager
  sudo
  bash-completion
  ca-certificates
  apt-transport-https
  curl
  wget
  locales
  gnupg
)

# Curated desktop — no gnome-core metapackage, no gnome-software.
DESKTOP_PACKAGES=(
  gdm3
  gnome-session
  gnome-shell
  gnome-control-center
  gnome-terminal
  nautilus
  gnome-calculator
  firefox-esr
  neofetch
  htop
  plymouth
  plymouth-label
)

if [[ "${NEXUSOS_CI_MINIMAL:-0}" == "1" ]]; then
  DESKTOP_PACKAGES=()
fi

setup_chroot_mounts() {
  local chroot="$1"
  mount --bind /dev "${chroot}/dev"
  mount --bind /dev/pts "${chroot}/dev/pts"
  mount -t proc proc "${chroot}/proc"
  mount -t sysfs sys "${chroot}/sys"
  cp /etc/resolv.conf "${chroot}/etc/resolv.conf" 2>/dev/null || true
}

teardown_chroot_mounts() {
  local chroot="$1"
  umount -R "${chroot}" 2>/dev/null || true
}

prepare_chroot_apt() {
  local chroot="$1"

  cat >> "${chroot}/etc/apt/sources.list" <<'EOF'
deb http://deb.debian.org/debian bookworm-updates main
deb http://security.debian.org/debian-security bookworm-security main
EOF

  if [[ -f "${ROOT_COMMON}/build/rootfs/overlays/etc/apt/sources.list.d/nexusos.list" ]]; then
    mkdir -p "${chroot}/etc/apt/sources.list.d"
    cp "${ROOT_COMMON}/build/rootfs/overlays/etc/apt/sources.list.d/nexusos.list" \
      "${chroot}/etc/apt/sources.list.d/nexusos.list"
  fi

  cat > "${chroot}/usr/sbin/policy-rc.d" <<'EOF'
#!/bin/sh
exit 101
EOF
  chmod +x "${chroot}/usr/sbin/policy-rc.d"
}

install_desktop_packages() {
  local chroot="$1"

  chroot "$chroot" apt-get update

  if [[ "${NEXUSOS_CI_MINIMAL:-0}" == "1" ]]; then
    chroot "$chroot" env DEBIAN_FRONTEND=noninteractive \
      apt-get install -y --no-install-recommends htop neofetch
    rm -f "${chroot}/usr/sbin/policy-rc.d"
    return 0
  fi

  chroot "$chroot" env DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends "${CHROOT_BASE_PACKAGES[@]}"
  chroot "$chroot" env DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends locales
  chroot "$chroot" sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
  chroot "$chroot" locale-gen

  if [[ ${#DESKTOP_PACKAGES[@]} -gt 0 ]]; then
    chroot "$chroot" env DEBIAN_FRONTEND=noninteractive \
      apt-get install -y --no-install-recommends "${DESKTOP_PACKAGES[@]}"
  fi

  rm -f "${chroot}/usr/sbin/policy-rc.d"
}

install_nexus_debs() {
  local chroot="$1"
  local deb_dir="${ROOT_COMMON}/releases/debs"

  [[ -d "$deb_dir" ]] || return 0
  mkdir -p "${chroot}/tmp/nexus-debs"
  cp "${deb_dir}"/*.deb "${chroot}/tmp/nexus-debs/" 2>/dev/null || return 0

  chroot "$chroot" bash -c 'dpkg -i /tmp/nexus-debs/*.deb 2>/dev/null || true; apt-get install -f -y'
  rm -rf "${chroot}/tmp/nexus-debs"
}

apply_theme_and_branding() {
  local chroot="$1"
  local root="${ROOT_COMMON}"

  if [[ -d "${root}/configs/plymouth" ]]; then
    mkdir -p "${chroot}/usr/share/plymouth/themes/nexusos"
    cp -a "${root}/configs/plymouth/." "${chroot}/usr/share/plymouth/themes/nexusos/"
    echo "nexusos" > "${chroot}/etc/plymouth/plymouthd.conf" 2>/dev/null || \
      mkdir -p "${chroot}/etc/plymouth" && echo -e "[Daemon]\nTheme=nexusos" > "${chroot}/etc/plymouth/plymouthd.conf"
  fi

  if [[ -d "${root}/configs/grub" ]]; then
    mkdir -p "${chroot}/boot/grub/themes/nexusos"
    cp -a "${root}/configs/grub/." "${chroot}/boot/grub/themes/nexusos/" 2>/dev/null || true
  fi

  if [[ -f "${root}/configs/gdm/01-nexusos-defaults" ]]; then
    mkdir -p "${chroot}/etc/dconf/db/local.d"
    cp "${root}/configs/gdm/01-nexusos-defaults" "${chroot}/etc/dconf/db/local.d/"
  fi
}

finalize_rootfs() {
  local chroot="$1"
  if [[ "${NEXUSOS_CI_MINIMAL:-0}" != "1" ]]; then
    chroot "$chroot" apt-get clean 2>/dev/null || true
  fi
  rm -rf "${chroot}/var/lib/apt/lists"/*
}

pack_rootfs() {
  local chroot="$1"
  local output="$2"
  local name="$3"
  local archive="${output}/${name}"
  local sums="${output}/SHA256SUMS"

  mkdir -p "$output"
  rm -f "$archive"

  if [[ "${NEXUSOS_CI_MINIMAL:-0}" == "1" ]]; then
    tar -C "$chroot" -cf - . | xz -1 -T0 > "$archive"
  else
    tar -C "$chroot" -cJf "$archive" .
  fi

  local hash
  if command -v sha256sum >/dev/null 2>&1; then
    hash="$(sha256sum "$archive" | awk '{print $1}')"
  else
    hash="$(shasum -a 256 "$archive" | awk '{print $1}')"
  fi

  touch "$sums"
  grep -v "  ${name}$" "$sums" > "${sums}.tmp" 2>/dev/null || true
  echo "${hash}  ${name}" >> "${sums}.tmp"
  mv "${sums}.tmp" "$sums"
}
