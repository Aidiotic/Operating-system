#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Quick repo health check — used by CI and `make validate`.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "NexusOS healthcheck"
echo "==================="

fail=0
pass() { echo "[OK] $*"; }
fail_msg() { echo "[FAIL] $*"; fail=1; }

# Version sync
chmod +x scripts/sync-version.sh 2>/dev/null || true
./scripts/sync-version.sh >/dev/null
pass "version sync"

# Shell syntax
for f in install.sh scripts/*.sh build/rootfs/*.sh build/kernel/*.sh build/iso/*.sh build/utm/*.sh build/packages/*.sh build/repo/*.sh installer/*.sh installer/patches/*.sh installer/assets/*.sh; do
  [[ -f "$f" ]] || continue
  bash -n "$f" || fail_msg "syntax: $f"
done
pass "shell syntax"

# JSON
python3 -m json.tool installer/nexusos-installer-data.json >/dev/null
python3 -m json.tool packages/nexus-store/catalog.json >/dev/null
pass "JSON configs"

# Branding
grep -q NexusOS os-release || fail_msg "os-release missing NexusOS"
grep -q Aidiotic/Operating-system os-release || fail_msg "os-release repo URL"
pass "os-release"

# APT keyring
[[ -f packages/nexus-keyring/nexusos-archive-keyring.gpg ]] || fail_msg "missing archive public key"
pass "archive keyring"

# APT repo layout (relative Filename paths)
[[ -f docs/repo/dists/stable/Release ]] || fail_msg "docs/repo not published"
if grep -q '^Filename: /' docs/repo/dists/stable/main/binary-amd64/Packages 2>/dev/null; then
  fail_msg "APT Packages has absolute Filename paths — run publish-repo.sh"
fi
[[ -d docs/repo/pool ]] || fail_msg "docs/repo/pool missing"
pass "APT repo layout"

# Installer assets
[[ -f installer/assets/nexusos.icns ]] || fail_msg "missing installer/assets/nexusos.icns"
pass "installer boot logo"

# Welcome service path
grep -q 'ExecStart=/usr/bin/nexus-welcome' packages/nexus-welcome/nexus-welcome.service \
  || fail_msg "nexus-welcome.service wrong ExecStart"
pass "welcome service"

# Plymouth assets
[[ -f configs/plymouth/logo.png ]] || fail_msg "missing plymouth logo.png"
pass "plymouth theme"

# Platform detect
out="$(./scripts/detect-platform.sh)"
[[ -n "$out" ]] || fail_msg "detect-platform empty"
pass "platform detect: $out"

# Version sync check
ver_file="$(cat VERSION)"
grep -q "VERSION=\"${ver_file}\"" os-release || fail_msg "VERSION mismatch"
grep -q "\"version\": \"${ver_file}\"" installer/nexusos-installer-data.json || fail_msg "installer JSON version mismatch"
pass "version $(cat VERSION)"

# Executable bits
[[ -x install.sh ]] || fail_msg "install.sh not executable"
pass "permissions"

exit "$fail"
