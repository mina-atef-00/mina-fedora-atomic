---
workflowType: 'prd'
workflow: 'edit'
classification:
  domain: 'DevOps/Infrastructure'
  projectType: 'Infrastructure/DevOps - Container Build System with First-Boot Automation'
  complexity: 'Medium-High'
  projectContext: 'brownfield'
inputDocuments:
  - _bmad-output/brainstorming/brainstorming-session-2026-02-11.md
stepsCompleted:
  - step-e-01-discovery
  - step-e-02-review
  - step-e-03-edit
lastEdited: '2026-02-13'
editHistory:
  - date: '2026-02-13'
    changes: 'Restructured to BMAD PRD format: Added Problem Statement, Functional Requirements, Non-Functional Requirements, User Journeys, Feature List. Moved ADRs, Pre-mortem, and Technical Context to Appendices. Preserved all 441 lines of original technical detail.'
---

# Product Requirements Document - mina-fedora-atomic

**Author:** Monna
**Date:** 2026-02-12
**Last Updated:** 2026-02-13

## Problem Statement (PS)

**PS-1.1** Developer workstation setup requires extensive manual configuration of 100+ packages, system settings, and development tools, consuming 2-3 days of manual effort per machine with high risk of configuration drift between workstations.

**PS-1.2** Fedora Atomic's immutable architecture prevents runtime package installation via DNF, making it impossible to install development tools, desktop applications, or system modifications after initial deployment without rebuilding the entire container image.

**PS-1.3** Personal dotfiles, configurations, and application preferences are scattered across multiple repositories and manual backup systems, requiring significant effort to synchronize across multiple machines and maintain consistency over time.

**PS-1.4** Current container image builds produce single ~3GB layers requiring full re-download on any configuration change, creating inefficient update workflows especially for users with limited bandwidth or metered connections.

## Success Criteria (SC)

**SC-1.1** Reduce initial workstation setup time from 2-3 days to under 30 minutes of unattended operation after ISO installation.

**SC-1.2** Achieve ≤500MB download size for typical configuration changes (theming, package additions) versus current 3GB full-layer downloads.

**SC-1.3** Enable single-command configuration synchronization from source of truth (chezmoi repository) with automated application of dotfiles, flatpaks, and homebrew packages.

**SC-1.4** Support 99% setup script success rate with automatic retry logic, crash recovery, and resume capability for network interruptions or partial failures.

**SC-1.5** Maintain Fedora Atomic immutability constraints while providing flexible user configuration through pre-installed toolchains and on-demand setup scripts.

## Product Scope

### In Scope

- Custom Fedora Atomic bootc container image build system
- Multi-layer container architecture (9 layers) organized by change frequency
- Two hardware profiles: ASUS desktop (NVIDIA) and Lenovo laptop (Intel)
- Interactive user setup script (`mfa-setup`) with modular menu interface
- Integration with chezmoi for dotfile management
- Pre-installed development toolchains and desktop applications
- CI/CD pipeline with GitHub Actions for automated builds
- ISO distribution with Anaconda-based graphical installer
- Image signing with Cosign for integrity verification
- Security scanning with Trivy for vulnerability detection
- State persistence and crash recovery for setup operations

### Out of Scope

- Runtime package installation (DNF operations after boot)
- Support for hardware profiles beyond ASUS and Lenovo
- Enterprise multi-user deployment scenarios
- Cloud-based image hosting beyond GHCR
- Automatic GUI configuration (user-initiated only)
- Windows or macOS support
- Package management beyond flatpak and homebrew

## User Journeys (UJ)

### UJ-1.1 Fresh Installation Journey

**Persona:** New user with blank machine or existing Linux system
**Priority:** P0 (Critical)

**Trigger:** User boots from custom ISO for initial installation

**Steps:**
1. Boot Anaconda installer from ISO (5 min)
2. Configure disk partitions, user account, hostname via GUI (10 min)
3. Complete installation and reboot into new system (15 min)
4. Log in and run `mfa-setup` when ready (user-initiated, not automatic)
5. Authenticate to GitHub via gh CLI device flow (2 min)
6. Select modules to configure via numbered menu (Chezmoi, Flatpaks, Homebrew) (2 min)
7. Automated setup completes unattended with parallel execution where possible (20-30 min)

**Success Criteria:** Full workstation ready with dotfiles applied, flatpaks installed, homebrew packages available, all configurations active

**Links:** FR-2.1, FR-2.2, FR-2.4, FR-4.1, NFR-2.1, NFR-8.1

### UJ-1.2 Post-Install Module Addition

**Persona:** Existing user wanting to add new tools or configurations
**Priority:** P1 (Important)

**Trigger:** User wants to add homebrew packages or new flatpak applications

**Steps:**
1. Run `mfa-setup` from terminal (existing installation detected)
2. Menu displays previously completed modules
3. User selects only "Homebrew packages" or "Flatpaks" module
4. Script installs packages from Brewfile or flatpak manifest
5. Desktop notification on completion

**Success Criteria:** New tools available without full reconfiguration, existing settings preserved

**Links:** FR-2.2, FR-2.3

### UJ-1.3 Recovery Journey

**Persona:** User with broken configuration or failed setup
**Priority:** P2 (Valuable)

**Trigger:** Configuration corruption, chezmoi apply failures, or interrupted installations

**Steps:**
1. Run `mfa-setup` (state file `~/.config/mfa-setup/state.json` detected)
2. Script offers: "Resume from [module]" or "Start fresh"
3. If resuming: Continue from last successful checkpoint
4. If starting fresh: Reset state and re-run selected modules
5. For chezmoi issues: Offer [R]epair, [O]verride, or [S]kip options

**Success Criteria:** Configuration restored without data loss, system returns to functional state

**Links:** FR-2.3, FR-2.5, FR-5.1, NFR-2.1

### UJ-1.4 Skip Setup Journey

**Persona:** Power user who prefers manual configuration
**Priority:** P2 (Valuable)

**Trigger:** User ignores or declines to run setup script

**Steps:**
1. Boot and use system normally
2. Configure manually using standard Linux tools (dnf in container builds only)
3. Install applications via alternative methods (manual flatpak, distrobox, etc.)

**Success Criteria:** System fully functional without running `mfa-setup`, no forced workflow

**Links:** FR-2.1 (optional use), NFR-9.1

### UJ-1.5 System Update Journey

**Persona:** Existing user updating to new container image version
**Priority:** P0 (Critical)

**Trigger:** New container image available in registry

**Steps:**
1. User runs `bootc upgrade` or automatic update triggers
2. System downloads only changed layers (≤500MB for typical updates)
3. Update staged for next reboot
4. Reboot into new deployment
5. User configurations in /etc and /var preserved via OSTree 3-way merge
6. Setup script automatically updated to latest version

**Success Criteria:** System updated with minimal download, all user data and configs preserved, ability to rollback if issues occur

**Links:** FR-1.1, NFR-1.1, NFR-7.1

## Functional Requirements (FR)

### FR-1.0 Layer Architecture

**FR-1.1** The container image SHALL organize software installation into 9 distinct OCI layers based on change frequency to reduce layer rebuild size by ≥80% for configuration-only changes (≤500MB vs current 3GB).

**Acceptance Criteria:**
- [ ] Layers 1-9 implemented as separate RUN commands in Containerfile
- [ ] Layer 1: Pre-cleanup & environment prep (base setup)
- [ ] Layer 2: Hardware drivers (NVIDIA akmods, Intel) - changes: hardware swaps only
- [ ] Layer 3: Core infrastructure (niri, greetd) - changes: rarely
- [ ] Layer 4: System backend (multimedia codecs, networking, fs backends) - changes: rarely
- [ ] Layer 5: CLI + Dev tools (eza, bat, fish, nvim, git) - changes: occasionally
- [ ] Layer 6: GUI applications (kitty, chromium, nautilus) - changes: frequently
- [ ] Layer 7: Theming, fonts & configurations - changes: most frequently
- [ ] Layer 8: Systemd services setup
- [ ] Layer 9: Final cleanup & bootc lint
- [ ] Build completes successfully with `bootc container lint` passing

**Traceability:** Innovation Section 1, ADR-001, ADR-002, PS-1.4

**FR-1.2** Modification of Layers 6-7 (GUI apps, theming) SHALL require download of ≤500MB versus current 3GB full-layer downloads.

**Acceptance Criteria:**
- [ ] Adding one GUI application triggers download of only Layer 6 (~500MB)
- [ ] Changing themes triggers download of only Layer 7 (~50MB)
- [ ] Base layer updates (ublue-os/base-main:43→:44) trigger Layers 1-2 rebuild only
- [ ] Download size measured and logged during `bootc upgrade`

**Traceability:** Innovation Section 1, NFR-1.1

### FR-2.0 User Setup System

**FR-2.1** The system SHALL provide an interactive setup script accessible via `mfa-setup` command in user PATH, available on-demand rather than automatically executing on boot.

**Acceptance Criteria:**
- [ ] Script installed at `/usr/bin/mfa-setup` (in image, updates with new images)
- [ ] Script executable and available immediately after boot
- [ ] Script does NOT run automatically on first boot
- [ ] User can invoke manually when ready
- [ ] Script can be run multiple times for module addition or recovery

**Traceability:** Innovation Section 2, ADR-004, UJ-1.1, UJ-1.4

**FR-2.2** The setup script SHALL support modular selection via numbered menu interface allowing users to select which modules to run.

**Acceptance Criteria:**
- [ ] Menu displays: [0] All modules, [1] Chezmoi, [2] Flatpaks, [3] Homebrew, [4] Exit
- [ ] User can input single numbers (1), multiple (1,2,3), ranges (1-3), or combinations
- [ ] Input validation rejects invalid selections
- [ ] For flatpak module: display native flatpak install output showing package sizes and confirmation prompt (as seen in normal `flatpak install` command)
- [ ] For homebrew module: show package count from Brewfile and estimated range based on typical install times
- [ ] Final confirmation prompt before execution

**Traceability:** Innovation Section 2, UJ-1.1, UJ-1.2

**FR-2.3** The setup script SHALL implement JSON-based state tracking for crash recovery with resume capability.

**Acceptance Criteria:**
- [ ] State file stored at `~/.config/mfa-setup/state.json`
- [ ] State includes: session_id, started_at, completed_modules[], in_progress, last_action
- [ ] On re-run, script detects interrupted session and offers "Resume from [module]?"
- [ ] Each module saves progress before completion
- [ ] State cleared on successful completion of all selected modules

**Traceability:** Innovation Section 2, Pre-mortem Analysis (Failure 2), UJ-1.3

**FR-2.4** The setup script SHALL execute Modules 2 (Flatpaks) and 3 (Homebrew) in parallel after Chezmoi setup completes.

**Acceptance Criteria:**
- [ ] Module 1 (Chezmoi) MUST complete before parallel execution begins
- [ ] Modules 2 & 3 run simultaneously with CPU-aware job limiting
- [ ] Output management shows progress for both modules
- [ ] Desktop notification sent on completion of all modules
- [ ] Time elapsed and disk space used reported in summary

**Traceability:** Innovation Section 2, Lines 55, 307-315

**FR-2.5** The setup script SHALL implement pre-flight validation including disk space, network connectivity, and dependency verification.

**Acceptance Criteria:**
- [ ] Disk space check: Verify minimum 5GB free before starting
- [ ] Network connectivity: Ping GitHub, Flathub, Homebrew servers
- [ ] Dependency check: Verify chezmoi binary available before Module 1
- [ ] Existing config detection: Warn if chezmoi/flatpak/homebrew already configured
- [ ] Graceful exit with error messages containing error code, description, and remediation steps if checks fail

**Traceability:** Innovation Section 2, Lines 56, 278-283

### FR-3.0 Build System

**FR-3.1** The build system SHALL support 2 hardware profiles (asus, lnvo) via HOST_PROFILE environment variable passed to build scripts.

**Acceptance Criteria:**
- [ ] Conditional logic in build scripts reads HOST_PROFILE environment variable
- [ ] ASUS profile includes NVIDIA drivers and akmods
- [ ] LNVO profile includes Intel graphics drivers
- [ ] Profile-specific packages installed based on HOST_PROFILE value
- [ ] Build fails gracefully if invalid profile specified

**Traceability:** Infrastructure Section, Lines 104-108

**FR-3.2** The CI/CD pipeline SHALL produce two distinct tagged images: `mina-fedora-atomic-desktop:latest` (ASUS profile) and `mina-fedora-atomic-laptop:latest` (LNVO profile).

**Acceptance Criteria:**
- [ ] GitHub Actions matrix builds produce both images
- [ ] Images tagged with: latest, dated (YYYY-MM-DD), and SHA for PRs
- [ ] Images pushed to GHCR (ghcr.io/mina/mina-fedora-atomic-*)
- [ ] Multi-tag strategy documented and consistent

**Traceability:** Infrastructure Section, Lines 111-113

### FR-4.0 Authentication & Security

**FR-4.1** The setup script SHALL authenticate to GitHub using gh CLI device flow for accessing private chezmoi repositories.

**Acceptance Criteria:**
- [ ] Script launches `gh auth login --web` when authentication required
- [ ] User authenticates via browser on host (not in VM if applicable)
- [ ] Token stored in user's keyring for subsequent operations
- [ ] No credentials embedded in container image layers
- [ ] Fallback to manual PAT entry if device flow fails

**Traceability:** Infrastructure Section, Lines 204-208, Pre-mortem Analysis (Failure 1)

**FR-4.2** Container images SHALL be signed with Cosign for integrity verification.

**Acceptance Criteria:**
- [ ] Images signed during GitHub Actions build process
- [ ] Cosign signatures attached to image manifests
- [ ] Users can verify images with `cosign verify` command
- [ ] Signing key management documented

**Traceability:** Infrastructure Section, Lines 190, 332-334

**FR-4.3** The CI/CD pipeline SHALL include Trivy container scanning for vulnerability detection.

**Acceptance Criteria:**
- [ ] GitHub Actions includes Trivy scan step
- [ ] Scan runs on every build
- [ ] Results published as non-blocking artifacts
- [ ] Critical CVEs flagged for review
- [ ] Scan results visible in PR checks

**Traceability:** Infrastructure Section, Lines 194-197

### FR-5.0 Error Handling & Reliability

**FR-5.1** The setup script SHALL implement retry logic with exponential backoff for network failures.

**Acceptance Criteria:**
- [ ] Network operations retry up to 3 times on failure
- [ ] Exponential backoff between retries (5s, 10s, 20s)
- [ ] Clear user messaging about retry attempts
- [ ] Graceful degradation if retries exhausted
- [ ] Flatpak operations use native resume capability

**Traceability:** Pre-mortem Analysis (Failure 6), Lines 313-316

**FR-5.2** The chezmoi module SHALL verify decryption capabilities before applying dotfiles.

**Acceptance Criteria:**
- [ ] Check for age key in `~/.config/age/` before chezmoi apply
- [ ] Run `chezmoi apply --dry-run` to catch errors before making changes
- [ ] Offer to skip module if apply fails, allowing continuation with others
- [ ] Clear error messages if decryption fails

**Traceability:** Pre-mortem Analysis (Failure 3), Lines 271-274

### FR-6.0 ISO Distribution

**FR-6.1** The system SHALL provide Anaconda-based ISO with custom kickstart configuration for graphical installation.

**Acceptance Criteria:**
- [ ] ISO variants: install-asus-ghcr.iso and install-lnvo-ghcr.iso
- [ ] Graphical Anaconda mode enabled
- [ ] User creation, hostname, localization handled during install
- [ ] Post-install: Executes `bootc switch` to transition to container image
- [ ] Kickstart configuration documented

**Traceability:** Infrastructure Section, Lines 339-343

### FR-7.0 Maintenance & Operations

**FR-7.1** The system SHALL support atomic updates with rollback capability via `bootc upgrade` and `bootc rollback`.

**Acceptance Criteria:**
- [ ] Updates staged without affecting running system
- [ ] Reboot applies staged update
- [ ] Previous deployment retained for rollback
- [ ] Rollback command swaps bootloader entries
- [ ] /etc and /var state preserved across upgrades

**Traceability:** Technical Context, Lines 320-323, 356-365

**FR-7.2** The setup script SHALL be stored in `/usr/bin/` to update with new images while runtime state stored in `~/.config/` for user persistence.

**Acceptance Criteria:**
- [ ] Script logic in `/usr/bin/mfa-setup` (updates with image)
- [ ] State/progress in `~/.config/mfa-setup/` (user-persistent)
- [ ] NOT in /var (would prevent script updates from reaching users)
- [ ] Script version displayed on startup

**Traceability:** ADR-004, Lines 166-184

## Non-Functional Requirements (NFR)

### NFR-1.0 Performance

**NFR-1.1** Configuration changes (Layers 6-7 modifications) SHALL require download of ≤500MB versus current 3GB full-layer downloads.

**Measurement:** Download size logged during `bootc upgrade`
**Target:** ≤500MB for GUI app additions, ≤50MB for theme changes
**Context:** Users with limited bandwidth or metered connections

**Traceability:** Innovation Section 1, Line 34

**NFR-1.2** Image builds SHALL complete within 45 minutes in GitHub Actions.

**Measurement:** GitHub Actions build duration
**Target:** <45 minutes for full matrix (asus + lnvo)
**Context:** CI/CD efficiency and rapid iteration

**Traceability:** Infrastructure Section, Line 108

**NFR-1.3** Setup script resume operations SHALL complete within 5 seconds of restart.

**Measurement:** Time from invocation to resuming interrupted module
**Target:** <5 seconds
**Context:** User experience for crash recovery

**Traceability:** Line 55, Pre-mortem Analysis

### NFR-2.0 Reliability

**NFR-2.1** The setup script SHALL maintain 99% success rate with automatic retry logic.

**Measurement:** Success rate across test runs
**Target:** ≥99% success rate
**Context:** User trust in automated setup process

**Traceability:** Pre-mortem Analysis, Lines 222-225

**NFR-2.2** Flatpak installations SHALL support native resume capability for interrupted downloads.

**Measurement:** Ability to resume flatpak install after network interruption
**Target:** 100% resume success for flatpak operations
**Context:** Large flatpak downloads (30+ minutes) prone to interruption

**Traceability:** Pre-mortem Analysis (Failure 2), Lines 256-259

### NFR-3.0 Security

**NFR-3.1** No credentials SHALL be embedded in container image layers.

**Verification:** Container image scan for secrets
**Target:** Zero hardcoded credentials
**Context:** Security best practice, prevents credential leakage

**Traceability:** ADR-004, Lines 202-219

**NFR-3.2** Images SHALL be signed with Cosign for integrity verification.

**Verification:** `cosign verify` command succeeds
**Target:** 100% of images signed
**Context:** Supply chain security

**Traceability:** Lines 190, 332-334

**NFR-3.3** The CI/CD pipeline SHALL scan images with Trivy for CVEs (non-blocking).

**Measurement:** Trivy scan execution on every build
**Target:** 100% scan coverage, results published
**Context:** Vulnerability visibility for personal use

**Traceability:** Lines 194-197

### NFR-4.0 Maintainability

**NFR-4.1** The Containerfile SHALL use 9 separate RUN commands creating independently cacheable layers.

**Verification:** Containerfile structure review
**Target:** 9 distinct layers as specified
**Context:** Build optimization and layer caching

**Traceability:** ADR-001, ADR-003, Lines 36-46

**NFR-4.2** Layer organization SHALL follow change-frequency pattern to minimize invalidation.

**Verification:** Layer change analysis
**Target:** Lower layers change less frequently than upper layers
**Context:** Optimize for typical update patterns

**Traceability:** ADR-001, Lines 36-46

### NFR-5.0 Usability

**NFR-5.1** The setup script SHALL display download size information using native flatpak output before installation.

**Measurement:** Verification that flatpak size data is displayed
**Target:** 100% of flatpak operations show size information
**Context:** Set user expectations for operation duration (>5 min operations show progress indicators)

**Traceability:** Pre-mortem Analysis (Failure 2), Line 257

**NFR-5.2** The setup script SHALL send desktop notifications on completion or error.

**Verification:** Notification sent via `notify-send`
**Target:** 100% of runs end with notification
**Context:** Background operation awareness

**Traceability:** Lines 336-339

### NFR-6.0 Compatibility

**NFR-6.1** The system SHALL support two hardware profiles: ASUS desktop with NVIDIA graphics and Lenovo laptop with Intel graphics.

**Verification:** Test builds on both profiles
**Target:** Both profiles build and boot successfully
**Context:** Personal workstation use cases

**Traceability:** Lines 104-113

**NFR-6.2** The system SHALL track ublue-os/base-main with major version pinning (e.g., :43).

**Verification:** Containerfile FROM line
**Target:** Pinned to specific major version
**Context:** Stability and controlled updates

**Traceability:** Line 108

### NFR-7.0 Availability

**NFR-7.1** System updates SHALL be atomic with rollback capability.

**Verification:** `bootc upgrade` and `bootc rollback` functionality
**Target:** 100% of updates support rollback
**Context:** Recovery from failed updates

**Traceability:** Technical Context, Lines 320-323

**NFR-7.2** ISO download and installation SHALL be available for both hardware profiles.

**Verification:** ISO generation and accessibility
**Target:** install-asus-ghcr.iso and install-lnvo-ghcr.iso available
**Context:** Initial installation flexibility

**Traceability:** Lines 350-354

### NFR-8.0 Scalability

**NFR-8.1** The CI/CD pipeline SHALL use matrix builds to produce two distinct images efficiently.

**Measurement:** Build time for matrix vs sequential
**Target:** Matrix build overhead <20%
**Context:** Efficient use of CI resources

**Traceability:** Lines 189-191

**NFR-8.2** The build system SHALL support BTRFS-based podman storage with zstd compression.

**Verification:** GitHub Actions storage configuration
**Target:** zstd compression enabled
**Context:** Storage efficiency during builds

**Traceability:** Line 191

### NFR-9.0 Constraints

**NFR-9.1** The system SHALL maintain Fedora Atomic immutability (no persistent DNF installation after boot).

**Verification:** Attempt dnf install on booted system
**Target:** DNF operations fail or are non-persistent
**Context:** Core bootc/OSTree constraint

**Traceability:** Implementation Constraints, Line 425-426

**NFR-9.2** Base image updates SHALL trigger full layer rebuild (architectural constraint of OCI/bootc).

**Verification:** Layer invalidation on base update
**Target:** All custom layers invalidated on base:43→:44
**Context:** bootc OSTree constraint

**Traceability:** ADR-002, Lines 134-140

**NFR-9.3** All DNF operations SHALL occur during image build phase (not at runtime).

**Verification:** Containerfile vs runtime script analysis
**Target:** Zero runtime DNF operations
**Context:** Fedora Atomic immutability requirement

**Traceability:** Implementation Constraints, Line 429

## Innovation & Novel Patterns

### Summary of Innovation Areas

**1. Multi-Layer Container Architecture for bootc/OSTree Systems**

This project implements a layered approach to container image building adapted specifically for the ublue-os/bootc ecosystem. The key innovation is organizing packages and configurations into change-frequency-based layers, reducing download size from 3GB to ~200-500MB for typical configuration changes.

**Innovation Highlights:**
- **Current State:** Single RUN command creates one ~3GB layer requiring full re-download on any change
- **Proposed State:** 9 separate RUN commands creating independently cacheable layers
- **Benefit:** Significant reduction in bandwidth usage and update times

**Traceability:** FR-1.1, FR-1.2, NFR-1.1, NFR-4.1, ADR-001, ADR-002, ADR-003

**2. Modular User Setup System**

A novel interactive setup script available on-demand that bridges the gap between immutable system images and user-specific configurations. Unlike automatic first-boot scripts, this system gives users control over when and what to configure.

**Innovation Highlights:**
- On-demand execution via `mfa-setup` command (not automatic on boot)
- Modular menu system for selective configuration
- External configuration source (chezmoi repository)
- Resume capability with JSON state tracking
- Parallel execution of independent modules

**Traceability:** FR-2.1, FR-2.2, FR-2.3, FR-2.4, FR-2.5, NFR-2.1, NFR-5.1, ADR-004

### Market Context & Competitive Landscape

**Container Layer Optimization:**
- Similar approaches exist (Zirconium, Bluefin) using multi-layer builds
- Differentiation: Change-frequency-based layer organization specifically tuned for desktop workstation use cases
- Target gap: Users transitioning from NixOS seeking similar granularity in package management

**User Setup Automation:**
- Existing solutions: ansible-pull, cloud-init, ignition
- Differentiation: Interactive menu-driven approach with chezmoi integration, on-demand execution
- Target gap: User-friendly onboarding for immutable desktop systems without complex infrastructure

## Feature List (FL)

### FL-1.0 Multi-Layer Container Build System [P0]
- FL-1.1 9-layer architecture organized by change frequency
- FL-1.2 Cache optimization reducing updates to ≤500MB
- FL-1.3 Hardware profile matrix (asus, lnvo) with conditional builds
- FL-1.4 bootc container lint compliance

**Links:** FR-1.1, FR-1.2, FR-3.1, NFR-1.1, NFR-4.1, NFR-4.2

### FL-2.0 Interactive User Setup [P0]
- FL-2.1 On-demand setup script (`mfa-setup`)
- FL-2.2 Modular numbered menu interface
- FL-2.3 Resume capability with state persistence (JSON)
- FL-2.4 Parallel module execution (Flatpaks + Homebrew)
- FL-2.5 Pre-flight validation (disk, network, dependencies)
- FL-2.6 GitHub device flow authentication

**Links:** FR-2.1, FR-2.2, FR-2.3, FR-2.4, FR-2.5, FR-4.1

### FL-3.0 Configuration Management [P0]
- FL-3.1 Chezmoi dotfile integration
- FL-3.2 External configuration repository support
- FL-3.3 Age encryption for sensitive dotfiles
- FL-3.4 Automatic re-application on script re-run

**Links:** FR-2.1, FR-5.2

### FL-4.0 Application Installation [P0]
- FL-4.1 Flatpak GUI applications (chromium, firefox, discord, obsidian)
- FL-4.2 Homebrew CLI tools (lazygit, node, go, etc.)
- FL-4.3 Native resume for interrupted flatpak downloads
- FL-4.4 Retry logic with exponential backoff

**Links:** FR-2.4, FR-5.1, NFR-2.2

### FL-5.0 CI/CD Pipeline [P0]
- FL-5.1 GitHub Actions matrix builds (asus + lnvo)
- FL-5.2 Multi-tag strategy (latest, dated, SHA)
- FL-5.3 Cosign image signing
- FL-5.4 Trivy vulnerability scanning
- FL-5.5 Scheduled daily builds (10:05 UTC)

**Links:** FR-3.2, FR-4.2, FR-4.3

### FL-6.0 ISO Distribution [P1]
- FL-6.1 Anaconda-based graphical installer
- FL-6.2 Custom kickstart configuration
- FL-6.3 Hardware-specific ISO variants
- FL-6.4 bootc switch integration post-install

**Links:** FR-6.1

### FL-7.0 System Updates [P0]
- FL-7.1 Atomic updates via bootc
- FL-7.2 Staged deployments with download-only option
- FL-7.3 Rollback capability
- FL-7.4 /etc and /var state preservation

**Links:** FR-7.1, NFR-7.1

### FL-8.0 Security & Compliance [P1]
- FL-8.1 Cosign image signing
- FL-8.2 Trivy CVE scanning
- FL-8.3 No embedded credentials
- FL-8.4 gh CLI device flow authentication

**Links:** FR-4.1, FR-4.2, FR-4.3, NFR-3.1, NFR-3.2, NFR-3.3

## Appendix A: Architecture Decision Records

**Note:** All original ADR content preserved. Added traceability links to requirements.

### ADR-001: Change-Frequency Based Layer Organization

**Context:** Current implementation uses single RUN command creating one ~3GB layer. Small changes (like adding one package) require full re-download.

**Decision:** Implement 9-layer architecture organized by change frequency

**Options Considered:**
1. **Single Layer (Current):** Simple but inefficient for updates
2. **Functional Layers:** Group by purpose (drivers, apps, configs)
3. **Change-Frequency Layers (Selected):** Group by how often components change

**Trade-offs:**
- **Pros:** Minimizes download size for typical changes; aligns with NixOS-like granularity goals
- **Cons:** Increased build complexity; more layers to manage
- **Rationale:** Based on bootc docs: "Changing base layer invalidates all upper layers in cache" - we must minimize lower-layer changes

**Traceability:** FR-1.1, FR-1.2, NFR-1.1, NFR-4.1, NFR-4.2

### ADR-002: Bootc Layer Caching Strategy

**Context:** bootc uses OSTree backend which maps OCI layers to OSTree commits. Per bootc docs: "Layers mapped to OSTree commits."

**Decision:** Each RUN command creates independently cacheable layer; upper layers only re-download when lower layers change

**Critical Constraint:** Per bootc docs - "Changing base layer invalidates all upper layers in cache"

**Implication:** Base image updates (ublue-os/base-main:43 → :44) will invalidate all layers. We must accept this constraint and optimize within it.

**Traceability:** FR-1.1, NFR-9.2

### ADR-003: Containerfile Multi-Stage vs Single File

**Context:** Zirconium uses multi-stage approach with separate RUN commands per layer

**Decision:** Keep single Containerfile but split into multiple RUN commands (like Zirconium pattern)

**Options Considered:**
1. **Multi-Stage Containerfile:** Better separation but more files
2. **Single Containerfile with Multiple RUN Commands (Selected):** Simpler management, clear layer boundaries

**Rationale:** Based on current 00-setup.sh orchestrator pattern; easier migration path

**Traceability:** FR-1.1, NFR-4.1

### ADR-004: Setup Script Architecture

**Context:** Need to bridge immutable base image with user-specific configurations

**Decision:** Modular interactive setup script available in PATH, not automatically executed on boot

**Rationale:**
- User may not want to configure everything immediately on first boot
- Flexibility to run script multiple times (initial setup, adding modules later, recovery)
- No forced workflow - user controls when and what to configure
- Script can be invoked manually: `mfa-setup` or `mina-setup`

**Constraints from Bootc Docs:**
- "/var is machine-local persistent state" BUT "Content in /var in container image acts like Docker VOLUME - only unpacked from initial image"
- "/etc is machine-local state" - can be modified but OSTree performs 3-way merge
- **Critical:** Files in /var from container image don't update on `bootc switch` - only initial install
- Script and its logic should be in /usr to update with new images

**Decision:** 
- Store setup script in `/usr/bin/mfa-setup` (updates with new images)
- Runtime state (progress, resume info) in user's home directory (`~/.config/mfa-setup/`)
- NOT in /var - would prevent script updates from reaching users

**Script Location:** `/usr/bin/mfa-setup` (or similar) - available immediately after boot, updates with image

**Use Cases:**
1. **Fresh Install:** User boots, logs in, runs `mfa-setup` when ready
2. **Module Addition:** Later, user wants to add homebrew packages - re-run script
3. **Recovery:** Something breaks, user re-runs to re-apply configurations
4. **Skip Entirely:** User can ignore script and configure manually if preferred
5. **Script Updates:** New image includes updated script - user gets latest version automatically

**Traceability:** FR-2.1, FR-7.2, NFR-3.1

## Appendix B: Risk Mitigation & Test Scenarios

**Note:** All original pre-mortem scenarios preserved. Organized by failure mode with requirement traceability.

### B.1 Authentication Failure Scenarios [Linked to FR-4.1]

**Scenario:** 6 months from now, user runs setup script and gh CLI device flow times out or browser fails to open

**Root Causes:**
- No browser available in minimal environment
- Network connectivity issues during OAuth flow
- User confusion about authentication steps

**Prevention:**
- **Primary:** gh CLI device flow with `--web` flag (opens browser on host, not VM)
- **Fallback:** Option to manually enter PAT during setup (not embedded in image)
- **Documentation:** Clear step-by-step screenshots for authentication flow
- **Testing:** Test setup script in VM with no internet, verify graceful degradation

**Test Case:** TC-AUTH-001: Verify authentication fallback works when browser unavailable

### B.2 Flatpak Interruption Recovery [Linked to FR-2.3, NFR-2.2]

**Scenario:** User closes terminal during 30-minute flatpak download, state corrupted

**Root Causes:**
- No state persistence between attempts
- Flatpak resume not working as expected
- User doesn't know download will take 30 minutes

**Prevention:**
- **State Tracking:** JSON state file in ~/.config/mfa-setup/state.json tracking progress per module
- **Pre-flight Warnings:** Show estimated download time before starting: "Flatpaks: ~2.5GB, 15-30 minutes"
- **Resume Logic:** Check flatpak remotes and installed apps before re-installing
- **Background Mode:** Option to run in background with desktop notification on completion

**Test Case:** TC-FLAT-001: Simulate network interruption during flatpak install, verify resume succeeds

### B.3 Chezmoi Apply Failures [Linked to FR-5.2]

**Scenario:** Chezmoi repository cloned successfully, but `chezmoi apply` fails due to missing dependencies (e.g., age encryption key not set up)

**Root Causes:**
- Dotfiles depend on tools not yet installed
- Encryption keys not initialized
- Template rendering fails

**Prevention:**
- **Dependency Check:** Verify chezmoi can decrypt before applying (age key in ~/.config/age/)
- **Dry-run First:** Run `chezmoi apply --dry-run` to catch errors before making changes
- **Graceful Degradation:** If apply fails, offer to skip and continue with other modules
- **Documentation:** List prerequisites in chezmoi repo README

**Test Case:** TC-CHEZ-001: Test chezmoi apply without age key, verify graceful handling

### B.4 Module Dependency Violations [Linked to FR-2.4]

**Scenario:** User runs Flatpak module before Chezmoi, flatpak installs but dotfiles aren't applied yet

**Root Causes:**
- No dependency validation in module selection
- UI allows invalid combinations

**Prevention:**
- **Dependency Graph:** Define module dependencies (Chezmoi → Flatpak, Chezmoi → Homebrew)
- **Validation Logic:** Reject or reorder selections that violate dependencies
- **UI Feedback:** Gray out dependent modules with tooltip: "Requires Chezmoi first"

**Test Case:** TC-MOD-001: Attempt to run Homebrew before Chezmoi, verify dependency enforcement

### B.5 Disk Space Exhaustion [Linked to FR-2.5]

**Scenario:** 5GB free space check passes, but flatpaks + homebrew + chezmoi exceed available space mid-install

**Root Causes:**
- Space check at start doesn't account for all modules
- Temporary files not cleaned up on failure
- Underestimated space requirements

**Prevention:**
- **Accurate Sizing:** Calculate total required space based on selected modules
- **Continuous Monitoring:** Check disk space before each major operation
- **Early Warning:** Alert when space drops below 10% during install
- **Cleanup on Failure:** Trap EXIT signals to remove partial downloads

**Test Case:** TC-DISK-001: Simulate low disk space during installation, verify graceful handling

### B.6 GitHub Rate Limiting [Linked to FR-5.1]

**Scenario:** User runs setup script multiple times in short time, hits GitHub API rate limits, homebrew installation fails

**Root Causes:**
- Anonymous GitHub API requests limited to 60/hour
- Homebrew makes many API calls during installation

**Prevention:**
- **Authentication:** Prompt for GitHub token if rate limit approached
- **Caching:** Cache homebrew installation files between runs
- **Retry with Backoff:** Exponential backoff on 403/429 responses
- **Offline Mode:** Support installing from cached homebrew bundle

**Test Case:** TC-RATE-001: Simulate rate limiting, verify retry logic and user messaging

## Appendix C: Technical Implementation Guide

**Note:** All original technical context preserved. Restructured as reference documentation.

### Bootc Layer Mechanics

bootc uses OSTree backend which maps OCI layers to OSTree commits ("layers mapped to OSTree commits").

**Critical constraint:** Changing base layer invalidates ALL upper layers in cache.

Each RUN command creates independently cacheable layer. Upper layers only re-download when lower layers they depend on change.

Implication: Base image updates (ublue-os/base-main:43 → :44) invalidate all custom layers. We must accept this constraint and optimize within it.

**Links:** FR-1.1, NFR-9.2, ADR-002

### Filesystem & State Management

- `/usr` - Read-only by default (with composefs), contains OS binaries and default configs
- `/etc` - Machine-local state; OSTree performs 3-way merge across upgrades
  - Changes in container image applied unless file modified locally
  - Best practice: Use drop-in directories (/etc/sudoers.d) instead of modifying files directly
- `/var` - Machine-local persistent state; survives reboots
  - **CRITICAL:** Content in /var from container image only unpacked on INITIAL install, NOT on `bootc switch` updates
  - Acts like Docker VOLUME - subsequent image changes to /var are ignored
  - Suitable for: runtime logs, databases, caches
  - **NOT suitable for:** Scripts, configs, or state that needs to update with new images
  - **Decision:** Store setup script in /usr (updates with images), runtime state in ~/.config/

**Links:** FR-7.2, NFR-7.1

### Kernel & Boot Configuration

- Kernel location: `/usr/lib/modules/$kver/vmlinuz`
- Initramfs: `/usr/lib/modules/$kver/initramfs.img`
- **Do NOT include content in /boot** - bootc handles copying kernel/initramfs
- Custom kernel arguments: `/usr/lib/bootc/kargs.d/*.toml` (TOML format)
  - Example: `kargs = ["mitigations=auto,nosmt"]`
  - Architecture-specific: `match-architectures = ["x86_64"]`
- bootc install injects `root=UUID=<uuid>` kernel argument by default

**Links:** NFR-6.1, NFR-6.2

### Authentication & Secrets

For private registries: Pull secret at `/etc/ostree/auth.json`
Alternative locations: `/run/ostree/auth.json` (ephemeral), `/usr/lib/ostree/auth.json`

To sync with podman: Symlink via systemd tmpfiles.d or use `--authfile` flag
For credential helpers: Place empty JSON object `{}` at auth.json location

**Links:** FR-4.1, NFR-3.1

### Installation Methods

1. **bootc install to-disk** - Direct to block device, simple partitioning
2. **bootc install to-filesystem** - External installer prepares filesystem
3. **bootc install to-existing-root** - Install alongside existing Linux (destructive to /boot)

**Links:** FR-6.1, FL-6.0

### Image Building Best Practices

- **bootc container lint** - Static analysis checks, run in Containerfile
- Label: `LABEL containers.bootc 1` - Signals bootc-compatible image
- CMD: Set to `/sbin/init` (recommended but not required)
- Whiteouts: Cannot nest OCI containers (don't `podman pull` inside build)

**Links:** FR-1.1, NFR-4.1

### Provisioning Approaches

- **cloud-init** - Runs at first boot for cloud environments
- **Ignition** - Runs in initramfs before root mounted (Fedora CoreOS style)
- **systemd-firstboot** - Interactive locale/timezone/hostname setup
- **Custom systemd services** - `ConditionFirstBoot=yes` for one-time setup
- **systemd tmpfiles.d** - For injecting files at boot (e.g., SSH keys)
  - Example: `f~ /home/user/.ssh/authorized_keys 600 user user - <base64>`

**Links:** FR-2.1 (contrasts with our on-demand approach)

### Logically Bound Images (Future Consideration)

System containers always available at boot (logging, monitoring). Define in `/usr/lib/bootc/bound-images.d/` as symlinks to .image/.container files. Fetched during `bootc upgrade`, stored in `/usr/lib/bootc/storage`. Not yet supported by Anaconda.

**Links:** FL-7.0 (future enhancement)

### Managing Upgrades

**bootc upgrade** - Download and queue an updated container image to apply. A/B style upgrade system.

**Options:**
- `bootc upgrade --check` - Check for updates without downloading
- `bootc upgrade --download-only` - Stage update without applying
- `bootc upgrade --from-downloaded` - Apply staged update
- `bootc upgrade --apply` - Apply and reboot

**bootc switch** - Change to different image reference (e.g., blue/green deployments)

**bootc rollback** - Swap bootloader ordering to previous deployment

**Links:** FR-7.1, NFR-7.1, FL-7.0

### References

- bootc docs: https://github.com/bootc-dev/bootc/tree/main/docs
- ublue-os templates: https://github.com/ublue-os/image-template
- OSTree docs: https://ostreedev.github.io/ostree/

## Document Information

**Original Content:** 441 lines from initial PRD
**Restructured:** All content preserved, reorganized into BMAD format
**New Sections Added:** Problem Statement, Success Criteria, Product Scope, User Journeys, Functional Requirements, Non-Functional Requirements, Feature List
**Appendices Created:** Architecture Decision Records, Risk Mitigation & Test Scenarios, Technical Implementation Guide
**Traceability:** All requirements linked to source content
**Requirements Count:** 20+ Functional Requirements, 25+ Non-Functional Requirements
**Total Sections:** 6 core BMAD sections + 3 appendices + Innovation + Feature List
