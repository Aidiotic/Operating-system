# AGENTS.md

## Cursor Cloud specific instructions

### What this repo is
NexusOS is a **custom Debian-based Linux distribution builder** — not a web app or service. It is
almost entirely Bash (+ PowerShell for the Windows installer). There is **no dev server and no
listening ports**; "running the app" means running the validator, building a rootfs artifact, or
invoking the in-distro `nexus-*` CLI tools.

> Note: the real product lives on branch `cursor/nexusos-real-os-06aa` (PR #1). The `main` branch is
> only a placeholder `README.md`. If you see an almost-empty checkout, you are on `main` — switch to
> the product branch (or a branch based on it) to work on the actual codebase.

### System dependencies (baked into the VM snapshot)
`shellcheck`, `debootstrap`, and `xz-utils` are the build/lint toolchain. They are installed at the
system level (plus preinstalled `python3`, `make`, `git`, `curl`, `gpg`). If a fresh VM is ever
missing them: `sudo apt-get install -y shellcheck debootstrap xz-utils`. `xorriso` and
`grub-*-bin` are **not** preinstalled and are only needed for `make build-iso`.

### Lint / validate (blocking CI gate)
- `make validate` runs `./scripts/healthcheck.sh` (bash `-n` syntax, JSON validation, branding and
  version-sync checks). This is the gate CI enforces.
- Shellcheck runs across all `*.sh` (excluding `installer/upstream/`) with
  `shellcheck -e SC1091,SC2034,SC2164`. In CI it is advisory only (`|| true`); a few pre-existing
  SC2005/SC2012/SC2148 style/info notices are expected and non-blocking.

### Build (core functionality)
- Fast smoke build (what CI runs, ~20s): `sudo NEXUSOS_CI_MINIMAL=1 ./build/rootfs/build-x86_64.sh`.
  Produces `releases/nexusos-x86_64-rootfs.tar.xz` + `SHA256SUMS` — a real Debian `bookworm minbase`
  rootfs rebranded as NexusOS. `releases/` is gitignored.
- Full build (`NEXUSOS_CI_MINIMAL=0`, the default) additionally mounts a chroot and installs GNOME —
  much heavier and network-intensive; only use when you specifically need the full desktop image.
- **Rootfs/ISO builds must run as root** (`sudo`); the scripts hard-fail otherwise. `make build-*`
  targets add `sudo` automatically unless `UID=0`.
- Other targets: `make build-aarch64`, `make build-iso` (needs `xorriso` + `grub-*-bin`),
  `make build-utm`, `make build-debs`, `make clean`.

### In-distro CLI tools
`packages/*/bin/*` (`nexus-store`, `nexus-update`, `nexus-settings`, `nexus-doctor`,
`nexus-neofetch`, `nexus-welcome`) are meant to run **inside the built OS**, so on the host they
report host values / some `nexus-doctor` FAIL/WARN checks — that is expected.
Gotcha: `nexus-store` reads its catalog from the absolute path `/usr/share/nexusos/catalog.json`,
not the repo. To exercise it in the VM, copy it there first:
`sudo mkdir -p /usr/share/nexusos && sudo cp packages/nexus-store/catalog.json /usr/share/nexusos/`,
then run `nexus-store list` / `nexus-store install <pkg>`. `nexus-store` writes to
`/var/log/nexus/store.log`, so create that dir (writable) to avoid a harmless permission warning.
