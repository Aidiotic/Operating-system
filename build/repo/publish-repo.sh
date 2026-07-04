#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Publish signed NexusOS APT repository for GitHub Pages (docs/repo/).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=build/repo/layout.sh
source "${ROOT}/build/repo/layout.sh"

REPO_OUT="${REPO_OUT:-${ROOT}/docs/repo}"
SUITE="${NEXUSOS_REPO_SUITE:-stable}"
DEBS="${ROOT}/releases/debs"
VERSION="$(cat "${ROOT}/VERSION")"

log() { printf '[publish-repo] %s\n' "$*"; }
die() { printf '[publish-repo] ERROR: %s\n' "$*" >&2; exit 1; }

sign_repo() {
  local repo_root="$1"
  export GNUPGHOME
  GNUPGHOME="$(mktemp -d)"
  trap 'rm -rf "$GNUPGHOME"' RETURN

  if [[ -z "${NEXUSOS_APT_GPG_PRIVATE_KEY:-}" ]]; then
    log "No NEXUSOS_APT_GPG_PRIVATE_KEY — publishing unsigned Release (dev only)"
    return 0
  fi

  echo "$NEXUSOS_APT_GPG_PRIVATE_KEY" | base64 -d | gpg --batch --import
  [[ -n "${NEXUSOS_APT_GPG_KEY_ID:-}" ]] || die "NEXUSOS_APT_GPG_KEY_ID required when signing"

  for suite_dir in "${repo_root}"/dists/*/; do
    [[ -d "$suite_dir" ]] || continue
    local suite release_file
    suite="$(basename "$suite_dir")"
    release_file="${suite_dir}Release"
    [[ -f "$release_file" ]] || continue

    log "Signing suite: $suite"
    gpg --batch --yes --local-user "$NEXUSOS_APT_GPG_KEY_ID" \
      --digest-algo SHA512 \
      -abs -o "${suite_dir}Release.gpg" "$release_file"

    gpg --batch --yes --local-user "$NEXUSOS_APT_GPG_KEY_ID" \
      --digest-algo SHA512 \
      --clearsign -o "${suite_dir}InRelease" "$release_file"

    gpg --batch --verify "${suite_dir}Release.gpg" "$release_file" \
      || die "Signature verification failed for $suite"
  done
}

main() {
  command -v dpkg-scanpackages >/dev/null 2>&1 || die "Install dpkg-dev"
  command -v apt-ftparchive >/dev/null 2>&1 || die "Install apt-utils"

  "${ROOT}/build/packages/build-debs.sh"

  rm -rf "$REPO_OUT"
  create_repo_layout "$REPO_OUT"

  log "Populating pool from ${DEBS}..."
  shopt -s nullglob
  for deb in "${DEBS}"/*.deb; do
    local base name ver arch letter
    base="$(basename "$deb")"
    name="${base%%_*}"
    ver="${base#*_}"
    ver="${ver%_*}"
    arch="${base##*_}"
    arch="${arch%.deb}"
    letter="${name:0:1}"
    mkdir -p "${REPO_OUT}/pool/main/${letter}/${name}"
    cp "$deb" "${REPO_OUT}/$(pkg_pool_path "$name" "$ver" "$arch")"
  done

  log "Generating Packages indices..."
  for arch in amd64 arm64; do
    mkdir -p "${REPO_OUT}/dists/${SUITE}/main/binary-${arch}"
    dpkg-scanpackages --arch "$arch" "${REPO_OUT}/pool" /dev/null \
      > "${REPO_OUT}/dists/${SUITE}/main/binary-${arch}/Packages"
    gzip -9c "${REPO_OUT}/dists/${SUITE}/main/binary-${arch}/Packages" \
      > "${REPO_OUT}/dists/${SUITE}/main/binary-${arch}/Packages.gz"
  done

  log "Generating Release..."
  apt-ftparchive -c "${ROOT}/build/repo/apt-ftparchive.conf" \
    release "${REPO_OUT}/dists/${SUITE}" \
    > "${REPO_OUT}/dists/${SUITE}/Release"

  sign_repo "$REPO_OUT"

  if [[ -f "${ROOT}/packages/nexus-keyring/nexusos-archive-keyring.gpg" ]]; then
    cp "${ROOT}/packages/nexus-keyring/nexusos-archive-keyring.gpg" "${REPO_OUT}/"
    cp "${ROOT}/packages/nexus-keyring/nexusos-archive-keyring.asc" "${REPO_OUT}/" 2>/dev/null || true
  fi

  log "Repository published to ${REPO_OUT}"
  log "Deploy via GitHub Pages from docs/repo/"
}

main "$@"
