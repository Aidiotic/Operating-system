# Redistribution Policy

NexusOS is a hobby / engineering-preview project. **This is project policy, not legal
advice.** There has been no paid legal review.

## What we publish on GitHub Releases

| Artifact | Published? |
|----------|------------|
| `nexusos-x86_64-rootfs.tar.xz` | Yes |
| `nexusos-x86_64.iso` | Yes (live boot preview) |
| `SHA256SUMS` | Yes |
| Signed APT repo (GitHub Pages) | Yes when maintainers configure a signing key |

## What we do **not** publish

Apple Silicon and firmware-dependent artifacts are **not** attached to GitHub Releases:

- `nexusos-aarch64-rootfs.tar.xz`
- `nexusos-aarch64.utm`
- `nexusos-asahi-kernel_*_arm64.deb`
- `installer-*.tar.gz` (Asahi-based macOS installer bundles)

These may still be **built locally** or in CI for development. Mac users should **git
clone** this repository and run `./install.sh` so the Asahi installer and firmware are
obtained through the upstream install flow on their machine — not via prebuilt NexusOS
redistribution.

## Mac install (source-only)

```bash
git clone --recursive https://github.com/Aidiotic/Operating-system.git
cd Operating-system
./install.sh              # Apple Silicon → native dual-boot (from clone)
./install.sh --utm        # Apple Silicon → UTM VM (built from source)
```

Intel Mac: use `./install.sh --iso` for live ISO instructions (no UTM release artifact).

## Windows install

WSL2 path uses published x86_64 rootfs from Releases or a local build.

## If you fork NexusOS

You are responsible for your own redistribution choices and compliance with third-party
licenses (GPL, Apple firmware terms via Asahi, etc.).

See also [DISCLAIMER.md](DISCLAIMER.md) and [INTENDED_USE.md](INTENDED_USE.md).
