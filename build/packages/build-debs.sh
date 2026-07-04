#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Build all NexusOS .deb packages into releases/debs/

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PKG_VERSION="$(cat "${ROOT}/VERSION")-1"
OUT="${ROOT}/releases/debs"
STAGE="${ROOT}/build/packages/stage"
ARCH="${NEXUSOS_DEB_ARCH:-all}"

log() { printf '[build-debs] %s\n' "$*"; }

pkg_pool_path() {
  local name="$1" ver="$2" arch="$3"
  local letter="${name:0:1}"
  echo "pool/main/${letter}/${name}/${name}_${ver}_${arch}.deb"
}

write_control() {
  local dir="$1" pkg="$2" depends="${3:-}" arch="${4:-all}"
  mkdir -p "${dir}/DEBIAN"
  cat > "${dir}/DEBIAN/control" <<EOF
Package: ${pkg}
Version: ${PKG_VERSION}
Section: misc
Priority: optional
Architecture: ${arch}
Maintainer: NexusOS <[email protected]>
Description: NexusOS ${pkg}
${depends:+Depends: ${depends}}
EOF
}

build_deb() {
  local pkg="$1" depends="${2:-}"
  local dir="${STAGE}/${pkg}"
  rm -rf "$dir"
  mkdir -p "$dir"
  write_control "$dir" "$pkg" "$depends" "$ARCH"

  case "$pkg" in
    nexus-keyring)
      mkdir -p "${dir}/usr/share/keyrings"
      if [[ -f "${ROOT}/packages/nexus-keyring/nexusos-archive-keyring.gpg" ]]; then
        cp "${ROOT}/packages/nexus-keyring/nexusos-archive-keyring.gpg" \
          "${dir}/usr/share/keyrings/"
      else
        touch "${dir}/usr/share/keyrings/nexusos-archive-keyring.gpg"
        log "WARN: no signing public key — run build/repo/generate-dev-key.sh"
      fi
      ;;
    nexus-store)
      install -Dm755 "${ROOT}/packages/nexus-store/bin/nexus-store" "${dir}/usr/bin/nexus-store"
      install -Dm644 "${ROOT}/packages/nexus-store/catalog.json" "${dir}/usr/share/nexusos/catalog.json"
      install -Dm644 "${ROOT}/packages/nexus-store/nexus-store.desktop" "${dir}/usr/share/applications/nexus-store.desktop"
      ;;
    nexus-settings)
      install -Dm755 "${ROOT}/packages/nexus-settings/bin/nexus-update" "${dir}/usr/bin/nexus-update"
      install -Dm755 "${ROOT}/packages/nexus-settings/bin/nexus-settings" "${dir}/usr/bin/nexus-settings"
      install -Dm755 "${ROOT}/packages/nexus-settings/bin/nexus-doctor" "${dir}/usr/bin/nexus-doctor"
      install -Dm755 "${ROOT}/packages/nexus-settings/bin/nexus-neofetch" "${dir}/usr/bin/nexus-neofetch"
      install -Dm755 "${ROOT}/build/packages/nexus-pkg" "${dir}/usr/bin/nexus-pkg"
      ;;
    nexus-welcome)
      install -Dm755 "${ROOT}/packages/nexus-welcome/bin/nexus-welcome" "${dir}/usr/bin/nexus-welcome"
      install -Dm644 "${ROOT}/packages/nexus-welcome/nexus-welcome.service" "${dir}/lib/systemd/system/nexus-welcome.service"
      cat > "${dir}/DEBIAN/postinst" <<'EOF'
#!/bin/sh
systemctl daemon-reload 2>/dev/null || true
ln -sf /lib/systemd/system/nexus-welcome.service /etc/systemd/system/multi-user.target.wants/nexus-welcome.service 2>/dev/null || true
EOF
      chmod 755 "${dir}/DEBIAN/postinst"
      ;;
    nexus-theme)
      mkdir -p "${dir}/usr/share/nexusos/theme" "${dir}/usr/share/backgrounds/nexusos"
      if [[ -f "${ROOT}/packages/nexus-theme/wallpaper.svg" ]]; then
        cp "${ROOT}/packages/nexus-theme/wallpaper.svg" "${dir}/usr/share/backgrounds/nexusos/default.svg"
      fi
      if [[ -f "${ROOT}/packages/nexus-theme/gtk.css" ]]; then
        cp "${ROOT}/packages/nexus-theme/gtk.css" "${dir}/usr/share/nexusos/theme/gtk.css"
      fi
      ;;
    nexus-meta)
      : # metapackage only
      ;;
  esac

  mkdir -p "$OUT"
  dpkg-deb --build "$dir" "${OUT}/${pkg}_${PKG_VERSION}_${ARCH}.deb"
  log "Built ${pkg}_${PKG_VERSION}_${ARCH}.deb"
}

main() {
  rm -rf "$STAGE"
  mkdir -p "$OUT"

  build_deb nexus-keyring
  build_deb nexus-store
  build_deb nexus-settings
  build_deb nexus-welcome
  build_deb nexus-theme
  build_deb nexus-meta "nexus-keyring, nexus-store, nexus-settings, nexus-welcome, nexus-theme"

  log "Done: ${OUT}/"
}

main "$@"
