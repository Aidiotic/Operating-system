#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Apple Silicon (aarch64) specific rootfs helpers.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

install_asahi_kernel_deb() {
  local chroot="$1"
  local version
  version="$(cat "${ROOT}/VERSION")"
  local deb="${ROOT}/releases/nexusos-asahi-kernel_${version}_arm64.deb"

  if [[ ! -f "$deb" ]]; then
    if [[ "${ASAHI_KERNEL_USE_PREBUILT:-0}" == "1" ]]; then
      "${ROOT}/build/kernel/fetch-asahi-platform.sh" --kernel-only
    else
      printf '[common-asahi] WARN: kernel deb missing — run build/kernel/build-asahi-kernel.sh\n' >&2
      return 0
    fi
  fi

  [[ -f "$deb" ]] || return 0
  cp "$deb" "${chroot}/tmp/nexus-kernel.deb"
  chroot "$chroot" env DEBIAN_FRONTEND=noninteractive \
    dpkg -i /tmp/nexus-kernel.deb || true
  chroot "$chroot" apt-get install -f -y || true
  rm -f "${chroot}/tmp/nexus-kernel.deb"
}

install_asahi_platform() {
  local chroot="$1"
  if [[ "${NEXUSOS_CI_MINIMAL:-0}" == "1" ]]; then
    return 0
  fi
  # shellcheck source=build/kernel/versions.env
  source "${ROOT}/build/kernel/versions.env" 2>/dev/null || true
  "${ROOT}/build/kernel/fetch-asahi-platform.sh" "$chroot" || \
    printf '[common-asahi] WARN: Asahi platform packages unavailable in this environment\n' >&2
}

apply_asahi_overlays() {
  local chroot="$1"
  mkdir -p "${chroot}/etc/nexusos"
  echo "asahi" > "${chroot}/etc/nexusos/platform"
  mkdir -p "${chroot}/etc/kernel"
  if [[ -f "${ROOT}/build/rootfs/overlays/etc/kernel/cmdline" ]]; then
    cp "${ROOT}/build/rootfs/overlays/etc/kernel/cmdline" "${chroot}/etc/kernel/cmdline"
  elif [[ ! -f "${chroot}/etc/kernel/cmdline" ]]; then
    echo 'root=UUID=auto rw quiet splash loglevel=3' > "${chroot}/etc/kernel/cmdline"
  fi
}
