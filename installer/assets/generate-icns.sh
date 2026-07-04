#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Generate installer/assets/nexusos.icns from nexusos-logo.svg (macOS m1n1 boot logo).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SVG="${ROOT}/nexusos-logo.svg"
OUT="${ROOT}/nexusos.icns"
WORK="$(mktemp -d)"

cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

command -v rsvg-convert >/dev/null 2>&1 || { echo "Install librsvg2-bin"; exit 1; }
command -v png2icns >/dev/null 2>&1 || { echo "Install icnsutils (png2icns)"; exit 1; }

for size in 16 32 48 128 256 512; do
  rsvg-convert -w "$size" -h "$size" "$SVG" -o "${WORK}/nexusos_${size}.png"
done

png2icns "$OUT" \
  "${WORK}/nexusos_16.png" \
  "${WORK}/nexusos_32.png" \
  "${WORK}/nexusos_48.png" \
  "${WORK}/nexusos_128.png" \
  "${WORK}/nexusos_256.png" \
  "${WORK}/nexusos_512.png"

echo "Generated ${OUT}"
