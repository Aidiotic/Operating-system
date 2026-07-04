# NexusOS APT repository key lifecycle
#
# Production signing:
#   1. Run generate-dev-key.sh on a secure machine (or use org key)
#   2. Store private key base64 in GitHub Actions secret NEXUSOS_APT_GPG_PRIVATE_KEY
#   3. Store fingerprint in NEXUSOS_APT_GPG_KEY_ID
#   4. Commit only public key: packages/nexus-keyring/nexusos-archive-keyring.gpg
#
# Rotation: publish new public key in nexus-keyring package; overlap one release cycle.
# Compromise: gpg --gen-revoke, publish cert, rotate secrets immediately.
