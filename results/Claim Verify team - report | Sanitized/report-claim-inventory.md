SANITIZED public digest — secrets, spoilers, and PoC payloads removed.
Not a full-repro archive. For complete repros see unsanitized team folders (not published).

# Report claim inventory

## Mode / depth

`after_full` / **full** — post full pr-ready; scope per `modes.md` full globs.

## Sources scanned

| path | used | notes |
|------|------|-------|
| `results/pr-ready-report.md` | yes | Master PR-ready consolidated findings PR-001–PR-014 |
| `results/pr-ready-fix-log.md` | yes | Primary remediation ledger (22 rows) |
| `Red team reports/redteam-report.md` | yes | Baseline adversarial findings (pre-fix probes); no post-fix Fixed claims |
| `legal - results/legal-review-report.md` | yes | Consolidated legal posture LR-001–LR-040 |
| `legal - results/legal-implementation-log.md` | yes | Implementation status per LR-* |
| `legal - results/legal-implementation-verify.md` | yes | Verified / Partial / Implemented / Deferred-accepted per LR-* |
| `marketing - reports/marketing-review-report.md` | yes | Post-fix delta + MR-* punch list (open items) |
| `marketing - reports/marketing-implementation-{log,verify}.md` | no | Not present |
| `generalist reports/general-review-report.md` | yes | GR-* consolidated + fix-hold claims |
| `generalist reports/general-{completeness,consistency,quality,regression}-report.md` | yes | Fix-log crosswalk and regression holds |
| `audit - reports/pr-ready-overload.md` | yes | Deduped punch list reference |
| `results/pr-ready-lite-*` | no | Not present (full flow only) |

## Claims

| id | severity | source | claimed_status | title | evidence_pointer |
|----|----------|--------|----------------|-------|------------------|
| PR-001 | P0 | pr-ready-report | Fixed | Broken curl\|sh one-liner → bootstrap.sh | fix-log REQ-001; README L11–14 |
| PR-002 | P0 | pr-ready-report | Fixed | Invalid APT Packages paths | fix-log REQ-002; `docs/repo/.../Packages` Filename |
| PR-003 | P0 | pr-ready-report | Partial | Non-bootable ISO placeholders | fix-log REQ-003; `build/iso/build-iso.sh` |
| PR-004 | P0 | pr-ready-report | Fixed | UTM missing boot disk | fix-log REQ-004; `build/utm/build-utm.sh` Drives |
| PR-005 | P0 | pr-ready-report | Fixed | Default nexus:nexus credentials | fix-log REQ-015/RT-005/BE-001; `chroot-setup.sh` |
| PR-006 | P0 | pr-ready-report | Fixed | Checksum verification fail-open | fix-log REQ-018/RT-004/BE-003; `scripts/common.sh` verify_checksum |
| PR-007 | P0 | pr-ready-report | Partial | Unsigned APT mirror | fix-log RT-002/RT-008; `docs/repo/dists/stable/` |
| PR-008 | P0 | pr-ready-report | Deferred | Apple firmware redistribution | fix-log LEG-002; counsel hold |
| PR-009 | High | pr-ready-report | Fixed | NEXUSOS_REPO redirect | fix-log RT-003/BE-007; `scripts/common.sh` allowlist |
| PR-010 | High | pr-ready-report | Partial | Installer tarball integrity | fix-log BE-002; `installer/run-installer.sh` |
| PR-011 | High | pr-ready-report | Fixed | ISO dual-boot overclaim | fix-log MR-001/002; GRUB + install-linux.sh |
| PR-012 | High | pr-ready-report | Partial | Legal docs not on user path | fix-log LEG-003/004; `chroot-setup.sh` legal copy |
| PR-013 | High | pr-ready-report | Fixed | CI soft gates | fix-log REQ-008/009; `validate.yml`, `release.yml` |
| PR-014 | High | pr-ready-report | Fixed | Preview vs stable branding | fix-log MR-001/002; `os-release` |
| REQ-001 | P0 | pr-ready-fix-log | Fixed | Bootstrap one-liner routing | README → `scripts/bootstrap.sh` |
| REQ-002 | P0 | pr-ready-fix-log | Fixed | APT Filename relative paths | `publish-repo.sh`, Packages |
| REQ-003 | P0 | pr-ready-fix-log | Partial | ISO kernel extraction / fail-if-missing | `build/iso/build-iso.sh` |
| REQ-004 | P0 | pr-ready-fix-log | Fixed | UTM virtio disk + Drives | `build/utm/build-utm.sh` |
| REQ-005 | High | pr-ready-fix-log | Deferred | Intel UTM x86 artifact | overload punch list |
| REQ-006 | High | pr-ready-fix-log | Deferred | ISO installer handler | overload punch list |
| REQ-007 | High | pr-ready-fix-log | Deferred | macOS CI stub installer | overload punch list |
| REQ-008 | High | pr-ready-fix-log | Fixed | ISO build no \|\| true in release.yml | `.github/workflows/release.yml` L77 |
| REQ-009 | Low | pr-ready-fix-log | Fixed | ShellCheck fails CI | `.github/workflows/validate.yml` |
| REQ-010 | Medium | pr-ready-fix-log | Deferred | Submodule init docs | overload punch list |
| REQ-011 | Medium | pr-ready-fix-log | Fixed | installer/build.sh syncs VERSION metadata | `installer/build.sh` sync_installer_metadata |
| REQ-015 | P0 | pr-ready-fix-log | Fixed | Random bootstrap password + expire | `chroot-setup.sh`, `nexus-welcome` |
| REQ-018 | High | pr-ready-fix-log | Fixed | verify_checksum fails closed | `scripts/common.sh` L68–90 |
| RT-001 | Critical | pr-ready-fix-log | Partial | Bootstrap clones repo; pipe-to-shell remains | `bootstrap.sh`, README |
| RT-002 | Critical | pr-ready-fix-log | Partial | Unsigned committed APT mirror | `docs/repo/dists/stable/` |
| RT-003 | High | pr-ready-fix-log | Fixed | NEXUSOS_REPO allowlist | `scripts/common.sh`, `install.ps1` |
| RT-004 | High | pr-ready-fix-log | Fixed | Checksum fail-closed | `scripts/common.sh` |
| RT-005 | High | pr-ready-fix-log | Fixed | Default credentials removed | `chroot-setup.sh` |
| RT-008 | Medium | pr-ready-fix-log | Partial | publish-repo signing gate in CI | `publish-repo.sh`, `release.yml` |
| RT-016 | Low | pr-ready-fix-log | Fixed | ShellCheck blocks CI | `validate.yml` |
| BE-001 | High | pr-ready-fix-log | Fixed | Default credentials | `chroot-setup.sh` |
| BE-002 | High | pr-ready-fix-log | Fixed | Installer tarball SHA256SUMS | `installer/run-installer.sh` L47–48 |
| BE-003 | High | pr-ready-fix-log | Fixed | verify_checksum fail-closed | `scripts/common.sh` |
| BE-004 | High | pr-ready-fix-log | Partial | Bootstrap hardening | `bootstrap.sh` |
| BE-007 | High | pr-ready-fix-log | Fixed | Removed sudo -E from run-installer | `installer/run-installer.sh` L100 |
| LEG-002 | P0 | pr-ready-fix-log | Deferred | Apple firmware counsel | legal-review LR-002 |
| LEG-003 | High | pr-ready-fix-log | Partial | Legal docs shipped | `chroot-setup.sh`, README links |
| LEG-004 | High | pr-ready-fix-log | Partial | Legal docs on user path | README + rootfs `/usr/share/nexusos/` |
| LEG-005 | High | pr-ready-fix-log | Fixed | Native install typed YES gate | `scripts/install-macos-asahi.sh` L29–30 |
| MR-001 | P0 | pr-ready-fix-log | Partial | os-release preview channel | `os-release`, chroot-setup CHANNEL split |
| MR-002 | P0 | pr-ready-fix-log | Partial | ISO/GRUB preview labels | `install-linux.sh`, `build-iso.sh` GRUB |
| LR-001 | P0 | legal-implementation-verify | Partial | GPL source-offer on shipped image | `chroot-setup.sh`, `docs/GPL_SOURCE_OFFER` |
| LR-002 | P0 | legal-implementation-verify | Partial | Apple firmware counsel gate | `install-macos-asahi.sh` risk copy |
| LR-003 | P0 | legal-implementation-verify | Implemented | README license split MIT vs artifacts | `README.md` License section |
| LR-004 | High | legal-implementation-verify | Partial | Legal links + on-system bundle | README, rootfs overlays |
| LR-005 | High | legal-implementation-verify | Implemented | AS-IS on install entrypoints | `install.sh`, `install.ps1`, install scripts |
| LR-006 | High | legal-implementation-verify | Implemented | Native typed YES risk gate | `install-macos-asahi.sh` |
| LR-007 | High | legal-implementation-verify | Partial | ISO dual-boot preview copy | `install-linux.sh`, GRUB |
| LR-008 | High | legal-implementation-verify | Partial | curl\|sh demotion / integrity warning | README vs `install.sh` usage |
| LR-009 | High | legal-implementation-verify | Implemented | Independence / non-affiliation in README | README L5 |
| LR-014 | High | legal-implementation-verify | Implemented | Debian SPI non-affiliation | `THIRD_PARTY_NOTICES.md` |
| LR-015 | High | legal-implementation-verify | Implemented | Package copyright metadata | `build/packages/build-debs.sh` |
| LR-016 | Medium | legal-implementation-verify | Implemented | Installer tarball checksum | `installer/run-installer.sh` |
| LR-021 | Medium | legal-implementation-verify | Implemented | install.ps1 repo allowlist | `install.ps1` L16–18 |
| LR-024 | Medium | legal-implementation-verify | Implemented | nexus-doctor not certification | `nexus-doctor` L8 |
| LR-025 | Medium | legal-implementation-verify | Implemented | nexus-store third-party disclaimer | `nexus-store` L78 |
| LR-027 | Medium | legal-implementation-verify | Implemented | Password expiry messaging | README, WSL script |
| LR-028 | Medium | legal-implementation-verify | Implemented | INTENDED_USE.md shipped | `chroot-setup.sh` |
| LR-035 | Info | legal-implementation-verify | Implemented | common.sh repo validation | `scripts/common.sh` |
| LR-036 | Info | legal-implementation-verify | Implemented | Credential hardening maintained | `chroot-setup.sh`, `nexus-welcome` |
| LR-037 | Info | legal-implementation-verify | Implemented | Bootstrap one-liner path | README |
| LR-038 | Info | legal-implementation-verify | Implemented | ISO real kernel / unavailable install | `build-iso.sh` |
| LR-039 | Info | legal-implementation-verify | Implemented | verify_checksum fail-closed | `scripts/common.sh` |
| LR-040 | Info | legal-implementation-verify | Implemented | DISCLAIMER trademarks cross-ref | `docs/DISCLAIMER.md` |
| GRG-hold | — | general-regression-report | Verified | 14 fix clusters holding; 0 regressions | `make validate` PASS |

## Counts by claimed_status

| claimed_status | count |
|----------------|------:|
| Fixed | 28 |
| Implemented | 18 |
| Partial | 18 |
| Deferred / Deferred-accepted | 8 |
| Verified (regression hold) | 1 |

## Parent next actions

1. Invoke report-claim-spotcheck
