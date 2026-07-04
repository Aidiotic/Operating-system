# NexusOS installer assets

Place a macOS `.icns` logo here as `nexusos.icns` for the branded m1n1 boot screen.

`installer/build.sh` exports `LOGO=<this-dir>/nexusos.icns` when the file exists. If absent, the upstream Asahi artwork submodule logo is used (dual-boot logic unchanged).

Do **not** modify `installer/upstream/` directly — branding is applied via environment variables and optional `LOGO` at build time per [Asahi downstream policy](https://asahilinux.org/docs/alt/policy/).
