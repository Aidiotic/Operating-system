SANITIZED public digest — secrets, spoilers, and PoC payloads removed.
Not a full-repro archive. For complete repros see unsanitized team folders (not published).

# NexusOS Requirements Auditor Report

**Project:** NexusOS (`Aidiotic/Operating-system`)  
**Branch reviewed:** `main`  
**Audit date:** 2026-07-19  
**Auditor role:** Requirements auditor (ship-readiness)  
**Scope:** README, `install.sh`, `install.ps1`, `installer/`, `scripts/`, `build/`, `packages/`, `.github/workflows/`, `Makefile`, `os-release`, published APT repo (`docs/repo/`)

---

## Executive Summary

NexusOS presents a coherent **two-layer distro architecture** (Asahi platform + Debian bookworm rootfs) with well-structured entry points, CI pipelines, and custom `nexus-*` tooling. Local `make validate` / `scripts/healthcheck.sh` pass on the review host.

However, several **user-facing install paths documented in the README are not functionally complete** on `main`. The most severe gaps are:

1. **The documented one-liner (`curl … | sh`) is broken** — it pipes `install.sh`, which requires a full repo checkout (`scripts/common.sh`), while the correct bootstrap script (`scripts/bootstrap.sh`) exists but is never referenced.
2. **Published APT metadata is invalid** — `docs/repo/dists/stable/*/Packages` contains absolute CI workspace `Filename` entries (not repo-relative), so clients cannot fetch `.deb` files from GitHub Pages.
3. **ISO and UTM deliverables are not boot-ready** — ISO uses empty placeholder `vmlinuz`/`initrd.img`; UTM `config.plist` has no attached drives and ships only a rootfs tarball inside a zip renamed `.utm`.
4. **Intel Mac UTM support is misrepresented** — installer always fetches `nexusos-aarch64.utm` with Apple Virtualization (`Platform=Apple`), which does not match Intel hardware.
5. **CI quality gates are soft** — ShellCheck failures are swallowed (`|| true`); release workflow tolerates ISO build failure (`|| true`).

**Ship recommendation (functional readiness only — not legal clearance):** **Not ready for general release** until P0/High install-path and artifact issues are resolved. WSL2 and git-clone-based flows are the closest to shippable; native Asahi, ISO dual-boot, and UTM need verification on target hardware after fixes.

### Findings count by severity

| Severity | Count |
|----------|------:|
| P0 / Critical | 4 |
| High | 7 |
| Medium | 8 |
| Low | 5 |
| Info | 4 |
| **Total** | **28** |

---

## Detection Scope

### Requirements sources reviewed

| Source | Path / location |
|--------|-----------------|
| Primary user docs | `README.md` |
| Version / branding | `VERSION`, `os-release` |
| Universal installer | `install.sh`, `install.ps1` |
| Platform installers | `scripts/install-*.sh`, `scripts/detect-platform.sh`, `scripts/common.sh`, `scripts/bootstrap.sh` |
| macOS native path | `installer/run-installer.sh`, `installer/build.sh`, `installer/nexusos-installer-data.json` |
| Build system | `Makefile`, `build/rootfs/*`, `build/iso/*`, `build/utm/*`, `build/kernel/*`, `build/packages/*`, `build/repo/*` |
| Packages | `packages/nexus-*/bin/*`, `packages/nexus-store/catalog.json` |
| CI / release | `.github/workflows/*.yml` |
| Published APT tree | `docs/repo/dists/stable/*` |

### Verification performed

- Static review of all scoped files
- `bash -n` via `./scripts/healthcheck.sh` (passed)
- Simulated `curl | sh` path resolution for `install.sh`
- Cross-check of README promises vs. implementation references (`nexusos.install`, dual-boot installer, one-liner)
- Submodule presence check (`installer/upstream` — **not initialized** in workspace)

### Requirements with no clear source

| Topic | Notes |
|-------|-------|
| macOS minimum version (13.5+) | Stated in README only; not enforced in scripts |
| First-boot password change | Documented; `nexus-welcome` prompts but WSL path uses `--non-interactive` |
| Signed APT in production | Implied by architecture; signing depends on unpublished CI secrets |
| Hardware test matrix | No in-repo acceptance test spec beyond `healthcheck.sh` |
| Security policy for default creds | Not documented beyond README warning |

---

## Coverage Matrix

| Requirement (from README / architecture) | Status | Evidence |
|--------------------------------------------|--------|----------|
| One-liner install (`curl \| sh`) | **Missing** | `install.sh` sources missing `scripts/common.sh` when piped |
| Git clone + `./install.sh` | **Met** | Full repo provides `scripts/` |
| Auto-detect platform routing | **Met** | `install.sh` + `detect-platform.sh` |
| Mac Apple Silicon native dual-boot (Asahi) | **Partial** | Flow exists; submodule absent; CI builds Linux stub installer |
| Mac UTM VM (Apple Silicon + Intel) | **Partial** | Script exists; artifact aarch64-only; VM config incomplete |
| Windows WSL2 install | **Partial** | `install-windows-wsl.sh` + `install.ps1`; depends on published release tarball |
| Dual-boot ISO (x86_64) | **Missing** | Placeholder kernel/initrd; no `nexusos.install` handler |
| GNOME + Firefox desktop in rootfs | **Partial** | Full build installs desktop; CI minimal builds skip it |
| `nexus-store`, `nexus-update`, `nexus-settings`, `nexus-doctor`, `nexus-welcome` | **Partial** | Scripts exist; rootfs install depends on `.deb` build; APT repo broken |
| NexusOS APT repo on GitHub Pages | **Partial** | Layout present; `Packages` `Filename` paths invalid |
| Tag-driven release artifacts | **Partial** | `release.yml` exists; ISO failure ignored |
| `make validate` / CI validate | **Partial** | Healthcheck passes; ShellCheck non-blocking |
| Version sync (`VERSION` ↔ `os-release`) | **Met** | `healthcheck.sh` checks |
| Version sync (`VERSION` ↔ installer metadata) | **Missing** | Hardcoded `1.0.0` in `nexusos-installer-data.json` |

---

## Findings Table

| ID | Severity | Title | Location |
|----|----------|-------|----------|
| REQ-001 | P0/Critical | One-liner `curl \| sh` install is broken | `README.md`, `install.sh`, `scripts/bootstrap.sh` |
| REQ-002 | P0/Critical | Published APT `Packages` uses absolute `Filename` paths | `docs/repo/dists/stable/main/binary-*/Packages` |
| REQ-003 | P0/Critical | ISO build ships placeholder kernel/initrd (non-bootable) | `build/iso/build-iso.sh` |
| REQ-004 | P0/Critical | UTM bundle has no boot disk / drive configuration | `build/utm/build-utm.sh` |
| REQ-005 | High | Intel Mac UTM path incompatible with published artifact | `scripts/install-macos-utm.sh`, `build/utm/build-utm.sh`, `README.md` |
| REQ-006 | High | ISO dual-boot installer not implemented | `build/iso/build-iso.sh`, `scripts/install-linux.sh`, `README.md` |
| REQ-007 | High | CI builds macOS installer stub on Linux, not runnable installer | `installer/build.sh` |
| REQ-008 | High | Release workflow ignores ISO build failures | `.github/workflows/release.yml` |
| REQ-009 | High | ShellCheck lint does not fail CI | `.github/workflows/validate.yml` |
| REQ-010 | High | Asahi installer submodule not initialized in tree | `installer/upstream`, `.gitmodules` |
| REQ-011 | High | Installer metadata version hardcoded, not synced to `VERSION` | `installer/nexusos-installer-data.json` |
| REQ-012 | Medium | README clone path case typo | `README.md` |
| REQ-013 | Medium | `scripts/bootstrap.sh` exists but is unreferenced | `scripts/bootstrap.sh` |
| REQ-014 | Medium | CI x86_64 rootfs uses minimal profile vs full release build | `.github/workflows/build-rootfs-x86_64.yml`, `release.yml` |
| REQ-015 | Medium | Default known credentials baked into rootfs | `build/rootfs/chroot-setup.sh`, `README.md` |
| REQ-016 | Medium | UTM artifact format may be invalid (zip renamed `.utm`) | `build/utm/build-utm.sh` |
| REQ-017 | Medium | GitHub URL casing inconsistent across docs/config | `README.md`, `build/rootfs/overlays/.../nexusos.list` |
| REQ-018 | Medium | Checksum verification skipped when `SHA256SUMS` missing | `scripts/common.sh` |
| REQ-019 | Medium | WSL post-install runs `nexus-welcome --non-interactive` before first login | `scripts/install-windows-wsl.sh` |
| REQ-020 | Low | `nexus-meta` not explicitly installed in rootfs setup | `build/rootfs/common.sh`, `build/packages/build-debs.sh` |
| REQ-021 | Low | `factory_reset` only clears default user home | `packages/nexus-settings/bin/nexus-settings` |
| REQ-022 | Low | WSL uninstall script undocumented in README | `scripts/uninstall-windows-wsl.sh` |
| REQ-023 | Low | Healthcheck does not verify submodule or release artifacts | `scripts/healthcheck.sh` |
| REQ-024 | Low | `install.ps1` requires `git`/`bash` without preflight checks | `install.ps1` |
| REQ-025 | Info | Architecture and project structure well documented | `README.md` |
| REQ-026 | Info | SPDX headers and MIT license present | `LICENSE`, shell scripts |
| REQ-027 | Info | Local healthcheck passes on review host | `scripts/healthcheck.sh` |
| REQ-028 | Info | `make validate` maps to healthcheck only (no full build) | `Makefile` |

---

## Per-Finding Detail

### REQ-001 | P0/Critical | One-liner `curl | sh` install is broken

| Field | Detail |
|-------|--------|
| **Requirement source** | `README.md` Quick Install one-liner |
| **Location** | `README.md` L9–10; `install.sh` L7–9 |
| **Evidence** | README documents a pipe-to-shell one-liner against `install.sh`. `install.sh` does `source "${ROOT}/scripts/common.sh"`. When piped to `sh`, `$0` is `sh`, so `ROOT` resolves to the current working directory (not the repo). `scripts/bootstrap.sh` clones the repo and execs `./install.sh` but is **never referenced** anywhere in the repo. |
| **Repro** | Run documented one-liner from an empty directory → fails with `No such file or directory` sourcing `scripts/common.sh`. |
| **Suggested fix** | Change README one-liner to pipe `scripts/bootstrap.sh`, or inline clone logic at top of `install.sh` when `scripts/common.sh` is missing. Add CI test that simulates pipe install. |

---

### REQ-002 | P0/Critical | Published APT `Packages` uses absolute `Filename` paths

| Field | Detail |
|-------|--------|
| **Requirement source** | README APT repo URL; architecture section |
| **Location** | `docs/repo/dists/stable/main/binary-amd64/Packages` L5; `binary-arm64/Packages` |
| **Evidence** | `Filename:` line uses an absolute CI workspace path instead of repo-relative `pool/main/...`. APT clients on end-user systems resolve `Filename` relative to repo root on GitHub Pages. |
| **Repro** | On a NexusOS/Debian system with `nexusos.list` configured: `sudo apt update && apt-cache show nexus-store` then attempt `sudo apt install nexus-store` — fetch URL will 404. |
| **Suggested fix** | Regenerate `Packages` with `dpkg-scanpackages` so `Filename` is `pool/main/...` (relative). Add publish-time assertion rejecting `Filename` lines starting with `/`. Commit regenerated `docs/repo/`. |

---

### REQ-003 | P0/Critical | ISO build ships placeholder kernel/initrd (non-bootable)

| Field | Detail |
|-------|--------|
| **Requirement source** | README Dual-boot ISO; release artifact list |
| **Location** | `build/iso/build-iso.sh` L53–54 |
| **Evidence** | `# Placeholder kernel/initrd — real CI builds extract from rootfs` followed by `touch "$WORK/live/vmlinuz" "$WORK/live/initrd.img"` (empty files). GRUB menu references `/live/vmlinuz` and `/live/initrd.img`. |
| **Repro** | `sudo ./build/iso/build-iso.sh` → boot ISO in VM → kernel load fails (empty/initrd missing). |
| **Suggested fix** | Extract `vmlinuz` and `initrd` from rootfs or build live-boot initramfs; fail build if kernel artifacts missing. Remove placeholder `touch`. |

---

### REQ-004 | P0/Critical | UTM bundle has no boot disk / drive configuration

| Field | Detail |
|-------|--------|
| **Requirement source** | README Mac UTM VM; `nexusos-aarch64.utm` release artifact |
| **Location** | `build/utm/build-utm.sh` L32–94 |
| **Evidence** | `config.plist` defines CPU/RAM/display/network but **no `Drive` / storage entries**. Rootfs tarball copied to `Images/nexusos-rootfs.tar.xz` but not attached as bootable media. README says "First boot extracts rootfs" — no extraction logic in bundle. |
| **Repro** | Build or download `.utm`, open in UTM → VM has nothing to boot from. |
| **Suggested fix** | Add virtio/virt disk with prepared qcow2/raw rootfs or cloud-init ISO; document first-boot flow. Align with UTM bundle schema (directory bundle vs archive). |

---

### REQ-005 | High | Intel Mac UTM path incompatible with published artifact

| Field | Detail |
|-------|--------|
| **Requirement source** | README Platform Support table (Intel Mac → UTM) |
| **Location** | `install.sh` L64–66; `scripts/install-macos-utm.sh` L13–14; `build/utm/build-utm.sh` L79–85 |
| **Evidence** | Intel Mac auto-routes to `install-macos-utm.sh`. Script always downloads `nexusos-aarch64.utm`. UTM config sets `Platform=Apple`, `Architecture=aarch64` (Apple Virtualization). Intel Macs require x86_64 + QEMU/standard virtualization. |
| **Repro** | On Intel Mac: `./install.sh` → downloads aarch64 Apple-virt bundle → UTM cannot run it natively. |
| **Suggested fix** | Detect host arch; ship `nexusos-x86_64.utm` for Intel or document Intel → ISO-only. Update README table. |

---

### REQ-006 | High | ISO dual-boot installer not implemented

| Field | Detail |
|-------|--------|
| **Requirement source** | README "installer will offer dual-boot"; `install-linux.sh` |
| **Location** | `build/iso/build-iso.sh` L45–47; `scripts/install-linux.sh` |
| **Evidence** | GRUB entry passes `nexusos.install` kernel param. **No handler** anywhere in codebase (single grep hit). `install-linux.sh` only prints download/write instructions. |
| **Repro** | Boot ISO → select "Install NexusOS (dual-boot)" → no installer runs. |
| **Suggested fix** | Implement live installer (e.g., calamares or custom script) or revise README to "live environment only / manual partitioning". |

---

### REQ-007 | High | CI builds macOS installer stub on Linux, not runnable installer

| Field | Detail |
|-------|--------|
| **Requirement source** | README native install; release `installer-*.tar.gz` |
| **Location** | `installer/build.sh` L28–41 |
| **Evidence** | On non-Darwin: copies `upstream/src` to stage, adds metadata, tars as `installer-${VERSION}.tar.gz`. Does not run Asahi `build.sh` (m1n1, firmware, etc.). `run-installer.sh` extracts and execs `./install.sh` expecting full installer. |
| **Repro** | Download release `installer-1.0.0.tar.gz` from CI on Apple Silicon Mac → likely missing firmware/boot chain payloads. |
| **Suggested fix** | Build real installer on `macos-latest` runner, or document that native install requires `git clone` + submodule build on Mac. |

---

### REQ-008 | High | Release workflow ignores ISO build failures

| Field | Detail |
|-------|--------|
| **Requirement source** | README release artifacts (`nexusos-x86_64.iso`) |
| **Location** | `.github/workflows/release.yml` L76 |
| **Evidence** | `sudo ./build/iso/build-iso.sh || true` — failures do not fail job. Release may publish broken/missing ISO with `SHA256SUMS`. |
| **Repro** | Break ISO build intentionally → tag release → workflow still green; release may ship corrupt ISO. |
| **Suggested fix** | Remove `|| true`; gate release on ISO artifact checksum/size validation. |

---

### REQ-009 | High | ShellCheck lint does not fail CI

| Field | Detail |
|-------|--------|
| **Requirement source** | Best practice / `make validate` intent |
| **Location** | `.github/workflows/validate.yml` L20–22 |
| **Evidence** | `shellcheck … \|\| true` swallows all lint errors. Only `healthcheck.sh` can fail the job. |
| **Repro** | Introduce ShellCheck error in any `.sh` → CI still passes. |
| **Suggested fix** | Remove `\|\| true`; use `shellcheck -e SC1091,SC2034,SC2164` with `set -e` or aggregate exit code. |

---

### REQ-010 | High | Asahi installer submodule not initialized in tree

| Field | Detail |
|-------|--------|
| **Requirement source** | README Architecture; `installer/run-installer.sh` |
| **Location** | `.gitmodules`; `installer/upstream/` (empty) |
| **Evidence** | `installer/upstream` submodule defined but not checked out in workspace. `run-installer.sh` falls back to release tarball download. Fresh clone without `git submodule update --init` cannot build native installer locally without network release. |
| **Repro** | `git clone … && ./install.sh --native` on Mac without release artifacts → submodule fetch or download required; may fail offline. |
| **Suggested fix** | Document submodule init in README; add healthcheck/submodule CI step; ensure release workflow uses `submodules: recursive` for installer build (already does for `build-installer` job). |

---

### REQ-011 | High | Installer metadata version hardcoded, not synced to `VERSION`

| Field | Detail |
|-------|--------|
| **Requirement source** | Release process; `healthcheck.sh` version sync |
| **Location** | `installer/nexusos-installer-data.json` L3–5 |
| **Evidence** | `"version": "1.0.0"` and `repo_base` URL embed `v1.0.0` literally. `healthcheck.sh` checks `VERSION` ↔ `os-release` only. Bumping `VERSION` without editing JSON breaks native install artifact resolution. |
| **Repro** | Set `VERSION=1.1.0`, tag `v1.1.0` without updating JSON → installer points at wrong release paths. |
| **Suggested fix** | Generate `nexusos-installer-data.json` from `VERSION` at build time; add healthcheck assertion. |

---

### REQ-012 | Medium | README clone path case typo

| Field | Detail |
|-------|--------|
| **Requirement source** | README Git clone instructions |
| **Location** | `README.md` L16–18 |
| **Evidence** | `cd operating-system` but repo name is `Operating-system` (case-sensitive on Linux). |
| **Repro** | Linux: `cd operating-system` → directory not found. |
| **Suggested fix** | Use exact repo name: `cd Operating-system`. |

---

### REQ-013 | Medium | `scripts/bootstrap.sh` exists but is unreferenced

| Field | Detail |
|-------|--------|
| **Requirement source** | Implied one-liner / remote install |
| **Location** | `scripts/bootstrap.sh` |
| **Evidence** | Bootstrap clones repo and execs `install.sh`. Zero references in README, `install.sh`, or CI. |
| **Repro** | N/A — dead code path unless user discovers manually. |
| **Suggested fix** | Wire README one-liner to bootstrap URL or merge bootstrap into `install.sh`. |

---

### REQ-014 | Medium | CI x86_64 rootfs uses minimal profile vs full release build

| Field | Detail |
|-------|--------|
| **Requirement source** | README "What's Included" desktop stack |
| **Location** | `.github/workflows/build-rootfs-x86_64.yml` L31; `release.yml` L75 |
| **Evidence** | Branch CI: `NEXUSOS_CI_MINIMAL=1` (no GNOME/desktop). Release: `NEXUSOS_CI_MINIMAL=0`. PR artifacts ≠ release artifacts. |
| **Repro** | Download CI artifact from main push → rootfs lacks desktop packages. |
| **Suggested fix** | Document artifact types; add optional full-build workflow; smoke-test desktop packages in release only. |

---

### REQ-015 | Medium | Default known credentials baked into rootfs

| Field | Detail |
|-------|--------|
| **Requirement source** | README default login |
| **Location** | `build/rootfs/chroot-setup.sh` L56–58 |
| **Evidence** | Default credentials set via `chpasswd` in chroot. Documented but insecure for any network-exposed install. |
| **Repro** | Import WSL / boot VM → login with known default credentials. |
| **Suggested fix** | Force password change on first login (expand `nexus-welcome`); disable SSH password auth by default; document security model. |

---

### REQ-016 | Medium | UTM artifact format may be invalid (zip renamed `.utm`)

| Field | Detail |
|-------|--------|
| **Requirement source** | UTM bundle release |
| **Location** | `build/utm/build-utm.sh` L112–114 |
| **Evidence** | `(cd "$WORK" && zip -r …)` then `mv …zip …utm`. UTM typically expects `.utm` **bundle directory** on macOS; zip rename may not register as UTM document type. |
| **Repro** | Double-click `.utm` on macOS → may not open in UTM or may require manual import. |
| **Suggested fix** | Emit proper `.utm` bundle directory; validate with `open -a UTM` in CI on macOS runner. |

---

### REQ-017 | Medium | GitHub URL casing inconsistent across docs/config

| Field | Detail |
|-------|--------|
| **Requirement source** | README Links / Releases |
| **Location** | `README.md` L94, L179; `build/rootfs/overlays/etc/apt/sources.list.d/nexusos.list` |
| **Evidence** | Mix of `Aidiotic/Operating-system`, `aidiotic/operating-system`, `aidiotic.github.io/Operating-system`. GitHub is case-insensitive for user/repo but inconsistent branding risks broken links on forks. |
| **Repro** | Compare URLs in README vs apt source — different casing/path segments. |
| **Suggested fix** | Canonicalize to actual org/repo casing; use env vars / `NEXUSOS_REPO` everywhere. |

---

### REQ-018 | Medium | Checksum verification skipped when `SHA256SUMS` missing

| Field | Detail |
|-------|--------|
| **Requirement source** | Supply-chain best practice |
| **Location** | `scripts/common.sh` L56–58 |
| **Evidence** | `verify_checksum` returns 0 with warning if sums file missing. Downloaders use `download_release "SHA256SUMS" … \|\| true`. |
| **Repro** | Publish release without `SHA256SUMS` → installers accept unverified tarballs. |
| **Suggested fix** | Fail closed when checksum file absent for release downloads; require `SHA256SUMS` in release workflow. |

---

### REQ-019 | Medium | WSL post-install runs `nexus-welcome --non-interactive` before first login

| Field | Detail |
|-------|--------|
| **Requirement source** | README first-boot wizard |
| **Location** | `scripts/install-windows-wsl.sh` L56–69 |
| **Evidence** | `nexus-welcome --non-interactive` during import; skips password/display prompts. README says "change on first boot". |
| **Repro** | Install WSL → default password remains unchanged until user runs `nexus-welcome` manually. |
| **Suggested fix** | Run interactive wizard on first `wsl -d NexusOS` login only; or force `passwd` in post-import script. |

---

### REQ-020 | Low | `nexus-meta` not explicitly installed in rootfs setup

| Field | Detail |
|-------|--------|
| **Requirement source** | `nexus-doctor` metapackage check |
| **Location** | `build/rootfs/common.sh` `install_nexus_debs` |
| **Evidence** | Copies all `releases/debs/*.deb` if present; `nexus-meta` included if built. If `build-debs.sh` skipped (warn path), metapackage absent. `nexus-doctor` treats as optional (warn). |
| **Repro** | Build rootfs with deb step skipped → `nexus-meta` not installed. |
| **Suggested fix** | `apt install nexus-meta` explicitly in chroot; fail build if debs missing. |

---

### REQ-021 | Low | `factory_reset` only clears default user home

| Field | Detail |
|-------|--------|
| **Requirement source** | README `nexus-settings` factory reset |
| **Location** | `packages/nexus-settings/bin/nexus-settings` L36–41 |
| **Evidence** | `rm -rf` on default user home only — system packages/settings untouched. |
| **Repro** | `nexus-settings reset` → partial reset. |
| **Suggested fix** | Rename to `reset-user` or document scope; align README wording. |

---

### REQ-022 | Low | WSL uninstall script undocumented in README

| Field | Detail |
|-------|--------|
| **Requirement source** | Operational completeness |
| **Location** | `scripts/uninstall-windows-wsl.sh` |
| **Evidence** | Script exists and works; not listed in README System Commands or Install Details. |
| **Repro** | User searches README for uninstall → not found. |
| **Suggested fix** | Add uninstall section to README. |

---

### REQ-023 | Low | Healthcheck does not verify submodule or release artifacts

| Field | Detail |
|-------|--------|
| **Requirement source** | `make validate` ship gate |
| **Location** | `scripts/healthcheck.sh` |
| **Evidence** | Checks syntax, JSON, os-release, keyring, repo layout, version — not submodule, ISO/UTM payloads, or installer tarball. |
| **Repro** | `make validate` passes while native/ISO/UTM paths broken. |
| **Suggested fix** | Add optional `--strict` checks for submodule, Packages Filename format, ISO/UTM smoke tests. |

---

### REQ-024 | Low | `install.ps1` requires `git`/`bash` without preflight checks

| Field | Detail |
|-------|--------|
| **Requirement source** | Windows install UX |
| **Location** | `install.ps1` L48–56 |
| **Evidence** | Clones via `git` if `install.sh` missing; invokes `bash` without verifying installation when not using clone path. |
| **Repro** | Run `irm …/install.ps1 \| iex` on Windows without Git Bash → opaque failure. |
| **Suggested fix** | Preflight `git`, `bash`; document Git for Windows requirement. |

---

### REQ-025 | Info | Architecture and project structure well documented

| Field | Detail |
|-------|--------|
| **Requirement source** | README Architecture section |
| **Location** | `README.md` |
| **Evidence** | Two-layer model, install paths, build commands clearly described. |
| **Suggested fix** | Keep updated as gaps (ISO, UTM) are fixed. |

---

### REQ-026 | Info | SPDX headers and MIT license present

| Field | Detail |
|-------|--------|
| **Requirement source** | `LICENSE` |
| **Location** | Repo root, most shell scripts |
| **Evidence** | MIT license file; SPDX lines in build/install scripts. |

---

### REQ-027 | Info | Local healthcheck passes on review host

| Field | Detail |
|-------|--------|
| **Requirement source** | `make validate` |
| **Location** | `scripts/healthcheck.sh` |
| **Evidence** | All checks OK on macOS aarch64 review environment (2026-07-19). |

---

### REQ-028 | Info | `make validate` maps to healthcheck only (no full build)

| Field | Detail |
|-------|--------|
| **Requirement source** | `Makefile` |
| **Location** | `Makefile` L24–25 |
| **Evidence** | `validate` target runs `healthcheck.sh` only — no rootfs/ISO/UTM build validation. |

---

## Ship Blockers (explicit)

| Blocker | Finding IDs |
|---------|-------------|
| Documented one-liner install fails | REQ-001 |
| APT repo cannot serve packages to end users | REQ-002 |
| ISO release artifact non-bootable | REQ-003, REQ-006, REQ-008 |
| UTM VM artifact non-functional | REQ-004, REQ-005, REQ-016 |
| Native Mac installer artifact integrity unverified | REQ-007, REQ-010, REQ-011 |

---

## Acceptance Tests

Manual / CI acceptance tests recommended before tagging a release:

### AT-01 — One-liner install (macOS / Linux host with curl)

```bash
# From empty temp directory, run documented pipe-to-shell one-liner (URL redacted)
# Expected (after fix): clones repo and starts installer
# Current expected: FAIL — missing scripts/common.sh
```

### AT-02 — Git clone install routing

```bash
git clone https://github.com/Aidiotic/Operating-system.git && cd Operating-system
./install.sh --help
./scripts/detect-platform.sh
make validate
# Expected: help text, platform line, healthcheck exit 0
```

### AT-03 — APT repository fetch

```bash
# On Debian/bookworm chroot or NexusOS VM
sudo apt update
apt-cache policy nexus-store
sudo apt install -y nexus-store
# Expected: package downloads from github.io/repo pool paths
# Current expected: FAIL — Filename 404
```

### AT-04 — WSL2 install (Windows 11)

```powershell
git clone https://github.com/Aidiotic/Operating-system.git
cd Operating-system
.\install.ps1
wsl -d NexusOS -- nexus-doctor
# Expected: distro imports, doctor mostly passes
# Depends on published v{VERSION} rootfs tarball
```

### AT-05 — ISO boot smoke test

```bash
sudo ./build/rootfs/build-x86_64.sh
sudo ./build/iso/build-iso.sh
# Boot ISO in QEMU/UTM x86_64
# Expected: live desktop loads; install entry works
# Current expected: FAIL — empty vmlinuz/initrd
```

### AT-06 — UTM bundle (Apple Silicon Mac)

```bash
./install.sh --utm
# Expected: UTM opens, VM boots to NexusOS login
# Current expected: FAIL — no attached boot disk
```

### AT-07 — Native Asahi install (Apple Silicon Mac, test machine)

```bash
./install.sh --native
# Expected: branded Asahi installer with valid firmware/kernel payloads
# Verify: dual-boot option, recovery partition, NexusOS rootfs flash
```

### AT-08 — Release workflow integrity

```bash
git tag vX.Y.Z && git push origin vX.Y.Z
# Expected: all jobs green; SHA256SUMS covers all artifacts;
# ISO size > threshold; installer tarball runs on macOS
# Current: ISO job may fail silently (|| true)
```

### AT-09 — Version bump regression

```bash
# Bump VERSION and os-release only
make validate
./installer/build.sh
# Expected: healthcheck should fail until nexusos-installer-data.json updated
# Current: passes (gap REQ-011)
```

### AT-10 — CI lint gate

```bash
# Introduce intentional ShellCheck error in scripts/foo.sh
git push
# Expected: validate workflow fails
# Current: passes (REQ-009)
```

---

## Summary for Orchestrator

- **Report path:** `results/Audit team - report | Sanitized/requirements-auditor-report.md`
- **Total findings:** 28 (P0: 4, High: 7, Medium: 8, Low: 5, Info: 4)
- **Top ship blockers:** broken one-liner (REQ-001), broken APT repo metadata (REQ-002), non-bootable ISO (REQ-003), non-functional UTM bundle (REQ-004)
- **Requirements without clear source:** macOS 13.5+ enforcement, production signing policy, hardware test matrix, default-credential security policy
- **Overall:** Architecture and scaffolding are solid; **end-user install artifacts and documented quick-start paths need fixes before general release**

---

*This report assesses functional and documentation readiness only. It does not constitute legal advice, compliance certification, or counsel sign-off.*
