#!/usr/bin/env bash
# Install nexus-welcome systemd service inside chroot.

set -euo pipefail

if [[ -f /usr/share/nexusos/nexus-welcome/nexus-welcome.service ]]; then
  cp /usr/share/nexusos/nexus-welcome/nexus-welcome.service /etc/systemd/system/
  systemctl daemon-reload
  systemctl enable nexus-welcome.service
fi
