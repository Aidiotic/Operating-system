#!/bin/sh
# SPDX-License-Identifier: MIT
# NexusOS bootstrap for the vendored Asahi installer (macOS only).

set -e

if [ ! -e /System ]; then
    echo "NexusOS native installer requires macOS (Apple Silicon recommended)."
    exit 1
fi

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

NEXUSOS_REPO="${NEXUSOS_REPO:-Aidiotic/Operating-system}"
NEXUSOS_VERSION="${NEXUSOS_VERSION:-1.0.0}"
GITHUB="https://github.com/${NEXUSOS_REPO}"

export DISTRO="NexusOS"
export DISTRO_DOCS="${GITHUB}"
export VERSION_FLAG="${GITHUB}/releases/download/v${NEXUSOS_VERSION}/installer-latest"
export INSTALLER_BASE="${GITHUB}/releases/download/v${NEXUSOS_VERSION}"
export INSTALLER_DATA="${GITHUB}/raw/main/installer/nexusos-installer-data.json"
export INSTALLER_DATA_ALT="${INSTALLER_BASE}/nexusos-installer-data.json"
export REPO_BASE="${GITHUB}/releases/download/v${NEXUSOS_VERSION}"
export EXPERT="${EXPERT:-0}"

TMP="${NEXUSOS_INSTALLER_TMP:-/tmp/nexusos-install}"

echo
echo "NexusOS installer bootstrap"
echo "==========================="
echo

if [ -e "$TMP" ]; then
    mv "$TMP" "$TMP-$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true
fi

mkdir -p "$TMP"
cd "$TMP"

echo "  Checking installer version..."
if ! PKG_VER="$(curl --fail --silent --show-error -L "$VERSION_FLAG" 2>/dev/null)"; then
    PKG_VER="${NEXUSOS_VERSION}"
    echo "  Using release tag version: $PKG_VER"
else
    echo "  Version: $PKG_VER"
fi

PKG="installer-${PKG_VER}.tar.gz"
if [ ! -f "$PKG" ]; then
    echo "  Downloading installer..."
    curl --fail --silent --show-error -L -o "$PKG" "${INSTALLER_BASE}/${PKG}" || {
        echo "  Installer tarball not on Releases yet — use ./installer/run-installer.sh from a git clone."
        exit 1
    }
fi

echo "  Fetching installer metadata..."
if ! curl --fail --silent --show-error -L -o installer_data.json "$INSTALLER_DATA"; then
    curl --fail --silent --show-error -L -o installer_data.json "$INSTALLER_DATA_ALT"
fi

echo "  Extracting..."
tar xf "$PKG"

echo
if [ "$USER" != "root" ]; then
    echo "The installer needs root — you may be prompted for your password."
    exec caffeinate -dis sudo ./install.sh "$@"
else
    exec caffeinate -dis ./install.sh "$@"
fi
