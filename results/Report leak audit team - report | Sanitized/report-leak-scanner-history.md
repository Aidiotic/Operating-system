SANITIZED public digest — secrets, spoilers, and PoC payloads removed.
Not a full-repro archive. For complete repros see unsanitized team folders (not published).

# Report Leak Scanner — History Pointers

**Date:** 2026-07-19  
**Project:** NexusOS (`Aidiotic/Operating-system`)  
**Author agent:** report-leak-scanner-history  
**Severity scale:** P0 = must block public publish; P1 = advisory

---

## ID Glossary

| Prefix | Meaning |
|--------|---------|
| **RLH** | Report Leak History finding (git SHA / history-pointer class) |

---

## Executive Summary

History-pointer scan of published-scope trees found **no P0 leaks**. No full 40-hex commit SHAs, no publish-log SHA tables, and no tracked `results/sanitized-publish-log.md` were present. GitHub history reachability probes against prior-publish refs returned **404** for known Strict report paths — residual history leak risk is **low**.

---

## Method / Surfaces Scanned

| Surface | Tracked? | Notes |
|---------|----------|-------|
| `results/Audit team - report \| Sanitized/**` | Untracked (candidate publish) | 5 files |
| `results/report-quality/**` | Gitignored | Local-only; not publish scope |
| `results/report-leak-audit/**` | Gitignored | Local-only audit workspace |
| `results/sanitized-publish-log.md` | Absent | Forbidden artifact not present |
| `git polish - reports/**` | Gitignored | Not present in index |
| GitHub `main` tree (3 commits) | Remote | No `results/` paths at tip |

**Tools:** `rg` (40-hex SHA pattern), `git ls-files results/`, `gh api` contents probes, `bash ~/.cursor/skills/pr-ready-publish-guard/guard.sh`.

---

## Findings Table

| ID | Severity | Path | Leak kind | Evidence | Suggested fix |
|----|----------|------|-----------|----------|---------------|
| — | — | — | — | No P0 history-pointer findings | — |

---

## Per-Finding Detail

No RLH findings. Scans for:

- Full 40-hex git SHAs in `results/*Sanitized*/**` → **none**
- “Commit SHA” / publish-log tables → **none**
- Tracked `results/sanitized-publish-log.md` → **absent**
- Tracked `git polish - reports/**` → **absent** (gitignored)

### History Reachability Probes

Probed GitHub Contents API for Strict paths at `prior-publish-sha-1` and `prior-publish-sha-2` (most recent non-initial commits on `main`):

| Path | prior-publish-sha-1 | prior-publish-sha-2 |
|------|---------------------|---------------------|
| `results/redteam-report.md` | 404 | 404 |
| `Red team reports/redteam-report.md` | 404 | 404 |
| `audit - reports/requirements-auditor-report.md` | 404 | 404 |
| `results/sanitized-publish-log.md` | 404 | 404 |

Recursive tree listing of `main` tip confirms **zero** `results/` paths ever served on GitHub.

### Publish-Guard (post-fixer)

`bash ~/.cursor/skills/pr-ready-publish-guard/guard.sh "results/Audit team - report | Sanitized"` → **PASS** (exit 0).

---

## Recommended Remediations

1. Keep `results/sanitized-publish-log.md` and `git polish - reports/` gitignored.
2. Never embed full commit SHAs in sanitized markdown or PR bodies; use PR numbers.
3. Re-probe history reachability if any future publish accidentally commits Strict trees.

---

## Gate: Pass

P0 count: 0
