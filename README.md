# NexusOS

A custom Linux distribution for **Mac** and **Windows**. Clone the repo and run the installer — like [Asahi Linux](https://asahilinux.org), with NexusOS branding, packages, and desktop tools on top of the Asahi platform where Apple Silicon hardware requires it.

## Quick Install

### One-liner

```bash
curl -fsSL https://raw.githubusercontent.com/Aidiotic/Operating-system/main/install.sh | sh
```

### Git clone

```bash
git clone https://github.com/Aidiotic/Operating-system.git
cd Operating-system
./install.sh
```

The installer auto-detects your platform and picks the right install method.

## Platform Support

| Platform | Method | Command |
|----------|--------|---------|
| **Mac Apple Silicon** | Native dual-boot (Asahi boot chain) | `./install.sh` or `./install.sh --native` |
| **Mac (any)** | UTM virtual machine | `./install.sh --utm` |
| **Mac Intel** | UTM VM (recommended) or EFI ISO | `./install.sh --utm` |
| **Windows 10/11** | WSL2 distro | `./install.sh` or `./install.sh --wsl` |
| **Windows / Linux PC** | Dual-boot ISO | `./install.sh --iso` |

## What's Included

- **GNOME desktop** with Wayland
- **Firefox** web browser
- **nexus-store** — software center (install apps from catalog or `apt`)
- **nexus-update** — system updates
- **nexus-settings** — system info, disk cleanup, factory reset
- **nexus-doctor** — diagnostics
- **nexus-welcome** — first-boot setup wizard
- **Terminal**, Files (Nautilus), Calculator

Default login: `nexus` / `nexus` (change on first boot)

## Install Details

### Mac Apple Silicon (native dual-boot)

Requires macOS 13.5+. **Back up with Time Machine first.**

```bash
./install.sh --native
```

This uses the [Asahi Linux installer](https://github.com/AsahiLinux/asahi-installer) boot chain (m1n1 → U-Boot → NexusOS kernel) to dual-boot alongside macOS.

### Mac UTM (virtual machine)

No repartitioning required. Works on Apple Silicon and Intel Macs.

```bash
./install.sh --utm
```

Requires [UTM](https://mac.getutm.app) (installed automatically via Homebrew if available).

### Windows WSL2

Run in **PowerShell** (not inside WSL):

```powershell
git clone https://github.com/Aidiotic/Operating-system.git
cd Operating-system
.\install.ps1
```

Or one-liner:

```powershell
irm https://raw.githubusercontent.com/Aidiotic/Operating-system/main/install.ps1 | iex
```

Then launch:

```powershell
wsl -d NexusOS
```

GUI apps work via WSLg on Windows 11.

### Dual-boot ISO

Download `nexusos-x86_64.iso` from [GitHub Releases](https://github.com/Aidiotic/Operating-system/releases) or build locally (requires full rootfs with kernel):

```bash
sudo NEXUSOS_CI_MINIMAL=0 ./build/rootfs/build-x86_64.sh
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
make validate        # sync versions + healthcheck
make sync-version    # propagate VERSION to metadata files
make build-x86_64    # full rootfs (sudo, Linux only)
make clean           # remove build output
```

## Project Structure

```
install.sh                 Universal installer entrypoint
scripts/                   Platform-specific installers
installer/                 Vendored Asahi installer + NexusOS metadata
build/rootfs/              debootstrap rootfs builders
build/iso/                 Dual-boot ISO builder
build/utm/                 macOS UTM VM builder
build/kernel/              Asahi kernel build + platform fetch
build/packages/            .deb package builder
build/repo/                Signed APT repo for GitHub Pages
docs/repo/                 Published APT tree (Pages)
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

GitHub Actions publishes:

- `nexusos-aarch64-rootfs.tar.xz` — Apple Silicon
- `nexusos-x86_64-rootfs.tar.xz` — WSL2 / ISO
- `nexusos-x86_64.iso` — Dual-boot
- `nexusos-aarch64.utm` — Mac UTM VM
- `installer-*.tar.gz` — Branded macOS installer
- `nexusos-asahi-kernel_*_arm64.deb` — Kernel package
- `SHA256SUMS` — Checksums

The NexusOS APT repository is deployed to GitHub Pages at `https://aidiotic.github.io/Operating-system/repo/`.

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
- **ISO** — dual-boot x86_64 image

### How NexusOS compares

| | **Asahi Linux** | **Fedora Asahi Remix** | **NexusOS** |
|---|-----------------|------------------------|-------------|
| Role | Platform + reference distro | Downstream Fedora spin | Downstream Debian-based distro |
| Boot chain | Owns m1n1 / U-Boot | Uses Asahi | Uses Asahi (unchanged) |
| Kernel | Asahi-patched | Asahi-patched, Fedora branding | Asahi-patched, `-nexusos` branding |
| Rootfs | Custom | Fedora | Debian bookworm + GNOME |
| Package manager | `dnf` / RPM | `dnf` | `apt` + NexusOS repo |
| Software center | GNOME Software | GNOME Software | `nexus-store` / `nexus-pkg` |
| Installer | alx.sh | Fedora downstream | NexusOS-branded downstream |
| x86_64 / WSL | No | Limited | Yes (generic Debian path) |

NexusOS is a **custom distro on Asahi** for Apple Silicon — not an independent platform replacement.

## License

MIT — see [LICENSE](LICENSE).

## Links

- [Asahi Linux](https://asahilinux.org) — Apple Silicon Linux platform
- [Asahi Installer](https://github.com/AsahiLinux/asahi-installer) — Mac install framework
- [UTM](https://mac.getutm.app) — macOS virtualization
- [WSL2](https://learn.microsoft.com/en-us/windows/wsl/) — Windows Subsystem for Linux
