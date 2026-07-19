SANITIZED public digest — secrets, spoilers, and PoC payloads removed.
Not a full-repro archive. For complete repros see unsanitized team folders (not published).

# Report Leak Scanner — Absolute Paths

**Date:** 2026-07-19  
**Project:** NexusOS (`Aidiotic/Operating-system`)  
**Author agent:** report-leak-scanner-paths  
**Severity scale:** P0 = must block public publish; P1 = advisory

---

## ID Glossary

| Prefix | Meaning |
|--------|---------|
| **RLP** | Report Leak Paths finding (absolute machine / home paths, `file://`) |

---

## Executive Summary

Initial path scan found **one P0 class** in the Audit team Sanitized digest: literal default-user-home paths in REQ-021 evidence. These matched publish-guard’s home-directory path pattern. **Fixer applied** — paths generalized to “default user home” wording. Re-scan and publish-guard now **Pass**.

---

## Method / Surfaces Scanned

| Surface | Scan result |
|---------|-------------|
| `results/Audit team - report \| Sanitized/**` | Initial Fail → fixed |
| `results/report-quality/**` | Contains `/Users/...` references in *audit findings about other reports* — gitignored, not publish scope |
| `results/*.md` (top-level) | Gitignored strict archives |
| `/Users/` machine paths in Sanitized trees | **None** (post-fix) |
| `file://` URIs in Sanitized trees | **None** |

**Tools:** `rg` for `/Users/`, `/home/`, `file://`; publish-guard PATH_PAT.

---

## Findings Table

| ID | Severity | Path | Leak kind | Evidence | Status |
|----|----------|------|-----------|----------|--------|
| RLP-001 | P0 | `results/Audit team - report \| Sanitized/requirements-auditor-report.md` | default-user-home absolute path | REQ-021 table + evidence block cited literal user-home `rm -rf` paths | **Fixed** |

---

## Per-Finding Detail

### RLP-001 | P0 | default-user-home path in Sanitized requirements digest

| Field | Detail |
|-------|--------|
| **Location** | `requirements-auditor-report.md` lines ~122, ~375–381 |
| **Leak kind** | Absolute home-directory path (publish-guard PATH_PAT) |
| **Initial evidence** | Factory-reset finding quoted literal nexus user home paths |
| **Risk** | Mechanical publish-guard Fail; potential host fingerprinting if combined with other paths |
| **Fix applied** | Replaced with “default user home” / generalized `rm -rf` description |
| **Re-scan** | home-path pattern scan on Sanitized folder → **0 matches**; publish-guard **PASS** |

---

## Recommended Remediations

1. Scrubber rule: replace literal home-directory paths with role-based labels (`default user home`, `<nexus-user-home>`) in all Sanitized digests.
2. Add README index to Sanitized folders (completed for Audit team).
3. Re-run publish-guard before any GitHub stage.

---

## Gate: Pass

P0 count: 0 (1 fixed)
