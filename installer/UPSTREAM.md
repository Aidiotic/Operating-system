# Vendored Asahi installer

NexusOS ships a **downstream** build of [AsahiLinux/asahi-installer](https://github.com/AsahiLinux/asahi-installer) per [Asahi downstream policy](https://asahilinux.org/docs/alt/policy/).

| Item | Value |
|------|-------|
| Submodule path | `installer/upstream` |
| Pinned release | `v0.8.3` (`c53d66d`) |
| Branding | `DISTRO=NexusOS`, `installer/assets/nexusos.icns`, `nexusos-installer-data.json` |
| Unchanged | APFS resize, recoveryOS, m1n1 boot chain |

## Update upstream

```bash
cd installer/upstream
git fetch --tags
git checkout v0.8.4   # example: new upstream tag
cd ../..
git add installer/upstream
git commit -m "Bump asahi-installer to v0.8.4"
```

Re-apply branding is automatic via `installer/patches/apply.sh` and `installer/build.sh`.

## Build

- **macOS (full):** `./installer/build.sh` — produces m1n1 + installer tarball for Releases
- **Linux CI (stub):** metadata-only bundle for release pipeline smoke tests
- **Dev:** `./installer/run-installer.sh --from-source` on macOS
