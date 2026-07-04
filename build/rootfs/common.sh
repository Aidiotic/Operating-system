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

# Fast CI smoke-test profile (validates pipeline only).
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

  chroot "$chroot" env DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends "${DESKTOP_PACKAGES[@]}"

  rm -f "${chroot}/usr/sbin/policy-rc.d"
}

finalize_rootfs() {
  local chroot="$1"
  if [[ "${NEXUSOS_CI_MINIMAL:-0}" != "1" ]]; then
    chroot "$chroot" apt-get clean
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
