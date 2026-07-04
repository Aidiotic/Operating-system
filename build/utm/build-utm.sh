#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Package NexusOS rootfs into UTM .utm bundle for macOS.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK="${ROOT}/build/utm/work"
OUTPUT="${ROOT}/releases"
UTM_NAME="nexusos-aarch64.utm"
ROOTFS="${ROOT}/releases/nexusos-aarch64-rootfs.tar.xz"
DISK_SIZE_GB="${NEXUSOS_UTM_DISK_GB:-20}"

log() { printf '[build-utm] %s\n' "$*"; }
die() { printf '[build-utm] ERROR: %s\n' "$*" >&2; exit 1; }

create_disk() {
  local disk="$1"
  if command -v qemu-img >/dev/null 2>&1; then
    qemu-img create -f qcow2 "$disk" "${DISK_SIZE_GB}G"
    log "Created ${DISK_SIZE_GB}G virtio disk: $(basename "$disk")"
    return 0
  fi
  log "WARN: qemu-img not found — bundle includes rootfs tarball only (attach disk in UTM)"
  return 1
}

main() {
  log "Building NexusOS UTM bundle..."

  if [[ ! -f "$ROOTFS" ]]; then
    log "Rootfs not found — building aarch64 rootfs first..."
    if [[ "$(id -u)" -eq 0 ]]; then
      ASAHI_KERNEL_USE_PREBUILT=1 NEXUSOS_CI_MINIMAL=0 "${ROOT}/build/rootfs/build-aarch64.sh"
    else
      die "Run: sudo ASAHI_KERNEL_USE_PREBUILT=1 NEXUSOS_CI_MINIMAL=0 ./build/rootfs/build-aarch64.sh"
    fi
  fi

  rm -rf "$WORK"
  mkdir -p "$WORK/Images" "$OUTPUT"

  local has_disk=0
  if create_disk "$WORK/Images/disk.qcow2"; then
    has_disk=1
  fi

  cat > "$WORK/config.plist" <<EOF
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
$(if [[ "$has_disk" == "1" ]]; then
cat <<'DRIVES'
    <key>Drives</key>
    <array>
        <dict>
            <key>Identifier</key>
            <string>0</string>
            <key>ImageName</key>
            <string>disk.qcow2</string>
            <key>ImageType</key>
            <string>Disk</string>
            <key>Interface</key>
            <string>VirtIO</string>
            <key>ReadOnly</key>
            <false/>
        </dict>
    </array>
DRIVES
fi)
    <key>Information</key>
    <dict>
        <key>Icon</key>
        <string>linux</string>
        <key>IconCustom</key>
        <false/>
        <key>Name</key>
        <string>NexusOS</string>
        <key>Notes</key>
        <string>NexusOS — Debian-based Linux for Apple Silicon (UTM)</string>
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
</dict>
</plist>
EOF

  cp "$ROOTFS" "$WORK/Images/nexusos-rootfs.tar.xz"

  cat > "$WORK/SETUP.md" <<'EOF'
# NexusOS UTM Setup

This bundle contains:

- `Images/nexusos-rootfs.tar.xz` — NexusOS aarch64 root filesystem
- `Images/disk.qcow2` — empty virtual disk (when built with qemu-img)

## Recommended: native dual-boot

For real Apple Silicon hardware, use native install (best GPU/WiFi support):

```bash
./install.sh --native
```

## UTM virtual machine

1. Open this `.utm` bundle in UTM
2. Boot a Debian arm64 netinst ISO to partition `disk.qcow2`
3. Extract rootfs: `sudo tar -xJf /path/to/nexusos-rootfs.tar.xz -C /mnt`
4. Install GRUB, set root UUID, reboot into NexusOS
5. Login: `nexus` / `nexus` — run `nexus-welcome`

See README: https://github.com/Aidiotic/Operating-system
EOF

  log "Creating .utm bundle..."
  rm -f "${OUTPUT}/${UTM_NAME}"
  (cd "$WORK" && zip -qr "${OUTPUT}/${UTM_NAME}.zip" .)
  mv "${OUTPUT}/${UTM_NAME}.zip" "${OUTPUT}/${UTM_NAME}"

  log "Done: ${OUTPUT}/${UTM_NAME}"
}

main "$@"
