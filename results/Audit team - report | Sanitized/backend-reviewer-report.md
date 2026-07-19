SANITIZED public digest — secrets, spoilers, and PoC payloads removed.
Not a full-repro archive. For complete repros see unsanitized team folders (not published).

# Backend Reviewer Report — NexusOS Installer & Build Tooling

**Project:** NexusOS repository (`Aidiotic/Operating-system`)  
**Reviewer:** backend-reviewer subagent  
**Date:** 2026-07-19  
**Scope:** `install.sh`, `install.ps1`, `scripts/*`, `installer/*`, `build/*`, `packages/*/bin/*`, CI workflows (`.github/workflows/*`)

---

## Executive Summary

NexusOS is an installer/build-script–driven distribution with no long-running API server. The highest risks are **supply-chain integrity gaps** on remote downloads (installer tarballs, optional checksum verification, `curl|sh` bootstrap) and **shipped default credentials** (known default user/password pair) baked into every rootfs image. Several CI/release paths **fail open** (ISO build `|| true`, shellcheck `|| true`, unsigned APT repo fallback), which can publish broken or unverified artifacts to GitHub Releases and Pages.

**Ship blockers (must fix before production release):**

1. Hardcoded default password in shipped images (`chroot-setup.sh`)
2. Native installer tarball extracted and executed as root without checksum/signature verification
3. Checksum verification silently skipped when `SHA256SUMS` is missing or fails to download
4. CI publishes a non-functional Linux stub installer bundle to releases on non-macOS builds

**Untested areas:** Live staging environment unavailable; native Asahi installer upstream behavior not executed; WSL2 import flow not run on Windows host; release signing with production GPG secrets not validated in this review.

---

## Finding Counts by Severity

| Severity | Count |
|----------|------:|
| P0/Critical | 0 |
| High | 7 |
| Medium | 9 |
| Low | 4 |
| Info | 3 |
| **Total** | **23** |

---

## Entry Points Mapped

| Category | Files / Triggers |
|----------|------------------|
| Universal installer | `install.sh` → `scripts/detect-platform.sh` → platform scripts |
| Windows bootstrap | `install.ps1` → `install.sh --wsl` |
| curl\|sh bootstrap | `scripts/bootstrap.sh`, documented one-liner in `install.sh` |
| macOS native (Asahi) | `scripts/install-macos-asahi.sh` → `installer/run-installer.sh` / `installer/bootstrap-nexusos.sh` |
| WSL2 | `scripts/install-windows-wsl.sh` |
| UTM VM | `scripts/install-macos-utm.sh` |
| Rootfs / ISO build | `build/rootfs/build-*.sh`, `build/iso/build-iso.sh` |
| APT repo publish | `build/repo/publish-repo.sh` (CI: `publish-repo.yml`, `release.yml`) |
| Runtime CLIs | `packages/nexus-*/bin/*` |
| CI gates | `.github/workflows/validate.yml`, `release.yml` |

---

## Complete Findings

### BE-001 | High | Hardcoded default credentials in shipped rootfs

**Location:** `build/rootfs/chroot-setup.sh:57-58`, `scripts/install-windows-wsl.sh:101`, `build/utm/build-utm.sh:104`

**Evidence:**
```bash
chroot "$CHROOT" useradd -m -s /bin/bash -G sudo,adm,cdrom,dip,plugdev nexus || true
echo 'nexus:[REDACTED]' | chroot "$CHROOT" chpasswd || true
```
Default user is in `sudo` group with a known default password. Install scripts log the password to stdout.

**Repro:** Build rootfs, import to WSL, log in with default credentials without any forced password change (`nexus-welcome --non-interactive` skips password prompt).

**Suggested fix:** Generate a random one-time password at image build time (or force password set on first login before network enable). Do not log credentials. Consider removing password auth for default user until first-boot wizard completes. Fail build if `chpasswd` fails (`|| true` masks errors).

---

### BE-002 | High | Native installer tarball executed as root without integrity verification

**Location:** `installer/bootstrap-nexusos.sh:51-71`, `installer/run-installer.sh:43-49,94-98`

**Evidence:**
```bash
curl --fail --silent --show-error -L -o "$PKG" "${INSTALLER_BASE}/${PKG}"
tar xf "$PKG"
exec caffeinate -dis sudo -E ./install.sh "$@"
```
No SHA256SUMS check, no GPG signature, no TLS pinning beyond HTTPS. Compromised GitHub release or MITM yields arbitrary code execution as root during dual-boot install.

**Repro:** Compromised or tampered release asset; installer runs extracted `install.sh` with `sudo -E` without verification step.

**Suggested fix:** Ship signed checksums for installer tarballs; verify before `tar xf`. Prefer minisign/GPG detached signatures. Pin release version; do not trust `installer-latest` alone without signature.

---

### BE-003 | High | Checksum verification skipped when SHA256SUMS unavailable

**Location:** `scripts/common.sh:52-58`, `scripts/install-windows-wsl.sh:45-46`, `scripts/install-macos-utm.sh:49-50`

**Evidence:**
```bash
download_release "SHA256SUMS" "${tmp}/SHA256SUMS" || true
verify_checksum "${tmp}/${ARTIFACT}" "${tmp}/SHA256SUMS"
```
`verify_checksum` warns and returns 0 when sums file missing:
```bash
if [[ ! -f "$sums_file" ]]; then
  warn "No checksum file at $sums_file — skipping verification"
  return 0
fi
```

**Repro:** Block or corrupt `SHA256SUMS` download; rootfs/UTM artifact still installs after warning only.

**Suggested fix:** Fail closed: `die` if checksum file missing for release artifacts. Require checksum verification for all release downloads in installer paths.

---

### BE-004 | High | curl\|sh and irm\|iex remote execution patterns

**Location:** `install.sh:27`, `install.ps1:3-4`, `scripts/bootstrap.sh:1-37`

**Evidence:** README and installer help document pipe-to-shell one-liners (`curl … | sh`, `irm … | iex`) without integrity verification. `bootstrap.sh` clones or downloads repo then `exec ./install.sh` — designed for pipe-to-shell.

**Repro:** Compromise of default branch or untrusted network path; piped script runs with user privileges immediately.

**Suggested fix:** Document and prefer `git clone` + inspect + run. For one-liner, pin to a verified release tag, verify detached signature, or use release tarball with checksum. Never recommend piping to `sh`/`iex` without integrity checks.

---

### BE-005 | High | CI publishes non-macOS stub installer to releases

**Location:** `installer/build.sh:28-41`, `.github/workflows/release.yml:50-62,105-128`

**Evidence:**
```bash
if [[ "$(uname -s)" != "Darwin" ]]; then
  log "Not on macOS — creating metadata-only installer bundle for CI/releases."
  ...
  tar czf "${RELEASES}/${PKG}" -C "$STAGE" .
  exit 0
fi
```
`build-installer` job runs on `ubuntu-latest`; artifact is merged into GitHub Release. macOS users downloading `installer-*.tar.gz` may get a stub without m1n1/U-Boot boot chain.

**Repro:** Tag release; download `installer-1.0.0.tar.gz` from Releases; run on Apple Silicon Mac — lacks real Asahi installer binaries.

**Suggested fix:** Build installer only on `macos-latest` runner, or fail release if stub detected. Gate release job on macOS-built installer artifact.

---

### BE-006 | High | installer-latest version string used without validation

**Location:** `installer/bootstrap-nexusos.sh:44-51`, `installer/run-installer.sh:44-45`

**Evidence:**
```bash
PKG_VER="$(curl --fail --silent --show-error -L "$VERSION_FLAG" 2>/dev/null)"
PKG="installer-${PKG_VER}.tar.gz"
```
No sanitization for newlines, slashes, or shell metacharacters. Attacker controlling release file content could influence download path or cause unexpected filenames.

**Repro:** Publish malformed `installer-latest` (path traversal or control characters); observe path construction behavior.

**Suggested fix:** Validate `PKG_VER` against `^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$` before use. Reject whitespace/control characters.

---

### BE-007 | High | sudo -E preserves attacker-controlled environment into privileged installer

**Location:** `installer/bootstrap-nexusos.sh:71`, `installer/run-installer.sh:98`

**Evidence:**
```bash
exec caffeinate -dis sudo -E ./install.sh "$@"
exec sudo -E ./install.sh "$@"
```
`-E` preserves dynamic-linker, library-path, `PATH`, and other env vars from invoking user into root context unless sudoers restricts them.

**Repro:** Invoke installer bootstrap with attacker-controlled dynamic-linker environment variables; privileged child may inherit unsafe env.

**Suggested fix:** Use `sudo -H` without `-E`, or explicitly `env -i` with allowlisted variables. Clear `LD_*`/`DYLD_*` before exec.

---

### BE-008 | Medium | Shared fixed temp directory enables symlink/race attacks

**Location:** `installer/bootstrap-nexusos.sh:29-41`, `installer/run-installer.sh:13,28-29`, `.gitignore:19`

**Evidence:**
```bash
TMP="${NEXUSOS_INSTALLER_TMP:-/tmp/nexusos-install}"
mkdir -p "$TMP"
cd "$TMP"
```
World-writable `/tmp/nexusos-install` is predictable. Concurrent runs or a malicious local user could race `tar xf` or replace extracted files before `sudo ./install.sh`.

**Repro:** Concurrent or hostile local access to the fixed temp directory during extract-and-exec flow.

**Suggested fix:** Use `mktemp -d` with restrictive permissions (`chmod 700`). Never use fixed path under `/tmp` for root-install flows.

---

### BE-009 | Medium | NEXUSOS_REPO / NEXUSOS_VERSION env vars redirect all downloads without validation

**Location:** `scripts/common.sh:8-11`, `install.ps1:14`, `scripts/bootstrap.sh:7-8`

**Evidence:**
```bash
NEXUSOS_REPO="${NEXUSOS_REPO:-Aidiotic/Operating-system}"
NEXUSOS_GITHUB="https://github.com/${NEXUSOS_REPO}"
NEXUSOS_RELEASES="https://github.com/${NEXUSOS_REPO}/releases/download/v${NEXUSOS_VERSION}"
```
No format validation. Phishing docs can instruct users to set `NEXUSOS_REPO` to an untrusted slug and run installer.

**Repro:** Set `NEXUSOS_REPO` to an attacker-controlled GitHub slug before running `./install.sh` — all artifacts fetched from untrusted origin.

**Suggested fix:** Allowlist known repo slugs or require explicit `--mirror URL` flag with warning. Validate `NEXUSOS_VERSION` semver format.

---

### BE-010 | Medium | Installer metadata fetched from mutable main branch, not release artifact

**Location:** `installer/bootstrap-nexusos.sh:24-25,61-62`, `installer/run-installer.sh:21-22,47-48`

**Evidence:**
```bash
export INSTALLER_DATA="${GITHUB}/raw/main/installer/nexusos-installer-data.json"
```
Metadata (partition sizes, image filenames, repo URLs) can change independently of signed release tarball.

**Repro:** Push to `main` changing `nexusos-installer-data.json` partition requirements; users on older installer version pick up new metadata.

**Suggested fix:** Bundle `installer_data.json` inside signed release tarball only; remove raw/main fallback for production.

---

### BE-011 | Medium | ISO build ships placeholder kernel/initrd; CI swallows failure

**Location:** `build/iso/build-iso.sh:53-54`, `.github/workflows/release.yml:76`

**Evidence:**
```bash
# Placeholder kernel/initrd — real CI builds extract from rootfs
touch "$WORK/live/vmlinuz" "$WORK/live/initrd.img"
```
```yaml
- run: sudo ./build/iso/build-iso.sh || true
```
Release pipeline may upload non-bootable ISO without failing the workflow.

**Repro:** Run release workflow; download `nexusos-x86_64.iso`; attempt USB boot — empty kernel files.

**Suggested fix:** Extract real `vmlinuz`/`initrd` from rootfs or fail build. Remove `|| true` from release workflow; gate release on ISO smoke test.

---

### BE-012 | Medium | Unsigned APT repository published when GPG secrets absent

**Location:** `build/repo/publish-repo.sh:25-28`, `.github/workflows/publish-repo.yml:32-38`

**Evidence:**
```bash
if [[ -z "${NEXUSOS_APT_GPG_PRIVATE_KEY:-}" ]]; then
  log "No NEXUSOS_APT_GPG_PRIVATE_KEY — publishing unsigned Release (dev only)"
  return 0
fi
```
Workflow still deploys to GitHub Pages. Clients with `signed-by=` keyring may reject, but unsigned repo could be served if keyring misconfigured.

**Repro:** Run `publish-repo.sh` without secrets; observe unsigned `Release` deployed to `docs/repo/`.

**Suggested fix:** Fail CI if signing secrets missing on `main` deploy. Separate dev publish target from production Pages.

---

### BE-013 | Medium | Asahi third-party APT source uses [trusted=yes]

**Location:** `build/kernel/fetch-asahi-platform.sh:35-37,49`

**Evidence:**
```bash
deb [trusted=yes] ${ASAHI_REPO_URL} ${ASAHI_REPO_SUITE} main
```
Disables Debian package signature verification for Asahi repo packages installed into release rootfs.

**Repro:** Supply-chain compromise of Asahi mirror during rootfs build — arbitrary packages could be installed into image.

**Suggested fix:** Import and pin Asahi archive signing key; use `signed-by=` instead of `trusted=yes`. Verify package hashes where possible.

---

### BE-014 | Medium | shellcheck failures ignored in CI validation

**Location:** `.github/workflows/validate.yml:18-23`

**Evidence:**
```yaml
shellcheck -e SC1091,SC2034,SC2164 "$f" || true
```
Static analysis never fails the pipeline.

**Repro:** Introduce shellcheck error in `install.sh`; CI still passes.

**Suggested fix:** Remove `|| true`; fail on shellcheck errors (keep targeted `-e` suppressions per-file if needed).

---

### BE-015 | Medium | chpasswd/useradd failures silently ignored during image build

**Location:** `build/rootfs/chroot-setup.sh:57-58`

**Evidence:**
```bash
chroot "$CHROOT" useradd ... nexus || true
echo 'nexus:[REDACTED]' | chroot "$CHROOT" chpasswd || true
```
Build succeeds even if user account or password not set — unpredictable login state.

**Repro:** Simulate chroot failure during useradd; image still builds.

**Suggested fix:** Remove `|| true`; fail build on user provisioning errors.

---

### BE-016 | Medium | install.ps1 clones arbitrary repo from environment without verification

**Location:** `install.ps1:48-56`

**Evidence:**
```powershell
$Repo = if ($env:NEXUSOS_REPO) { $env:NEXUSOS_REPO } else { "Aidiotic/Operating-system" }
git clone --depth 1 "https://github.com/$Repo.git" $tmp
bash $installSh --wsl @args
```
User-controlled `$Repo` passed to git clone; no release-tag pinning or signature check.

**Repro:** Set `NEXUSOS_REPO` to an untrusted repository before running `install.ps1`.

**Suggested fix:** Hardcode default repo; require explicit `-Mirror` parameter for alternates with warning. Pin to release tag.

---

### BE-017 | Low | Default password printed to installer stdout

**Location:** `scripts/install-windows-wsl.sh:101`

**Evidence:**
```bash
log "Default user: nexus (password: [REDACTED] — change with passwd)"
```

**Repro:** Run WSL installer; password visible in terminal scrollback and logs.

**Suggested fix:** Direct users to first-boot wizard; never echo default password in logs.

---

### BE-018 | Low | nexus-settings disk cleanup removes all of /tmp globally

**Location:** `packages/nexus-settings/bin/nexus-settings:30`

**Evidence:**
```bash
sudo rm -rf /tmp/* 2>/dev/null || true
```
Affects all users' temp files on shared systems.

**Repro:** Run `nexus-settings cleanup` while another user has files in `/tmp`.

**Suggested fix:** Scope cleanup to user cache (`~/.cache`, `apt clean`) rather than global `/tmp/*`.

---

### BE-019 | Low | nexus-store install path does not validate package names

**Location:** `packages/nexus-store/bin/nexus-store:52-60,88`

**Evidence:**
```bash
install_package() {
  local pkg="$1"
  ...
  sudo apt-get install -y "$pkg"
}
```
While quoted (no direct shell injection), no allowlist/regex validation permits installing arbitrary apt packages including sensitive system packages if user is in sudoers.

**Repro:** `nexus-store install $(printf 'a%.0s' {1..500})` or install critical system packages interactively.

**Suggested fix:** Validate against catalog allowlist for `nexus-store install`; use `apt-get install --no-install-recommends` with package name regex `^[a-z0-9][a-z0-9+.-]*$`.

---

### BE-020 | Low | WSL import path controlled by NEXUSOS_WSL_PATH without validation

**Location:** `scripts/install-windows-wsl.sh:12,93`, `scripts/uninstall-windows-wsl.sh:8`

**Evidence:**
```bash
INSTALL_PATH="${NEXUSOS_WSL_PATH:-C:\\NexusOS}"
$wsl_cmd --import "$DISTRO_NAME" "$INSTALL_PATH" "${tmp}/${ARTIFACT}"
```

**Repro:** Set `NEXUSOS_WSL_PATH` to sensitive or network path; WSL writes distro data there.

**Suggested fix:** Validate path is local absolute path under user-approved locations; confirm with user before import.

---

### BE-021 | Info | curl\|sh one-liner promoted in installer help text

**Location:** `install.sh:26-27`

**Evidence:** Usage documents remote pipe execution as primary install method.

**Suggested fix:** Deprecate in favor of verified release download instructions.

---

### BE-022 | Info | HTTP (not HTTPS) Debian mirrors in build scripts

**Location:** `build/rootfs/common.sh:59-60`, `build/rootfs/build-x86_64.sh:16`

**Evidence:** `deb http://deb.debian.org/debian` — standard for Debian but MITM-vulnerable during image build.

**Suggested fix:** Use `https://deb.debian.org/debian` where debootstrap supports it.

---

### BE-023 | Info | Healthcheck does not validate installer download security properties

**Location:** `scripts/healthcheck.sh:1-56`

**Evidence:** Checks syntax, JSON, version sync — no tests for checksum enforcement, credential policy, or signed repo requirement.

**Suggested fix:** Add checks that `verify_checksum` fails closed, that default password is not literal `nexus` in chroot-setup (or is documented test-only), and that publish-repo requires signing on main.

---

## Checklist Coverage

| Item | Status | Notes |
|------|--------|-------|
| Authentication/authorization on sensitive routes | N/A | No HTTP API |
| Input validation | **Fail** | Env vars, package names, version strings unvalidated |
| Consistent error responses | Partial | `die()` used; many `\|\| true` swallow errors |
| Rate limiting | N/A | Local scripts |
| Idempotency (webhooks) | N/A | |
| Timeouts/retries for outbound calls | Partial | `curl --retry 3` in `download_release` only |
| Logging without PII | **Fail** | Default password logged |
| Background job failure handling | Partial | CI `|| true` masks failures |
| Config fail-closed in production | **Fail** | Unsigned repo, optional checksums |
| Path traversal / injection | Partial | Quoted vars; fixed `/tmp` paths risky |
| Health/readiness probes | N/A | `healthcheck.sh` for repo only |
| Graceful shutdown | N/A | |

---

## Recommended Priority Order

1. **BE-001, BE-003, BE-002** — Image credentials and download integrity (ship blockers)
2. **BE-005, BE-011** — Release pipeline correctness
3. **BE-004, BE-010, BE-006** — Supply chain hardening
4. **BE-007, BE-008** — Privilege escalation surface on macOS installer
5. **BE-012–BE-016** — CI and build hygiene
6. **BE-017–BE-020** — Runtime CLI hardening

---

---

*This report is a security and engineering review. It does not constitute legal advice, compliance certification, or counsel sign-off.*

*End of report*
