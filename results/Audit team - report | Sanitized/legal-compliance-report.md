SANITIZED public digest — secrets, spoilers, and PoC payloads removed.
Not a full-repro archive. For complete repros see unsanitized team folders (not published).

# NexusOS Legal & Compliance Readiness Report

**Project:** NexusOS custom Linux distribution  
**Repository:** `Aidiotic/Operating-system`  
**Branch reviewed:** `main`  
**Audit date:** 2026-07-19  
**Auditor role:** Engineering compliance checklist (not legal advice)  
**Legal mode:** **A** — General product/distro compliance. No clinical, HIPAA, FDA, or medical-device signals detected.

---

## Executive Summary

NexusOS is a downstream Linux distribution that repackages Debian Bookworm, Asahi Linux platform components, and a vendored Asahi installer under NexusOS branding. The repository root is MIT-licensed, but **the shipped product is predominantly third-party binaries** (Debian packages, Asahi kernel/firmware stack, Firefox ESR, GNOME, m1n1/U-Boot chain). **Potential compliance gaps** (pending counsel validation) center on missing third-party license notices, absent GPL/source-offer mechanics for redistributed binaries, no trademark/affiliation disclaimers for Apple/Microsoft/Asahi/UTM, and no end-user terms beyond the repo MIT license.

Installer flows promote `curl | sh` / `irm | iex` without integrity checks on the bootstrap scripts themselves. Native dual-boot warns about backups but lacks explicit liability/data-loss disclaimers appropriate for partition-resize operations. Default credentials are published in README and UTM bundle docs.

**Ship blockers (counsel review recommended before public release):**

1. Binary redistribution license compliance (GPL/LGPL and aggregate third-party notices) for ISO/rootfs/kernel `.deb` artifacts  
2. Apple firmware / Asahi platform redistribution chain (proprietary firmware extraction and redistribution)  
3. Trademark and non-affiliation disclaimers for Apple, Microsoft, Asahi Linux, UTM, and other referenced brands  
4. End-user warranty/liability terms for the distributed OS (distinct from MIT on build scripts)

---

## Scope & Methodology

Reviewed: `LICENSE`, `README.md`, `os-release`, install scripts (`install.sh`, `install.ps1`, platform installers), rootfs/build pipelines, `.deb` packaging, APT repo metadata, installer/Asahi integration, marketing copy in MOTD/issue/UTM README, and release CI workflows.

Not reviewed in depth: contents of vendored `installer/upstream` submodule (not checked out in workspace), full SPDX inventory of thousands of Debian packages inside built rootfs, trademark clearance searches, or jurisdiction-specific consumer-law analysis.

---

## Finding Counts by Severity

| Severity | Count |
|----------|------:|
| P0 / Critical | 2 |
| High | 8 |
| Medium | 9 |
| Low | 4 |
| Info | 3 |
| **Total** | **26** |

---

## Complete Findings

### P0 / Critical

**LEG-001 | P0/Critical | Binary redistribution may not satisfy GPL/source-offer requirements**  
**Area:** License compliance / distro packaging  
**Location:** `build/rootfs/common.sh`, `build/rootfs/build-*.sh`, `build/iso/build-iso.sh`, `.github/workflows/release.yml`, release artifacts (`nexusos-*.tar.xz`, `nexusos-x86_64.iso`)  
**Evidence:** Rootfs installs Debian packages (`firefox-esr`, `gnome-shell`, `gdm3`, etc.) and ships compressed rootfs/ISO via CI release workflow. No `THIRD_PARTY_NOTICES`, `/usr/share/doc/*/copyright` aggregation step, or written GPL source offer (e.g., `/usr/share/common-licenses` pointer + offer document) is documented in-repo. Root `LICENSE` is MIT and applies to build scripts only.  
**Repro:** Run `sudo ./build/rootfs/build-x86_64.sh`; inspect output tarball and repo — no NexusOS-authored source-offer or license bundle beyond Debian's own per-package copyrights inside the image.  
**Suggested fix:** Add `LEGAL/` or `docs/legal/` with third-party notices; ship `/usr/share/nexusos/THIRD_PARTY_NOTICES` and a GPL source-offer file in rootfs; document how users obtain corresponding source (Debian snapshot + Asahi kernel source URLs); have counsel validate Debian redistribution and GPL §3 offer mechanics.

---

**LEG-002 | P0/Critical | Apple firmware redistribution via Asahi platform chain**  
**Area:** Proprietary firmware / platform compliance  
**Location:** `build/kernel/fetch-asahi-platform.sh`, `installer/nexusos-installer-data.json` (`"firmware": "asahi"`), `installer/build.sh` (initializes `asahi_firmware` submodule), README architecture table  
**Evidence:** AArch64 builds pull Asahi platform packages from `repo.asahilinux.org` and integrate Asahi installer firmware submodules. Asahi's model involves Apple-proprietary firmware extracted from macOS installations. NexusOS does not document firmware provenance, user obligations, or redistribution constraints.  
**Repro:** Review `fetch-asahi-platform.sh` package list and installer submodule init; trace release `nexusos-aarch64-rootfs.tar.xz` dependency on Asahi firmware stack.  
**Suggested fix:** Escalate to counsel immediately. Document firmware licensing in user-facing legal notices; align with Asahi Linux project redistribution terms; consider requiring users to supply firmware from their own macOS install where required; do not ship proprietary blobs without explicit rights analysis.

---

### High

**LEG-003 | High | No trademark / non-affiliation disclaimers**  
**Area:** Trademark / marketing claims  
**Location:** `README.md`, `build/rootfs/overlays/etc/motd`, `build/utm/build-utm.sh`, `os-release`, installer UI branding (`installer/run-installer.sh`, `installer/patches/apply.sh`)  
**Evidence:** Prominent use of **Mac**, **Apple Silicon**, **Windows**, **Time Machine**, **Asahi Linux**, **UTM**, **Homebrew**, **Microsoft WSL** with no "not affiliated with or endorsed by" language. README compares NexusOS to Asahi ("like Asahi Linux") without clarifying independent project status.  
**Repro:** Open README and MOTD; search repo for `affiliat` or `trademark` — no matches.  
**Suggested fix:** Add `TRADEMARKS.md` and a short disclaimer in README, installer first screen, and `/etc/issue` or welcome wizard: identify third-party marks and state NexusOS is not affiliated with Apple Inc., Microsoft Corporation, Asahi Linux contributors, UTM, etc.

---

**LEG-004 | High | End-user warranty/liability gap for shipped OS**  
**Area:** Warranty disclaimer / product liability  
**Location:** `LICENSE` (repo only), absence of `TERMS`, `EULA`, or installer click-through  
**Evidence:** MIT disclaimer covers "the Software" (repository scripts). Installed NexusOS images, dual-boot operations, and release binaries have no end-user warranty disclaimer, limitation of liability, or "use at your own risk" terms.  
**Repro:** Install via any path; no legal terms presented except optional `[y/N]` on native install.  
**Suggested fix:** Add end-user license/terms document shown at install time (native + WSL import); include AS-IS disclaimer, data-loss warning, no guarantee of boot stability, and limitation of liability. Counsel to draft jurisdiction-appropriate language.

---

**LEG-005 | High | Insufficient data-loss / partition-resize liability warnings**  
**Area:** Product liability / installer disclaimers  
**Location:** `scripts/install-macos-asahi.sh`, `installer/run-installer.sh`  
**Evidence:** Native install shows backup warning and `Continue? [y/N]` but no explicit acknowledgment of risk of data loss, bricking, voided warranty, or recovery limitations. Asahi installer performs APFS resize and boot-chain modification.  
**Repro:** Run `./install.sh --native` on macOS arm64 (or read script) — only Time Machine backup warn + y/N prompt.  
**Suggested fix:** Add multi-step risk acknowledgment (checkbox or typed confirmation) covering data loss, dual-boot instability, Apple hardware/firmware dependencies, and recommendation to maintain Apple recovery options.

---

**LEG-006 | High | Asahi installer downstream GPL compliance unclear**  
**Area:** Copyleft / vendored upstream  
**Location:** `.gitmodules`, `installer/patches/apply.sh`, `installer/build.sh`, `installer/run-installer.sh`  
**Evidence:** Vendored `AsahiLinux/asahi-installer` submodule with branding patches (`sed` on `util.py`). Release workflow publishes `installer-*.tar.gz`. No `COPYING`, license file, or source-offer for modified installer artifacts in NexusOS repo. Asahi installer is typically GPL-licensed.  
**Repro:** Inspect `.gitmodules`; note patches applied before tarball release; no compliance doc in repo.  
**Suggested fix:** Preserve exact upstream version + patch set; publish corresponding source (submodule revision + `installer/patches/`) alongside releases; include GPL notice in installer tarball; verify Asahi trademark/branding policy for downstream rebranding.

---

**LEG-007 | High | Kernel `.deb` repackaged/renamed without documented GPL attribution**  
**Area:** GPL compliance / branding  
**Location:** `build/kernel/fetch-asahi-platform.sh`, `build/kernel/build-asahi-kernel.sh`  
**Evidence:** Prebuilt path downloads `linux-image-asahi*.deb` and copies to `nexusos-asahi-kernel_${VERSION}_arm64.deb`. Build path uses `LOCALVERSION=-nexusos` and renames output. No `DEBIAN/copyright` maintenance or user-facing notice that kernel is GPL and derived from Asahi/Debian packaging.  
**Repro:** CI `release.yml` job `build-kernel` with `ASAHI_KERNEL_USE_PREBUILT=1`; output filename differs from upstream.  
**Suggested fix:** Do not obscure upstream origin in package metadata; retain or append `linux-image-asahi` copyright files; ship `/usr/share/doc/nexusos-asahi-kernel/copyright`; provide kernel source pointer matching exact build.

---

**LEG-008 | High | Remote install bootstrap without script integrity verification**  
**Area:** Supply chain / consumer safety  
**Location:** `README.md` lines 9–11, 80–82; `install.sh` usage text  
**Evidence:** README promotes pipe-to-shell install patterns (`curl … | sh`, `irm … | iex`) with no checksum, signature, or release-tag verification. Compromised distribution channel could execute arbitrary code with user privileges (including `sudo` in native installer path).  
**Repro:** Follow README one-liner — script executes immediately without hash/signature check. Contrast with `scripts/install-windows-wsl.sh` which verifies release artifact checksums.  
**Suggested fix:** Document verified install path (clone + review, signed releases, minisign/cosign); add optional checksum verification for `install.sh`/`install.ps1`; discourage pipe-to-shell in security-conscious deployments.

---

**LEG-009 | High | Published default credentials increase liability exposure**  
**Area:** Security / consumer harm risk  
**Location:** `README.md` line 44, `build/rootfs/chroot-setup.sh` lines 56–58, `build/utm/build-utm.sh` README.txt, `scripts/install-windows-wsl.sh` line 101  
**Evidence:** Default user `nexus` with a known default password is baked into rootfs (`chpasswd`) and advertised in README and UTM docs. WSL post-install runs `nexus-welcome --non-interactive`, skipping password change prompt.
**Repro:** Build/import rootfs; login with default credentials; WSL path skips interactive password change.
**Suggested fix:** Force password change on first login (PAM `chage` or lock until `nexus-welcome` completes); remove default password from public docs; use random one-time password printed at install time.

---

**LEG-010 | High | Missing third-party notices file for NexusOS `.deb` packages**  
**Area:** Package metadata / OSS compliance  
**Location:** `build/packages/build-debs.sh` (`write_control` function)  
**Evidence:** Generated `DEBIAN/control` lacks `License` field; no `DEBIAN/copyright` file for `nexus-store`, `nexus-settings`, etc. Published APT repo Packages entries only show `Description: NexusOS nexus-*`.  
**Repro:** Run `./build/packages/build-debs.sh`; inspect `releases/debs/*.deb` — MIT license of scripts not propagated into package metadata.  
**Suggested fix:** Add `debian/copyright` (MIT) to each package; set `License: MIT` in control; include full license text in `/usr/share/doc/<pkg>/copyright`.

---

### Medium

**LEG-011 | Medium | No privacy policy for project surfaces**  
**Area:** Privacy / disclosure  
**Location:** Repository root (no `PRIVACY.md`), `os-release` `HOME_URL`/`SUPPORT_URL`, GitHub Pages APT repo  
**Evidence:** No privacy policy describing data collected via GitHub (issues, release downloads, Pages access logs), installer network fetches, or on-system logs (`/var/log/nexus/store.log`, `maintenance.log`). No telemetry code found, but disclosure gap remains for a consumer-facing OS.  
**Repro:** Search repo for `privacy` — no policy files.  
**Suggested fix:** Add `PRIVACY.md` covering website/GitHub data, optional analytics (none today), local log files, and third-party services (Debian/Asahi mirrors, GitHub).

---

**LEG-012 | Medium | `trusted=yes` disables APT signature verification for Asahi repo**  
**Area:** Supply chain security  
**Location:** `build/kernel/fetch-asahi-platform.sh` lines 35–36, 49  
**Evidence:** `deb [trusted=yes] https://repo.asahilinux.org/debian/ stable main` bypasses GPG verification during build.  
**Repro:** Read `fetch-asahi-platform.sh`.  
**Suggested fix:** Pin Asahi archive signing key in build scripts and use `signed-by=`; document key rotation procedure.

---

**LEG-013 | Medium | Installer release tarball downloaded without checksum verification**  
**Area:** Supply chain  
**Location:** `installer/run-installer.sh` lines 43–49  
**Evidence:** `curl` downloads `installer-*.tar.gz` and `installer_data.json` from GitHub Releases without SHA256 verification (unlike WSL/UTM artifact paths).  
**Repro:** Trace `run_from_release_tarball` — no `verify_checksum` call.  
**Suggested fix:** Publish checksums for installer tarballs; verify before extraction; prefer signed artifacts.

---

**LEG-014 | Medium | Firefox trademark / redistribution policy unverified**  
**Area:** Trademark / third-party branding  
**Location:** `build/rootfs/common.sh` (`firefox-esr` in `DESKTOP_PACKAGES`), README "Firefox" feature list  
**Evidence:** NexusOS brands itself as including "Firefox" browser. Mozilla has specific trademark guidelines for Linux distributions using Debian's `firefox-esr` package. No `mozilla.cfg` or documented compliance with Mozilla Distribution Policy.  
**Repro:** Inspect desktop package list and README claims.  
**Suggested fix:** Confirm Debian `firefox-esr` branding is unmodified per Mozilla policy; add required notices; if rebranding, use unbranded build (`firefox-esr` without Mozilla trademarks).

---

**LEG-015 | Medium | ISO dual-boot marketing may outpace implementation**  
**Area:** Marketing claims / potential deceptive-practice risk (jurisdiction-specific)  
**Location:** `scripts/install-linux.sh`, `build/iso/build-iso.sh`, README "Dual-boot ISO" table row  
**Evidence:** README and ISO instructions state installer offers dual-boot when detected. `build-iso.sh` uses placeholder `touch` for `vmlinuz`/`initrd.img` and generic GRUB menu entries (`nexusos.install` kernel param) with no documented installer backend in repo.  
**Repro:** Read `build-iso.sh` lines 53–54; search for `nexusos.install` handler — not implemented in reviewed tree.  
**Suggested fix:** Align marketing copy with actual ISO capabilities; add prominent "preview/unsupported" labeling until installer exists; counsel review if releases are published claiming dual-boot.

---

**LEG-016 | Medium | Placeholder maintainer identity in published packages**  
**Area:** Consumer transparency / package policy  
**Location:** `build/packages/build-debs.sh`, `docs/repo/dists/stable/main/binary-*/Packages`  
**Evidence:** `Maintainer: NexusOS <[email protected]>` — placeholder email in packages published to GitHub Pages APT repo.  
**Repro:** Inspect Packages index or built `.deb` control files.  
**Suggested fix:** Use valid contact address or `debian.org` style `NexusOS Project <https://github.com/.../issues>`.

---

**LEG-017 | Medium | README repository path case mismatch**  
**Area:** Marketing accuracy / consumer confusion  
**Location:** `README.md` line 17 vs lines 10, 73  
**Evidence:** Git clone example uses `cd operating-system` (lowercase) but repo is `Operating-system`. May cause support failures, not strictly legal, but affects published install instructions accuracy.  
**Repro:** Follow README git clone block literally on case-sensitive filesystems.  
**Suggested fix:** Correct directory name to `Operating-system` everywhere.

---

**LEG-018 | Medium | No accessibility (WCAG) statement for public GitHub Pages repo**  
**Area:** Accessibility policy gap (public web; regulatory requirements vary by jurisdiction)  
**Location:** `docs/repo/` (GitHub Pages APT tree), project lacks accessibility statement  
**Evidence:** Published web-facing APT index via Pages has no accessibility conformance statement. Low complexity (machine-oriented), but public site may still warrant basic statement if expanded.  
**Repro:** N/A — policy gap.  
**Suggested fix:** If a user-facing website is added, publish WCAG conformance target and contact for accessibility issues.

---

**LEG-019 | Medium | On-system activity logging without user disclosure**  
**Area:** Privacy  
**Location:** `packages/nexus-store/bin/nexus-store` lines 61, 69; `packages/nexus-settings/bin/nexus-settings` line 32  
**Evidence:** Package install/remove and maintenance actions append timestamps to `/var/log/nexus/store.log` and `maintenance.log` without privacy notice.  
**Repro:** Run `nexus-store install htop`; inspect log file creation.  
**Suggested fix:** Document local logging in privacy notice; consider log rotation/retention policy.

---

### Low

**LEG-020 | Low | "NexusOS" trademark clearance not documented**  
**Area:** Trademark  
**Location:** Project name across `os-release`, packages, marketing  
**Evidence:** "Nexus" is used in many registered marks (e.g., Google Nexus historical, other software products). No trademark clearance or USPTO search summary in repo.  
**Repro:** N/A — documentation gap.  
**Suggested fix:** Counsel trademark search for "NexusOS" in relevant classes (software/OS); consider distinctive branding.

---

**LEG-021 | Low | Debian trademark attribution missing**  
**Area:** Trademark attribution  
**Location:** README, MOTD, legal notices (absent)  
**Evidence:** Debian Social Contract/trademark guidelines encourage proper attribution when distributing Debian-derived systems. NexusOS is Debian Bookworm-based but does not state "based on Debian" in legal notices (only technical docs).  
**Repro:** Search for "Debian" in user-facing legal text — only technical README references.  
**Suggested fix:** Add "NexusOS is based on Debian" with required trademark statement in `README` legal section and on installed system (`/usr/share/doc/nexusos/copyright`).

---

**LEG-022 | Low | Comparative claim "like Asahi Linux" may imply affiliation**  
**Area:** Marketing / trademark  
**Location:** `README.md` line 3  
**Evidence:** Opening sentence positions NexusOS relative to Asahi without explicit independence disclaimer.  
**Repro:** Read README intro.  
**Suggested fix:** Rephrase to "inspired by" or "downstream of" with non-affiliation disclaimer.

---

**LEG-023 | Low | MIT license year/entity may be incomplete**  
**Area:** Copyright notice  
**Location:** `LICENSE`  
**Evidence:** `Copyright (c) 2026 NexusOS Contributors` — no individual/entity legal name; may complicate enforcement or DMCA identity.  
**Repro:** Read LICENSE.  
**Suggested fix:** Use maintainer legal name or formal project entity once established.

---

### Info

**LEG-024 | Info | No first-party telemetry or analytics detected**  
**Area:** Privacy  
**Location:** Codebase search for `telemetry`, `analytics`, `track`  
**Evidence:** No analytics SDKs or remote tracking in NexusOS tools reviewed.  
**Repro:** Grep codebase — no matches in product code.  
**Suggested fix:** Maintain telemetry-free default; document in privacy policy if status changes.

---

**LEG-025 | Info | Root MIT license clearly scoped to repository scripts**  
**Area:** License clarity  
**Location:** `LICENSE`, `README.md` License section  
**Evidence:** README states "MIT — see LICENSE" for the repo; does not incorrectly claim MIT applies to entire OS. Gap is absence of other licenses, not misstatement.  
**Repro:** Read README License section.  
**Suggested fix:** Clarify README: "Build scripts are MIT; the distribution includes software under many licenses."

---

**LEG-026 | Info | Release artifacts include SHA256SUMS generation**  
**Area:** Supply chain (positive)  
**Location:** `build/rootfs/common.sh` `pack_rootfs`, `.github/workflows/release.yml`  
**Evidence:** CI generates `SHA256SUMS` for release files; WSL/UTM installers verify checksums when sums file present.  
**Repro:** Inspect release workflow and `verify_checksum` usage in WSL installer.  
**Suggested fix:** Extend verification to all download paths (installer tarball, `install.sh` bootstrap).

---

## Items Requiring Human Counsel (Not Engineering Sign-Off)

| ID | Topic | Why counsel |
|----|-------|-------------|
| LEG-001 | GPL/aggregate binary redistribution | Source-offer requirements and Debian redistribution policy need legal interpretation |
| LEG-002 | Apple proprietary firmware via Asahi | Potential copyright/DMCA and Apple license restrictions on firmware blobs |
| LEG-003 | Apple/Microsoft/Asahi/UTM trademarks | Nominative fair use vs. endorsement risk; mark usage guidelines |
| LEG-004 | End-user terms and liability limits | Enforceability varies by jurisdiction; dual-boot data-loss scenarios |
| LEG-006 | GPL on modified Asahi installer | Copyleft obligations for branded downstream installer tarballs |
| LEG-007 | Renamed kernel packages | GPL attribution and trademark interaction with Asahi/Linux naming |
| LEG-014 | Mozilla Firefox trademark | Distribution policy compliance for branded browser in custom distro |
| LEG-020 | "NexusOS" trademark clearance | Potential conflicts with existing marks |
| LEG-015 | ISO capability claims | Potential deceptive-practice risk if releases marketed without working installer (jurisdiction-specific; counsel review) |

---

## Ship Blockers Summary

*Engineering recommendations below are not legal clearance or counsel sign-off.*

| Blocker | Findings |
|---------|----------|
| **Defer public releases until** third-party license compliance program is in place (counsel review) | LEG-001, LEG-006, LEG-007, LEG-010 |
| **Defer Apple Silicon native images until** firmware rights are reviewed with counsel | LEG-002 |
| **Add trademark/non-affiliation disclaimers before** broad consumer-facing marketing | LEG-003, LEG-022 |
| **Add end-user liability terms and risk acknowledgment before** shipping destructive installers | LEG-004, LEG-005 |
| **Address before broad promotion** | LEG-008 (pipe-to-shell), LEG-009 (default passwords), LEG-015 (ISO claims) |

---

## Recommended Remediation Priority

1. **Week 0 (pre-release):** LEG-001, LEG-002, LEG-003, LEG-004, LEG-005 — counsel engagement  
2. **Week 1:** LEG-006, LEG-007, LEG-010, LEG-009 — compliance artifacts in build pipeline  
3. **Week 2:** LEG-008, LEG-011, LEG-012, LEG-013, LEG-014 — supply chain and privacy hardening  
4. **Ongoing:** LEG-015 through LEG-023 — accuracy, metadata, and trademark hygiene

---

## Appendix: Files Reviewed

- `LICENSE`, `README.md`, `os-release`, `VERSION`
- `install.sh`, `install.ps1`
- `scripts/common.sh`, `scripts/install-macos-asahi.sh`, `scripts/install-macos-utm.sh`, `scripts/install-windows-wsl.sh`, `scripts/install-linux.sh`
- `installer/run-installer.sh`, `installer/build.sh`, `installer/patches/apply.sh`, `installer/nexusos-installer-data.json`
- `build/rootfs/common.sh`, `build/rootfs/chroot-setup.sh`, `build/rootfs/common-asahi.sh`
- `build/kernel/fetch-asahi-platform.sh`, `build/kernel/build-asahi-kernel.sh`
- `build/packages/build-debs.sh`, `build/iso/build-iso.sh`, `build/utm/build-utm.sh`
- `packages/nexus-store/bin/nexus-store`, `packages/nexus-settings/bin/nexus-settings`, `packages/nexus-welcome/bin/nexus-welcome`
- `build/rootfs/overlays/etc/motd`, `build/rootfs/overlays/etc/issue`
- `.github/workflows/release.yml`, `docs/repo/dists/stable/Release`

---

*This report is an engineering compliance checklist for internal review and does not constitute legal advice. Engage qualified counsel before public distribution of NexusOS binaries.*
