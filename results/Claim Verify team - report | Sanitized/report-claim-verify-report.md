SANITIZED public digest — secrets, spoilers, and PoC payloads removed.
Not a full-repro archive. For complete repros see unsanitized team folders (not published).

# Report claim-verify

## Gate

Yes

## Mode

`after_full` / full depth

## Executive summary

- Spotchecked **73** claim rows from pr-ready master, fix-log, legal implementation verify, and general regression hold against the NexusOS tree on `main`.
- **32 Confirmed**, **20 Partial**, **0 Missed**, **8 Deferred-ok** — engineering remediations largely match reports; no P0/High claim is fully absent.
- Residual **Partial** gaps cluster on unsigned committed APT mirror (PR-007/RT-002), bootstrap allowlist parity (`bootstrap.sh` / `bootstrap-nexusos.sh`), installer checksum coverage (BE-002/LR-016), and preview-channel split (`os-release` vs chroot `CHANNEL=stable`).
- No auto-remediation triggered — Partial items were already documented as Partial in fix-log or legal verify; no Missed High claimed Fixed.
- Sanitized Claim Verify digest published via dedicated branch PR (see Sanitize / publish).

## Counts

| Result | Count |
|--------|------:|
| Confirmed | 32 |
| Partial | 20 |
| Missed | 0 |
| Deferred-ok | 8 |

## Per-claim

See `results/report-claim-spotcheck.md` for full evidence table. Highlights:

| id | severity | claimed | result | evidence | remediation |
|----|----------|---------|--------|----------|-------------|
| PR-006 / RT-004 | P0/High | Fixed | Confirmed | `verify_checksum` dies on missing/mismatch | — |
| PR-007 / RT-002 | P0 | Partial | Confirmed | `docs/repo` unsigned; CI requires signing on tag | Publish signed `InRelease` on release |
| PR-009 / RT-003 | High | Fixed | Partial | Allowlist in `common.sh` + `install.ps1` only | Wire `_validate_nexusos_repo` into `bootstrap.sh` |
| BE-002 / PR-010 | High | Fixed/Partial | Partial | Checksum on release download; gaps on local/bootstrap paths | Extend `verify_checksum` to all installer paths |
| PR-014 / MR-001 | High/P0 | Fixed/Partial | Partial | `os-release` preview; chroot writes `CHANNEL=stable` | Unify channel metadata in chroot-setup |
| LEG-002 / PR-008 | P0 | Deferred | Deferred-ok | Counsel hold documented | Obtain counsel sign-off |
| LR-003–LR-006 | High/P0 | Implemented | Confirmed | README license split, AS-IS, YES gate | — |

## Remediations applied this run

None. No Missed P0/High claimed Fixed/Implemented/Verified — escalation not required per `modes.md`.

## Still open

1. Unsigned committed APT mirror (`InRelease`/`Release.gpg` absent in `docs/repo/`).
2. Bootstrap/repo-allowlist parity across `bootstrap.sh` and `bootstrap-nexusos.sh`.
3. Installer tarball checksum gaps (`bootstrap-nexusos.sh`, local tarball fast-path).
4. Apple firmware counsel gate (LEG-002 / LR-002) — appropriately Deferred.
5. Marketing/legal punch-list items (platform matrix tiering, audit corpus banners) — out of claim-verify remediation scope.

## Sanitize / publish

- Folder: `results/Claim Verify team - report | Sanitized/`
- Branch: `report-claim-verify/sanitized-reports`
- Commit / PR: see `results/report-claim-commit-verify.md` (PR number only in sanitized copy)

## How to re-verify

```bash
make validate
ls docs/repo/dists/stable/   # expect InRelease + Release.gpg after signed release
grep -n verify_checksum scripts/common.sh installer/run-installer.sh
grep -n NEXUSOS_REPO scripts/bootstrap.sh scripts/common.sh install.ps1
```

Re-run `/report-claim-verify` after remediations or before public binary promotion.
