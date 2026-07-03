#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Shared rootfs build helpers.

set -euo pipefail

# Packages installed inside chroot after debootstrap (not during).
CHROOT_BASE_PACKAGES=(
  network-manager
  sudo
  bash-completion
  ca-certificates
  apt-transport-https
  curl
  wget
  locales
)

# Desktop and apps installed via apt inside chroot.
DESKTOP_PACKAGES=(
  gnome-core
  gdm3
  firefox-esr
  gnome-terminal
  nautilus
  gnome-calculator
  gnome-text-editor
  gnome-software
  neofetch
  htop
)

# Fast CI smoke-test profile (skips heavy GNOME metapackage).
if [[ "${NEXUSOS_CI_MINIMAL:-0}" == "1" ]]; then
  DESKTOP_PACKAGES=(
    firefox-esr
    gnome-terminal
    htop
    neofetch
  )
fi

setup_chroot_mounts() {
  local chroot="$1"
  mount --bind /dev "${chroot}/dev"
  mount --bind /dev/pts "${chroot}/dev/pts"
  mount -t proc proc "${chroot}/proc"
  mount -t sysfs sys "${chroot}/sys"
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

  # Prevent service start during package configuration.
  cat > "${chroot}/usr/sbin/policy-rc.d" <<'EOF'
#!/bin/sh
exit 101
EOF
  chmod +x "${chroot}/usr/sbin/policy-rc.d"
}

install_desktop_packages() {
  local chroot="$1"

  chroot "$chroot" apt-get update
  chroot "$chroot" env DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends "${CHROOT_BASE_PACKAGES[@]}"
  chroot "$chroot" env DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends locales
  chroot "$chroot" sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
  chroot "$chroot" locale-gen

  chroot "$chroot" env DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends "${DESKTOP_PACKAGES[@]}"

  rm -f "${chroot}/usr/sbin/policy-rc.d"
}

finalize_rootfs() {
  local chroot="$1"
  chroot "$chroot" apt-get clean
  rm -rf "${chroot}/var/lib/apt/lists"/*
}

pack_rootfs() {
  local chroot="$1"
  local output="$2"
  local name="$3"

  tar -C "$chroot" -cJf "${output}/${name}" .
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "${output}/${name}" >> "${output}/SHA256SUMS"
  else
    shasum -a 256 "${output}/${name}" >> "${output}/SHA256SUMS"
  fi
}
