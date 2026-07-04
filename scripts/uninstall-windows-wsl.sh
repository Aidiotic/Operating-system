#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Remove NexusOS WSL2 distro.

set -euo pipefail

DISTRO_NAME="NexusOS"
INSTALL_PATH="${NEXUSOS_WSL_PATH:-C:\\NexusOS}"

wsl_cmd="wsl"
command -v wsl.exe >/dev/null 2>&1 && wsl_cmd="wsl.exe"

if ! $wsl_cmd -l -q 2>/dev/null | grep -qx "$DISTRO_NAME"; then
  echo "Distro '${DISTRO_NAME}' is not installed."
  exit 0
fi

read -r -p "Unregister NexusOS WSL distro? [y/N] " confirm
[[ "${confirm,,}" == "y" ]] || exit 0

$wsl_cmd --unregister "$DISTRO_NAME"
echo "NexusOS removed. Delete ${INSTALL_PATH} manually if it still exists."
