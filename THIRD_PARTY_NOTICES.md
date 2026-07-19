# Third-Party Notices

NexusOS build scripts are licensed under the MIT License (see `LICENSE`).

NexusOS is **based on Debian GNU/Linux**. Debian is a registered trademark of
Software in the Public Interest, Inc. NexusOS is not Debian and is not affiliated
with SPI.

Release artifacts (root filesystem images, ISO, kernel packages, and `.deb` packages)
bundle and redistribute software from third parties, including but not limited to:

- **Debian GNU/Linux** (packages under GPL, LGPL, and other licenses)
- **Asahi Linux platform** (kernel, firmware, and platform packages on Apple Silicon)
- **Mozilla Firefox**, **GNOME**, and other desktop components

## Source code

Corresponding source code for GPL/LGPL components is available from:

- Debian package sources: `apt source <package>` on a NexusOS system
- Asahi Linux: https://github.com/AsahiLinux
- This repository: build scripts and NexusOS-specific packages

For a tagged release, see `SOURCES-{VERSION}.txt` (when published) and
`/usr/share/nexusos/GPL_SOURCE_OFFER` on installed systems. Contact the maintainers via GitHub Issues for
source requests not satisfied by the above.

## Apple firmware

Apple Silicon support may include proprietary Apple firmware distributed under
Apple's license terms via the Asahi platform. Redistribution of release images
may require separate legal review.
