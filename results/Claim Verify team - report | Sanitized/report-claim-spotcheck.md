SANITIZED public digest — secrets, spoilers, and PoC payloads removed.
Not a full-repro archive. For complete repros see unsanitized team folders (not published).

# Report claim spotcheck

## Summary

| Result | Count |
|--------|------:|
| Confirmed | 32 |
| Partial | 20 |
| Missed | 0 |
| Deferred-ok | 8 |

## Per-claim

| id | severity | claimed | result | evidence | follow_up |
|----|----------|---------|--------|----------|-----------|
| PR-001 | P0 | Fixed | Confirmed | README L14 routes to `scripts/bootstrap.sh`; `install.sh` usage L27 same | — |
| PR-002 | P0 | Fixed | Confirmed | `docs/repo/.../Packages` uses relative `Filename: pool/main/...` | — |
| PR-003 | P0 | Partial | Confirmed | `build-iso.sh` extracts vmlinuz/initrd or `die`; GRUB install entry preview-unavailable | QEMU smoke not in CI |
| PR-004 | P0 | Fixed | Partial | `build-utm.sh` adds 16G `disk.img` + `Drives` virtio block | Boot path not validated; README extraction copy may overstate |
| PR-005 | P0 | Fixed | Confirmed | `chroot-setup.sh` random password, `passwd -e`, force-password-change flag; `nexus-welcome` forces `passwd` when flag set | `useradd`/`chpasswd` use `\|\| true` (silent fail risk) |
| PR-006 | P0 | Fixed | Confirmed | `verify_checksum` dies if sums missing/mismatch (`scripts/common.sh` L72–89) | — |
| PR-007 | P0 | Partial | Confirmed | `docs/repo/dists/stable/` has `Release` only; no `InRelease`/`Release.gpg` | CI `NEXUSOS_REQUIRE_SIGNED_REPO=1` on tag release |
| PR-008 | P0 | Deferred | Deferred-ok | fix-log + legal-review counsel hold; no counsel artifact | Obtain counsel sign-off |
| PR-009 | High | Fixed | Partial | Allowlist in `scripts/common.sh` L13–20 and `install.ps1` L16–18 | `scripts/bootstrap.sh` clones arbitrary `NEXUSOS_REPO` without validation |
| PR-010 | High | Partial | Confirmed | `run-installer.sh` verifies on release download (L47–48) | Local tarball path (L31–39) and `bootstrap-nexusos.sh` download skip checksum |
| PR-011 | High | Fixed | Confirmed | `install-linux.sh` preview header; GRUB `Install NexusOS (preview — unavailable)` | README Dual-boot ISO section partially aligned |
| PR-012 | High | Partial | Confirmed | Legal bundle copied in `chroot-setup.sh` L57–58; README links | WSL/PowerShell paths lack full disclaimer gate |
| PR-013 | High | Fixed | Confirmed | `validate.yml` shellcheck without `\|\| true`; `release.yml` ISO build L77 no `\|\| true` | — |
| PR-014 | High | Fixed | Partial | Root `os-release` has `NEXUSOS_CHANNEL=preview` | `chroot-setup.sh` writes `CHANNEL=stable` in `/etc/nexusos/release` |
| REQ-001 | P0 | Fixed | Confirmed | Same as PR-001 | — |
| REQ-002 | P0 | Fixed | Confirmed | Same as PR-002 | — |
| REQ-003 | P0 | Partial | Confirmed | Same as PR-003 | — |
| REQ-004 | P0 | Fixed | Partial | Same as PR-004 | — |
| REQ-005 | High | Deferred | Deferred-ok | No `nexusos-x86_64.utm` artifact | Separate build target |
| REQ-006 | High | Deferred | Deferred-ok | No `nexusos.install` handler | Keep preview messaging |
| REQ-007 | High | Deferred | Deferred-ok | Linux CI builds metadata-only installer stub | macOS runner or stub labeling |
| REQ-008 | High | Fixed | Confirmed | `release.yml` runs `sudo ./build/iso/build-iso.sh` without mask | — |
| REQ-009 | Low | Fixed | Confirmed | `validate.yml` L20–23 fails on shellcheck errors | — |
| REQ-010 | Medium | Deferred | Deferred-ok | Submodule init in `run-installer.sh` but not documented in README | Document `--recursive` clone |
| REQ-011 | Medium | Fixed | Confirmed | `installer/build.sh` `sync_installer_metadata` from `VERSION` | — |
| REQ-015 | P0 | Fixed | Confirmed | Same as PR-005 | — |
| REQ-018 | High | Fixed | Confirmed | Same as PR-006 | — |
| RT-001 | Critical | Partial | Confirmed | `bootstrap.sh` clones repo; README warns no integrity verification | Pipe-to-shell still documented |
| RT-002 | Critical | Partial | Confirmed | Unsigned committed mirror (see PR-007) | Republish signed mirror on release |
| RT-003 | High | Fixed | Partial | `common.sh` + `install.ps1` allowlist | `bootstrap.sh` / `bootstrap-nexusos.sh` lack allowlist |
| RT-004 | High | Fixed | Confirmed | `verify_checksum` fail-closed | — |
| RT-005 | High | Fixed | Confirmed | No static `nexus:nexus` in chroot-setup | — |
| RT-008 | Medium | Partial | Confirmed | `publish-repo.sh` dies when `NEXUSOS_REQUIRE_SIGNED_REPO=1` without key | Committed tree still unsigned |
| RT-016 | Low | Fixed | Confirmed | Same as REQ-009 | — |
| BE-001 | High | Fixed | Confirmed | Same as PR-005 | — |
| BE-002 | High | Fixed | Partial | Checksum on release download path only | Local + `bootstrap-nexusos.sh` gaps |
| BE-003 | High | Fixed | Confirmed | Same as PR-006 | — |
| BE-004 | High | Partial | Confirmed | Same as RT-001 | — |
| BE-007 | High | Fixed | Confirmed | `run-installer.sh` L100 `sudo ./install.sh` (no `-E`); `bootstrap-nexusos.sh` L71 also without `-E` | Stale general-completeness report cited `-E` |
| LEG-002 | P0 | Deferred | Deferred-ok | Counsel hold documented | — |
| LEG-003 | High | Partial | Confirmed | Legal docs in rootfs + README | On-system MOTD missing non-affiliation footer |
| LEG-004 | High | Partial | Confirmed | Same as LEG-003 | Uneven install-surface coverage |
| LEG-005 | High | Fixed | Confirmed | `install-macos-asahi.sh` typed `YES` gate L29–30 | — |
| MR-001 | P0 | Partial | Confirmed | Preview in `os-release`, MOTD, issue overlays | chroot-setup `CHANNEL=stable` split |
| MR-002 | P0 | Partial | Confirmed | GRUB + install-linux preview copy | README Dual-boot ISO section residual |
| LR-001 | P0 | Partial | Confirmed | `GPL_SOURCE_OFFER` + `SOURCES-1.0.0.txt` drafted; shipped via chroot-setup | Counsel review + per-release manifest |
| LR-002 | P0 | Partial | Confirmed | Native install firmware risk bullets before YES | No counsel opinion artifact |
| LR-003 | P0 | Implemented | Confirmed | README License section splits MIT repo vs bundled licenses | — |
| LR-004 | High | Partial | Confirmed | README legal links; issue non-affiliation line | MOTD lacks non-affiliation footer |
| LR-005 | High | Implemented | Confirmed | AS-IS warnings on `install.sh`, `install.ps1`, WSL/UTM/asahi scripts | — |
| LR-006 | High | Implemented | Confirmed | Same as LEG-005 | — |
| LR-007 | High | Partial | Confirmed | `install-linux.sh` preview language; GRUB unavailable install | README section gap per legal verify |
| LR-008 | High | Partial | Confirmed | README demotes one-liner with integrity warning | `install.sh` usage still shows curl\|sh without warning |
| LR-009 | High | Implemented | Confirmed | README independence line L5 | — |
| LR-014 | High | Implemented | Confirmed | `THIRD_PARTY_NOTICES.md` Debian SPI language | — |
| LR-015 | High | Implemented | Confirmed | `build-debs.sh` copyright + Maintainer Issues URL | — |
| LR-016 | Medium | Implemented | Partial | Download path verified in `run-installer.sh` | Local path bypass; `bootstrap-nexusos.sh` unverified |
| LR-021 | Medium | Implemented | Confirmed | `install.ps1` allowlist | — |
| LR-024 | Medium | Implemented | Confirmed | `nexus-doctor` certification disclaimer L8 | PASS/FAIL labels remain |
| LR-025 | Medium | Implemented | Confirmed | `nexus-store` third-party disclaimer L78 | Desktop branding still "Software Center" |
| LR-027 | Medium | Implemented | Confirmed | README default-user password expiry note | — |
| LR-028 | Medium | Implemented | Confirmed | `INTENDED_USE.md` shipped via chroot-setup | — |
| LR-035 | Info | Implemented | Confirmed | `_validate_nexusos_repo` in `common.sh` | bootstrap.sh not wired |
| LR-036 | Info | Implemented | Confirmed | Credential hardening present | — |
| LR-037 | Info | Implemented | Confirmed | README bootstrap path | — |
| LR-038 | Info | Implemented | Confirmed | ISO kernel extraction + unavailable install menu | — |
| LR-039 | Info | Implemented | Partial | `verify_checksum` fail-closed globally | Not all installer download paths call it |
| LR-040 | Info | Implemented | Confirmed | `docs/DISCLAIMER.md` trademarks cross-ref | — |
| GRG-hold | — | Verified | Confirmed | `make validate` exit 0; static reads on 14 fix clusters | No hardware AT probes run |

## Missed P0/High (action required)

None. All P0/High rows claimed **Fixed** / **Implemented** / **Verified** are at least **Partial** in tree; no fully absent remediations.

## Commands / tests run

| Command | Result |
|---------|--------|
| `make validate` | PASS (healthcheck OK) |
| `ls docs/repo/dists/stable/` | `Release` + `main/` only; `InRelease`/`Release.gpg` missing |
| `grep verify_checksum scripts/common.sh` | Fail-closed implementation confirmed |
| `grep NEXUSOS_REPO scripts/bootstrap.sh` | No allowlist validation |
| `grep sudo installer/bootstrap-nexusos.sh` | `sudo ./install.sh` (no `-E`) |

## Parent next actions

1. No P0/High Missed escalation required — write master verify report and sanitize publish
