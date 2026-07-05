# AGENTS.md

## Cursor Cloud specific instructions

### What this repo is
NexusOS is a **custom Debian-based Linux distribution builder** — not a web app or service. It is
almost entirely Bash (+ PowerShell for Windows). There is **no dev server and no listening ports**;
"running the app" means running the validator, building a rootfs artifact, or invoking the in-distro
CLI tools.

> Note: the actual product currently lives on the branch `cursor/nexusos-real-os-06aa`. The `main`
> branch is only a placeholder `README.md`. If you see an almost-empty checkout, you are on `main`.

### Pre-installed system dependencies (baked into the VM snapshot)
`shellcheck`, `debootstrap`, and `xz-utils` are installed at the system level (plus the preinstalled
`python3`, `make`, `git`, `curl`). They are not managed by any package manager in-repo, so the
startup update script does not reinstall them. If a fresh VM is ever missing them, install with
`sudo apt-get install -y shellcheck debootstrap xz-utils`.

### Lint / validate
- `make validate` runs `./scripts/healthcheck.sh` (bash `-n` syntax, JSON validation, branding and
  version-sync checks). This is the blocking CI gate.
- Shellcheck runs across all `*.sh` (excluding `installer/upstream/`) with
  `shellcheck -e SC1091,SC2034,SC2164`. In CI this is advisory only (`|| true`); a couple of
  pre-existing SC2005/SC2295 style/info notices are expected and non-blocking.

### Build (core functionality)
- Fast smoke build (what CI runs, ~20s): `sudo NEXUSOS_CI_MINIMAL=1 ./build/rootfs/build-x86_64.sh`.
  Produces `releases/nexusos-x86_64-rootfs.tar.xz` + `SHA256SUMS` (a real Debian `minbase` rootfs
  rebranded as NexusOS). `releases/` is gitignored.
- Full build (`NEXUSOS_CI_MINIMAL=0`, the default) additionally mounts a chroot and installs GNOME —
  much heavier and network-intensive; only use when you specifically need the full desktop image.
- **Rootfs/ISO builds must run as root** (`sudo`); the scripts hard-fail otherwise. `make build-*`
  targets add `sudo` automatically unless `UID=0`.
- Other targets: `make build-aarch64`, `make build-iso` (needs `xorriso`, `grub-*-bin` — not
  preinstalled), `make build-utm`, `make clean`.

### In-distro CLI tools
`packages/*/bin/*` (`nexus-store`, `nexus-update`, `nexus-settings`, `nexus-doctor`,
`nexus-welcome`) are meant to run inside the built OS. Gotcha: `nexus-store` reads its catalog from
the absolute path `/usr/share/nexusos/nexus-store/catalog.json`, not the repo. To exercise it in the
VM, copy `packages/nexus-store/catalog.json` there first, then run `nexus-store list`.
