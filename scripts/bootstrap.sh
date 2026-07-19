#!/usr/bin/env sh
# SPDX-License-Identifier: MIT
# curl | sh bootstrap for NexusOS.

set -e

NEXUSOS_REPO="${NEXUSOS_REPO:-Aidiotic/Operating-system}"
NEXUSOS_BRANCH="${NEXUSOS_BRANCH:-main}"

case "$NEXUSOS_REPO" in
  Aidiotic/Operating-system) ;;
  *)
    if [ "${NEXUSOS_ALLOW_FORK_REPO:-0}" = "1" ]; then
      echo "WARNING: Using non-default NEXUSOS_REPO=${NEXUSOS_REPO} (fork mode)" >&2
    else
      echo "ERROR: Unsupported NEXUSOS_REPO=${NEXUSOS_REPO}. Clone the repo and review scripts, or set NEXUSOS_ALLOW_FORK_REPO=1 for a trusted fork." >&2
      exit 1
    fi
    ;;
esac
TMP="${TMPDIR:-/tmp}/nexusos-install-$$"

cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT INT TERM

echo
echo "NexusOS Bootstrap Installer"
echo "==========================="
echo

mkdir -p "$TMP"
cd "$TMP"

echo "  Cloning repository..."
if command -v git >/dev/null 2>&1; then
  git clone --depth 1 -b "$NEXUSOS_BRANCH" \
    "https://github.com/${NEXUSOS_REPO}.git" repo
else
  curl -fsSL -o repo.tar.gz \
    "https://github.com/${NEXUSOS_REPO}/archive/refs/heads/${NEXUSOS_BRANCH}.tar.gz"
  mkdir repo
  tar xzf repo.tar.gz -C repo --strip-components=1
fi

cd repo
chmod +x install.sh scripts/*.sh 2>/dev/null || true
echo "  Starting installer..."
echo
exec ./install.sh "$@"
