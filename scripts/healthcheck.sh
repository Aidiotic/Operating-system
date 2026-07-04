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

# Shell syntax
for f in install.sh scripts/*.sh build/rootfs/*.sh installer/*.sh; do
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

# Platform detect
out="$(./scripts/detect-platform.sh)"
[[ -n "$out" ]] || fail_msg "detect-platform empty"
pass "platform detect: $out"

# Version sync
ver_file="$(cat VERSION)"
grep -q "VERSION=\"${ver_file}\"" os-release || fail_msg "VERSION mismatch"
pass "version $(cat VERSION)"

# Executable bits
[[ -x install.sh ]] || fail_msg "install.sh not executable"
pass "permissions"

exit "$fail"
