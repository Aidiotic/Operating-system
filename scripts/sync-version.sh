#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Sync VERSION across os-release, installer metadata, and overlay files.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(cat "${ROOT}/VERSION")"
VERSION_ID="${VERSION%.*}"
REPO="${NEXUSOS_REPO:-Aidiotic/Operating-system}"
GITHUB="https://github.com/${REPO}"
RELEASE_URL="${GITHUB}/releases/download/v${VERSION}"

log() { printf '[sync-version] %s\n' "$*"; }

# os-release
cat > "${ROOT}/os-release" <<EOF
NAME="NexusOS"
VERSION="${VERSION}"
ID=nexusos
VERSION_ID="${VERSION_ID}"
VERSION_CODENAME=nexus
PRETTY_NAME="NexusOS ${VERSION_ID}"
NEXUSOS_CHANNEL=stable
BUILD_ID=nexus-${VERSION}
HOME_URL="${GITHUB}"
SUPPORT_URL="${GITHUB}/issues"
BUG_REPORT_URL="${GITHUB}/issues"
LOGO=nexusos
EOF

# installer metadata
python3 - <<PY
import json
from pathlib import Path

version = "${VERSION}"
release = "${RELEASE_URL}"
github = "${GITHUB}"

data = {
    "distro": "NexusOS",
    "version": version,
    "platform": "asahi",
    "repo_base": release,
    "apt_repo": "https://aidiotic.github.io/Operating-system/repo stable main",
    "kernel_package": f"nexusos-asahi-kernel_{version}_arm64.deb",
    "firmware": "asahi",
    "firmware_packages": ["asahi-audio", "asahi-wifi", "asahi-ble", "mesa-asahi"],
    "images": {
        "aarch64": {
            "filename": "nexusos-aarch64-rootfs.tar.xz",
            "description": "NexusOS for Apple Silicon Macs",
            "kernel": "asahi",
            "kernel_package": f"nexusos-asahi-kernel_{version}_arm64.deb",
            "kernel_package_url": f"{release}/nexusos-asahi-kernel_{version}_arm64.deb",
            "firmware": "asahi",
            "firmware_packages": ["asahi-audio", "asahi-wifi", "asahi-ble", "mesa-asahi"],
            "initramfs": True,
        },
        "x86_64": {
            "filename": "nexusos-x86_64-rootfs.tar.xz",
            "description": "NexusOS for x86_64 (WSL2 / dual-boot)",
            "kernel": "generic",
            "initramfs": True,
        },
    },
    "partitions": {"efi_mb": 512, "boot_mb": 1024, "min_root_gb": 20},
    "branding": {
        "name": "NexusOS",
        "logo": "nexusos",
        "support_url": f"{github}/issues",
    },
}

path = Path("${ROOT}/installer/nexusos-installer-data.json")
path.write_text(json.dumps(data, indent=2) + "\n")
PY

# static overlay template (chroot-setup overwrites BUILD_DATE at image build)
cat > "${ROOT}/build/rootfs/overlays/etc/nexusos/release" <<EOF
VERSION=${VERSION}
CHANNEL=stable
BUILD_DATE=template
EOF

log "Synced version ${VERSION} → os-release, installer/nexusos-installer-data.json"
