#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Generate development GPG key for NexusOS APT repo signing (public key safe to commit).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
KEYRING_DIR="${ROOT}/packages/nexus-keyring"
export GNUPGHOME
GNUPGHOME="$(mktemp -d)"

cleanup() { rm -rf "$GNUPGHOME"; }
trap cleanup EXIT

mkdir -p "$KEYRING_DIR"

gpg --batch --full-generate-key <<EOF
%no-protection
Key-Type: RSA
Key-Length: 4096
Name-Real: NexusOS Archive Signing Key (Development)
Name-Email: [email protected]
Expire-Date: 2y
%commit
EOF

KEY_ID="$(gpg --list-secret-keys --with-colons | awk -F: '/^sec/{print $5; exit}')"

gpg --export --armor "$KEY_ID" > "${KEYRING_DIR}/nexusos-archive-keyring.asc"
gpg --export "$KEY_ID" > "${KEYRING_DIR}/nexusos-archive-keyring.gpg"

gpg --export-secret-keys --armor "$KEY_ID" | base64 -w0 > "${KEYRING_DIR}/private_key_b64.txt.NOT_FOR_COMMIT"

echo "Public key written to packages/nexus-keyring/"
echo "Add to GitHub Secrets:"
echo "  NEXUSOS_APT_GPG_PRIVATE_KEY=$(cat "${KEYRING_DIR}/private_key_b64.txt.NOT_FOR_COMMIT")"
echo "  NEXUSOS_APT_GPG_KEY_ID=$KEY_ID"
echo "Delete private_key_b64.txt.NOT_FOR_COMMIT before committing."
