# NexusOS Asahi kernel pipeline (aarch64 only)

NexusOS tracks the [Asahi Linux kernel](https://github.com/AsahiLinux/linux) — we brand and package it; we do not fork driver code.

## Pinned versions

See [`versions.env`](versions.env). Update `ASAHI_LINUX_TAG` when tracking a new Asahi stable release.

## Option A — Build from source (default)

```bash
./build/kernel/build-asahi-kernel.sh
```

Produces `releases/nexusos-asahi-kernel_<VERSION>_arm64.deb` with `LOCALVERSION=-nexusos`.

Requires native `aarch64` (or set `NEXUSOS_ALLOW_CROSS_KERNEL=1` for CI experiments).

## Option B — Prebuilt fallback

When CI time or host arch is a constraint:

```bash
ASAHI_KERNEL_USE_PREBUILT=1 ./build/kernel/build-asahi-kernel.sh
```

Downloads `linux-image-asahi` from `repo.asahilinux.org` and renames for the release set. Sacrifices the `-nexusos` version string but ships in minutes.

## Platform userspace (firmware, GPU, WiFi)

```bash
sudo ./build/kernel/fetch-asahi-platform.sh /path/to/chroot
```

Installs from the pinned Asahi Debian repo:

- `linux-image-asahi`, `linux-headers-asahi`
- `asahi-audio`, `asahi-wifi`, `asahi-ble`
- `mesa-asahi`

## Integration

[`build/rootfs/build-aarch64.sh`](../rootfs/build-aarch64.sh) calls `common-asahi.sh` to install the kernel `.deb` and platform packages. **x86_64 is unchanged** (generic Debian kernel).
