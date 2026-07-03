# NexusOS

A real custom Linux operating system for **Mac** and **Windows**. Clone the repo and run the installer — like [Asahi Linux](https://asahilinux.org), but a completely custom distro with its own desktop, browser, app store, and maintenance tools.

## Quick Install

### One-liner

```bash
curl -fsSL https://raw.githubusercontent.com/aidiotic/operating-system/main/install.sh | sh
```

### Git clone

```bash
git clone https://github.com/aidiotic/operating-system.git
cd operating-system
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
- **Terminal**, Files (Nautilus), Calculator, Text Editor

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
git clone https://github.com/aidiotic/operating-system.git
cd operating-system
bash install.sh --wsl
```

Then launch:

```powershell
wsl -d NexusOS
```

GUI apps work via WSLg on Windows 11.

### Dual-boot ISO

Download `nexusos-x86_64.iso` from [GitHub Releases](https://github.com/aidiotic/operating-system/releases) or build locally:

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

## Project Structure

```
install.sh                 Universal installer entrypoint
scripts/                   Platform-specific installers
installer/                 Asahi downstream Mac installer adapter
build/rootfs/              debootstrap rootfs builders
build/iso/                 Dual-boot ISO builder
build/utm/                 macOS UTM VM builder
build/kernel/              Kernel config fragments
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
- `SHA256SUMS` — Checksums

## Architecture

NexusOS is a custom Linux distribution built on:

- **Debian bookworm** base rootfs with GNOME
- **Asahi Linux** boot chain for Apple Silicon native install
- **WSL2** import for Windows
- **UTM** for macOS virtualization

Apple Silicon hardware support (GPU, WiFi, speakers) comes from Asahi kernel patches — the same foundation used by Fedora Asahi Remix.

## License

MIT — see [LICENSE](LICENSE).

## Links

- [Asahi Linux](https://asahilinux.org) — Apple Silicon Linux platform
- [Asahi Installer](https://github.com/AsahiLinux/asahi-installer) — Mac install framework
- [UTM](https://mac.getutm.app) — macOS virtualization
- [WSL2](https://learn.microsoft.com/en-us/windows/wsl/) — Windows Subsystem for Linux
