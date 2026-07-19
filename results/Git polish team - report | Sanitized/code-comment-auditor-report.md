# Code Comment Auditor Report

**Project:** NexusOS  
**Date:** 2026-07-19  
**Diff scope:** PR #4 merged changes (35 files)

## Files commented

| File | Change |
|------|--------|
| `packages/nexus-welcome/bin/nexus-welcome` | Added comment explaining why `--non-interactive` is blocked when `force-password-change` is pending (red-team credential-rotation requirement) |
| `build/iso/build-iso.sh` | Added grub.cfg comment on preview install menu placeholder |

## Already adequate

- `scripts/common.sh` — `_validate_nexusos_repo` and `verify_checksum` have clear intent comments
- `installer/build.sh` — non-macOS stub path documented inline
- `build/utm/build-utm.sh` — UTM bundle structure comment present

## Skipped

No drive-by comments on self-explanatory shell helpers or legal doc prose.
