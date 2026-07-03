#!/usr/bin/env sh
# SPDX-License-Identifier: MIT
# curl | sh bootstrap for NexusOS.

set -e

NEXUSOS_REPO="${NEXUSOS_REPO:-aidiotic/operating-system}"
NEXUSOS_BRANCH="${NEXUSOS_BRANCH:-main}"
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
