# NexusOS installer assets

Custom branding for the vendored Asahi installer (m1n1 boot logo).

| File | Purpose |
|------|---------|
| `nexusos.icns` | macOS icon used as m1n1 boot logo (`LOGO` in `installer/build.sh`) |
| `nexusos-logo.svg` | Source artwork (NexusOS ring + mark, `#51a2da` on `#0f0f1a`) |
| `generate-icns.sh` | Regenerate `.icns` from SVG (needs `librsvg2-bin`, `icnsutils`) |

`installer/build.sh` and `installer/patches/apply.sh` export `LOGO=<this-dir>/nexusos.icns` when present. Dual-boot / APFS logic in upstream is unchanged.

Regenerate after editing the SVG:

```bash
./installer/assets/generate-icns.sh
```
