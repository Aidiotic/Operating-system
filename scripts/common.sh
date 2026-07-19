#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Shared helpers for NexusOS installers.

set -euo pipefail

_nexusos_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NEXUSOS_VERSION="${NEXUSOS_VERSION:-$(cat "${_nexusos_root}/VERSION" 2>/dev/null || echo 1.0.0)}"
NEXUSOS_REPO="${NEXUSOS_REPO:-Aidiotic/Operating-system}"

# Fail closed: only allow known repo slugs unless explicitly overridden for dev forks.
_validate_nexusos_repo() {
  case "$NEXUSOS_REPO" in
    Aidiotic/Operating-system) return 0 ;;
    *)
      if [[ "${NEXUSOS_ALLOW_FORK_REPO:-0}" == "1" ]]; then
        warn "Using non-default NEXUSOS_REPO=${NEXUSOS_REPO} (fork mode)"
        return 0
      fi
      die "Unsupported NEXUSOS_REPO=${NEXUSOS_REPO}. Clone the repo and review scripts, or set NEXUSOS_ALLOW_FORK_REPO=1 for a trusted fork."
      ;;
  esac
}
_validate_nexusos_repo

NEXUSOS_GITHUB="https://github.com/${NEXUSOS_REPO}"
NEXUSOS_RELEASES="https://github.com/${NEXUSOS_REPO}/releases/download/v${NEXUSOS_VERSION}"

log() {
  printf '[nexusos] %s\n' "$*"
}

warn() {
  printf '[nexusos] WARNING: %s\n' "$*" >&2
}

die() {
  printf '[nexusos] ERROR: %s\n' "$*" >&2
  exit 1
}

need_cmd() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: $cmd"
}

repo_root() {
  local dir
  dir="$(cd "$(dirname "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")/.." && pwd)"
  echo "$dir"
}

download_release() {
  local filename="$1"
  local dest="$2"
  local url="${NEXUSOS_RELEASES}/${filename}"

  log "Downloading ${filename}..."
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL --retry 3 -o "$dest" "$url"
  elif command -v wget >/dev/null 2>&1; then
    wget -q -O "$dest" "$url"
  else
    die "curl or wget required to download release artifacts"
  fi
}

verify_checksum() {
  local file="$1"
  local sums_file="$2"

  if [[ ! -f "$sums_file" ]]; then
    die "Checksum file required but missing: $sums_file"
  fi

  local base
  base="$(basename "$file")"
  local expected
  expected="$(grep "  ${base}$" "$sums_file" | awk '{print $1}')"
  [[ -n "$expected" ]] || die "Checksum not found for ${base}"

  local actual
  if command -v sha256sum >/dev/null 2>&1; then
    actual="$(sha256sum "$file" | awk '{print $1}')"
  else
    actual="$(shasum -a 256 "$file" | awk '{print $1}')"
  fi

  [[ "$actual" == "$expected" ]] || die "Checksum mismatch for ${base}"
  log "Checksum verified: ${base}"
}
