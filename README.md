# NexusOS

> **Preview release (v1.0.0):** Engineering preview — not legal clearance for redistribution of release binaries. See [Disclaimer](docs/DISCLAIMER.md), [Trademarks](docs/TRADEMARKS.md), and [Third-Party Notices](THIRD_PARTY_NOTICES.md).

A custom Linux distribution for **Mac** and **Windows**. Clone the repo and run the installer — inspired by the [Asahi Linux](https://asahilinux.org) install experience. **NexusOS is an independent project, not affiliated with or endorsed by Asahi Linux, Apple, or Microsoft.**

## Quick Install

### One-liner (convenience only)

No integrity verification — review `scripts/bootstrap.sh` before running:

```bash
curl -fsSL https://raw.githubusercontent.com/Aidiotic/Operating-system/main/scripts/bootstrap.sh | sh
```

### Git clone (recommended)

```bash
git clone https://github.com/Aidiotic/Operating-system.git
cd Operating-system
./install.sh
```

The installer auto-detects your platform and picks the right install method.

## Platform Support

| Platform | Method | Command |
|----------|--------|---------|
| **Mac Apple Silicon** | Git clone + native dual-boot (Asahi) | `git clone --recursive … && ./install.sh --native` |
| **Mac Apple Silicon** | Git clone + UTM VM (build locally) | `./install.sh --utm` |
| **Mac Intel** | Live ISO (preview) | `./install.sh --iso` |
| **Windows 10/11** | WSL2 distro | `./install.sh` or `./install.sh --wsl` |
| **Windows / Linux PC** | Live ISO (preview) | `./install.sh --iso` |

> **Mac users:** Apple Silicon installers run from a **git clone** only — aarch64 release
> binaries are not published. See [Redistribution Policy](docs/REDISTRIBUTION_POLICY.md).

## What's Included

- **GNOME desktop** with Wayland
- **Firefox** web browser
- **nexus-store** — software center (install apps from catalog or `apt`)
- **nexus-update** — system updates
- **nexus-settings** — system info, disk cleanup, factory reset
- **nexus-doctor** — diagnostics
- **nexus-welcome** — first-boot setup wizard
- **Terminal**, Files (Nautilus), Calculator, Text Editor

Default user: `nexus` — password expires on first login; `nexus-welcome` prompts you to set a new password.

## Install Details

### Mac Apple Silicon (native dual-boot)

Requires macOS 13.5+. **Back up with Time Machine first.** **Git clone required** (release
binaries for Mac are not published).

```bash
git clone --recursive https://github.com/Aidiotic/Operating-system.git
cd Operating-system
./install.sh --native
```

This uses the [Asahi Linux installer](https://github.com/AsahiLinux/asahi-installer) boot chain (m1n1 → U-Boot → NexusOS kernel) to dual-boot alongside macOS. Firmware is obtained through the upstream install flow on your Mac — not via prebuilt NexusOS downloads.

### Mac UTM (Apple Silicon virtual machine)

No repartitioning required. **Builds the VM bundle from your clone** (not from Releases).

```bash
git clone --recursive https://github.com/Aidiotic/Operating-system.git
cd Operating-system
./install.sh --utm
```

Requires [UTM](https://mac.getutm.app) (installed automatically via Homebrew if available).

### Mac Intel

UTM release artifacts are not published for Intel Macs. Use the **live ISO** path:

```bash
./install.sh --iso
```

### Windows WSL2

Run in **PowerShell** (not inside WSL):

```powershell
git clone https://github.com/Aidiotic/Operating-system.git
cd Operating-system
.\install.ps1
```

Or one-liner (convenience only — no integrity verification; review `install.ps1` first):

```powershell
irm https://raw.githubusercontent.com/Aidiotic/Operating-system/main/install.ps1 | iex
```

Then launch:

```powershell
wsl -d NexusOS
```

GUI apps work via WSLg on Windows 11.

### Dual-boot ISO (preview)

**Engineering preview:** live boot only; automated dual-boot installation is not available in v1.0.0.

Download `nexusos-x86_64.iso` from [GitHub Releases](https://github.com/Aidiotic/Operating-system/releases) or build locally:

```bash
sudo ./build/iso/build-iso.sh
```

## Building from Source

All rootfs builds run on Linux (GitHub Actions CI). Requires root for debootstrap.

```bash
# x86_64 (Windows WSL / ISO)
sudo ./build/rootfs/build-x86_64.sh

# aarch64 (Apple Silicon Mac / UTM)
sudo ./build/rootfs/build-aarch64.sh

# UTM bundle for Mac
./build/utm/build-utm.sh

# Bootable ISO
sudo ./build/iso/build-iso.sh
```

Build artifacts land in `releases/`.

## Developer Commands

```bash
make validate        # lint + healthcheck
make build-x86_64    # full rootfs (sudo, Linux only)
make clean           # remove build output
```

## Project Structure

```
install.sh                 Universal installer entrypoint
scripts/                   Platform-specific installers
installer/                 Asahi downstream Mac installer adapter
build/rootfs/              debootstrap rootfs builders
build/iso/                 Dual-boot ISO builder
build/utm/                 macOS UTM VM builder
build/kernel/              Asahi kernel build + platform fetch
build/packages/            .deb package builder
build/repo/                APT repo for GitHub Pages (signed when CI signing key is configured)
docs/repo/                 Published APT tree (Pages)
installer/                 Vendored Asahi installer + NexusOS metadata
packages/                  NexusOS custom tools (store, settings, welcome)
configs/                   Plymouth, GRUB, GDM branding
.github/workflows/         CI build and release pipelines
```

## System Commands

| Command | Description |
|---------|-------------|
| `nexus-store` | Software center (interactive or CLI) |
| `nexus-store install htop` | Install a package |
| `nexus-update` | Apply system updates |
| `nexus-update check` | Check for available updates |
| `nexus-settings about` | System information |
| `nexus-settings cleanup` | Disk cleanup |
| `nexus-doctor` | Run system diagnostics |
| `nexus-welcome` | First-boot setup wizard |

## Releases

Tag a version to trigger a full release build:

```bash
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions publishes **x86_64 artifacts only**:

- `nexusos-x86_64-rootfs.tar.xz` — WSL2 / ISO
- `nexusos-x86_64.iso` — Live boot (preview; no automated installer)
- `SHA256SUMS` — Checksums

**Not published on Releases** (git clone + `./install.sh` on Mac instead): aarch64 rootfs,
UTM bundles, Asahi kernel packages, and macOS installer tarballs. See
[Redistribution Policy](docs/REDISTRIBUTION_POLICY.md).

The NexusOS APT repository is deployed to GitHub Pages at
`https://aidiotic.github.io/Operating-system/repo/` (signed when `NEXUSOS_APT_GPG_*`
GitHub Actions secrets are configured; otherwise unsigned).

## Architecture

NexusOS is a **two-layer** distribution (similar in spirit to Fedora Asahi Remix):

| Layer | What it provides | NexusOS owns? |
|-------|------------------|---------------|
| **Platform (Asahi)** | m1n1 → U-Boot boot chain, Apple Silicon kernel patches, firmware, Mesa, WiFi/audio | Uses upstream; dual-boot logic unchanged |
| **Distro (NexusOS)** | Debian bookworm rootfs, GNOME desktop, `nexus-*` packages, APT repo, branding, installers | Yes |

### Platform vs distro

- **Apple Silicon native install** — vendored [Asahi installer](https://github.com/AsahiLinux/asahi-installer) with NexusOS metadata; boot chain and recovery/APFS handling stay upstream.
- **Kernel** — built from [Asahi Linux kernel](https://github.com/AsahiLinux/linux) with `LOCALVERSION=-nexusos`, or prebuilt `linux-image-asahi` from `repo.asahilinux.org` when building on non-arm hosts.
- **Packages** — `nexus-store`, `nexus-settings`, `nexus-theme`, etc. ship as `.deb` files from the NexusOS APT repo on [GitHub Pages](https://aidiotic.github.io/Operating-system/repo/).
- **x86_64 / WSL2 / ISO** — generic Debian rootfs without Asahi platform packages.

### Install paths

- **WSL2** — Windows import of x86_64 rootfs tarball
- **UTM** — macOS virtualization bundle (aarch64)
- **ISO** — dual-boot x86_64 image (preview; live boot supported when kernel is present in rootfs)

## License

Build scripts and NexusOS-specific packages in this repository: **MIT** — see [LICENSE](LICENSE).

Release images (rootfs, ISO, kernel packages) bundle third-party software under GPL, LGPL, and other licenses. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

Legal notices: [Disclaimer](docs/DISCLAIMER.md) · [Trademarks](docs/TRADEMARKS.md) · [Intended use](docs/INTENDED_USE.md) · [Redistribution policy](docs/REDISTRIBUTION_POLICY.md)

## Links

- [Asahi Linux](https://asahilinux.org) — Apple Silicon Linux platform
- [Asahi Installer](https://github.com/AsahiLinux/asahi-installer) — Mac install framework
- [UTM](https://mac.getutm.app) — macOS virtualization
- [WSL2](https://learn.microsoft.com/en-us/windows/wsl/) — Windows Subsystem for Linux
