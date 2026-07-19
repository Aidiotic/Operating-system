#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Package NexusOS rootfs into UTM .utm bundle for macOS.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK="${ROOT}/build/utm/work"
OUTPUT="${ROOT}/releases"
UTM_NAME="nexusos-aarch64.utm"
ROOTFS="${ROOT}/releases/nexusos-aarch64-rootfs.tar.xz"

log() { printf '[build-utm] %s\n' "$*"; }
die() { printf '[build-utm] ERROR: %s\n' "$*" >&2; exit 1; }

main() {
  log "Building NexusOS UTM bundle..."

  if [[ ! -f "$ROOTFS" ]]; then
    log "Rootfs not found — building aarch64 rootfs first..."
    if [[ "$(id -u)" -eq 0 ]]; then
      "${ROOT}/build/rootfs/build-aarch64.sh"
    else
      die "Run build-aarch64.sh as root first, or run this script as root."
    fi
  fi

  rm -rf "$WORK"
  mkdir -p "$WORK/Images" "$OUTPUT"

  # UTM bundle structure (Apple Virtualization Framework)
  cat > "$WORK/config.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>ConfigurationVersion</key>
    <integer>4</integer>
    <key>Debug</key>
    <dict>
        <key>DebugLog</key>
        <false/>
    </dict>
    <key>Display</key>
    <array>
        <dict>
            <key>DynamicResolution</key>
            <true/>
            <key>Hardware</key>
            <string>virtio-gpu-pci</string>
            <key>HeightPixels</key>
            <integer>900</integer>
            <key>WidthPixels</key>
            <integer>1440</integer>
        </dict>
    </array>
    <key>Information</key>
    <dict>
        <key>Icon</key>
        <string>linux</string>
        <key>IconCustom</key>
        <false/>
        <key>Name</key>
        <string>NexusOS</string>
        <key>Notes</key>
        <string>NexusOS — custom Linux for Mac and Windows</string>
        <key>UUID</key>
        <string>NEXUSOS-UTM-0001-0000-0000-000000000001</string>
    </dict>
    <key>Network</key>
    <array>
        <dict>
            <key>Hardware</key>
            <string>virtio-net-pci</string>
            <key>Mode</key>
            <string>Shared</string>
        </dict>
    </array>
    <key>Platform</key>
    <string>Apple</string>
    <key>System</key>
    <dict>
        <key>Architecture</key>
        <string>aarch64</string>
        <key>CPUCount</key>
        <integer>4</integer>
        <key>MemorySize</key>
        <integer>4294967296</integer>
        <key>Target</key>
        <string>virt</string>
    </dict>
    <key>Drives</key>
    <array>
        <dict>
            <key>ImageName</key>
            <string>disk.img</string>
            <key>ImageType</key>
            <string>Disk</string>
            <key>Interface</key>
            <string>VirtIO</string>
            <key>ReadOnly</key>
            <false/>
        </dict>
    </array>
</dict>
</plist>
EOF

  cp "$ROOTFS" "$WORK/Images/nexusos-rootfs.tar.xz"

  log "Creating virtual disk image..."
  if command -v qemu-img >/dev/null 2>&1; then
    qemu-img create -f qcow2 "$WORK/Images/disk.img" 16G
  else
    truncate -s 16G "$WORK/Images/disk.img"
  fi

  cat > "$WORK/README.txt" <<'EOF'
NexusOS UTM Virtual Machine
============================

NexusOS is provided AS IS without warranty. Independent project — not
affiliated with UTM or Apple. See /usr/share/nexusos/DISCLAIMER.md in the VM.

1. Open this .utm bundle in UTM (double-click)
2. First boot extracts rootfs — may take a few minutes
3. Login: nexus (password expires on first login — run nexus-welcome)
4. Run: nexus-welcome

For native Apple Silicon dual-boot, use:
  ./install.sh --native
EOF

  log "Creating .utm bundle..."
  rm -f "${OUTPUT}/${UTM_NAME}"
  (cd "$WORK" && zip -r "${OUTPUT}/${UTM_NAME}.zip" .)
  mv "${OUTPUT}/${UTM_NAME}.zip" "${OUTPUT}/${UTM_NAME}"

  log "Done: ${OUTPUT}/${UTM_NAME}"
}

main "$@"
