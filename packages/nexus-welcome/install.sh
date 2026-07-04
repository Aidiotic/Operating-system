#!/usr/bin/env bash
# Install nexus-welcome systemd service inside chroot.

set -euo pipefail

SERVICE_FILE="/usr/share/nexusos/nexus-welcome/nexus-welcome.service"

if [[ ! -f "$SERVICE_FILE" ]]; then
  exit 0
fi

cp "$SERVICE_FILE" /etc/systemd/system/

if [[ -d /run/systemd/system ]]; then
  systemctl daemon-reload
  systemctl enable nexus-welcome.service
else
  mkdir -p /etc/systemd/system/multi-user.target.wants
  ln -sf /etc/systemd/system/nexus-welcome.service \
    /etc/systemd/system/multi-user.target.wants/nexus-welcome.service
fi
