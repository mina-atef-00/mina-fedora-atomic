---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
workflowType: 'architecture'
project_name: 'mina-fedora-atomic'
user_name: 'Monna'
date: '2026-02-13'
lastStep: 8
status: 'complete'
completedAt: '2026-02-14'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional Requirements:**
The project contains 20+ functional requirements organized into 7 major categories:
- **FR-1.0 Layer Architecture**: 9-layer container image organization by change frequency to reduce download sizes from 3GB to ≤500MB
- **FR-2.0 User Setup System**: Interactive `mfa-setup` script with modular menu, crash recovery, parallel execution, and pre-flight validation
- **FR-3.0 Build System**: Hardware profile matrix (asus/lnvo) with conditional builds
- **FR-4.0 Authentication & Security**: gh CLI device flow, Cosign signing, Trivy scanning
- **FR-5.0 Error Handling & Reliability**: Retry logic with exponential backoff, chezmoi dry-run validation
- **FR-6.0 ISO Distribution**: Anaconda-based graphical installer with kickstart
- **FR-7.0 Maintenance & Operations**: Atomic updates via bootc, rollback capability

**Non-Functional Requirements:**
Key NFRs driving architectural decisions:
- **NFR-1.1**: ≤500MB download for configuration changes (vs 3GB baseline)
- **NFR-1.2**: Image builds <45 minutes in CI
- **NFR-2.1**: 99% success rate for setup script
- **NFR-3.1**: Zero credentials embedded in container layers
- **NFR-9.1**: Fedora Atomic immutability (no runtime DNF)
- **NFR-9.2**: Base image updates trigger full layer rebuild (architectural constraint)

### Scale & Complexity

- **Primary domain:** DevOps/Infrastructure - Container Build System with First-Boot Automation
- **Complexity level:** Medium-High
- **Estimated architectural components:** 9 (one per layer) + setup script modules + CI/CD pipeline

### Technical Constraints & Dependencies

1. **Fedora Atomic Immutability**: No persistent DNF operations after boot - all package installation must occur during image build
2. **bootc/OSTree Layer Caching**: Changing base layer invalidates ALL upper layers in cache - must optimize layer organization by change frequency
3. **State Persistence**: Files in /var from container image only unpacked on initial install, not on `bootc switch` updates
4. **Two Hardware Profiles**: ASUS (NVIDIA) and Lenovo (Intel) requiring conditional builds
5. **Authentication**: gh CLI device flow for GitHub, no embedded credentials

### Cross-Cutting Concerns Identified

1. **Layer Caching Strategy**: Must minimize lower-layer changes to preserve cache efficiency
2. **State Management**: Script in /usr (updates with image), runtime state in ~/.config/ (user-persistent)
3. **Update Atomicity**: All updates must support rollback via bootc
4. **Security Posture**: No credentials in layers, signed images, vulnerability scanning
5. **User Experience**: On-demand setup (not automatic), resume capability, parallel execution

## Starter Template Evaluation

### Primary Technology Domain

**Infrastructure/DevOps - Container Build System** based on project requirements analysis (not a traditional application project)

### Technology Stack Determination

This is a **brownfield infrastructure project** with pre-determined technology choices from the Fedora Atomic/bootc ecosystem. No alternative starter templates are applicable.

| Component | Technology | Rationale |
|-----------|------------|-----------|
| Base OS | Fedora Atomic | Required by project (PS-1.2) |
| Container | bootc/OSTree | Required by project (PS-1.2) |
| Base Image | ublue-os/base-main:43 | Industry standard for Fedora Atomic desktops |
| CI/CD | GitHub Actions | Already used in project |
| Package Managers | flatpak, homebrew | Required by PRD (PS-1.1) |
| Authentication | gh CLI | Required by FR-4.1 |
| Image Signing | Cosign | Required by FR-4.2 |
| Vulnerability Scanning | Trivy | Required by FR-4.3 |

### Architectural Approach

Since this is an infrastructure project rather than an application project, the "architectural decisions" will focus on:

1. **Layer Architecture**: 9-layer Containerfile organization by change frequency
2. **Setup Script Architecture**: Bash-based modular system with state management
3. **Build Pipeline**: GitHub Actions matrix for hardware profiles
4. **State Management Strategy**: /usr vs ~/.config/ separation

### Implementation Approach

This project uses **custom implementation** rather than a starter template. The implementation stories will build:
- Containerfile with 9 RUN commands (one per layer)
- Bash setup script with modular architecture
- GitHub Actions workflow with matrix strategy
- ISO generation with kickstart configuration

## Core Architectural Decisions

### Decision Priority Analysis

**Critical Decisions (Block Implementation):**
- **Layer Construction**: Refactoring monolithic script into 9 distinct scripts for caching
- **Hardware Profile Logic**: Using `ARG HOST_PROFILE` in Containerfile passed to scripts
- **Setup Script Concurrency**: Using `gum` for TUI parallel execution

**Important Decisions (Shape Architecture):**
- **State Management**: Immutable script in /usr/bin, mutable state in ~/.config/
- **CI Matrix Strategy**: Parallel builds for Asus/Lenovo profiles

### Data Architecture (State Management)

- **Script Location**: `/usr/bin/mfa-setup` (Immutable, updates via bootc)
- **State Location**: `~/.config/mfa-setup/state.json` (Mutable, persistent)
- **State Format**: JSON (requires `jq` dependency)
- **Rationale**: Follows Linux XDG standards; allows script logic to update with OS images while preserving user progress/recovery state.

### Authentication & Security

- **Method**: GitHub CLI Device Flow (`gh auth login --web`)
- **Rationale**: No secrets stored in image; leverages existing GitHub 2FA/security.
- **Signing**: Cosign keyless signing in CI pipeline.
- **Scanning**: Trivy vulnerability scanning (non-blocking).

### Setup Script Architecture

- **Concurrency**: `gum spin` based parallel execution for Flatpaks and Homebrew.
  - **Rationale**: Excellent UX ("Hacker" aesthetic), uses tool already in package list.
- **Modularity**: Scripts split by layer function (drivers, core, gui, etc.) to match Containerfile layers.
- **Recovery**: Checkpoints saved to `state.json` after each successful module.

### Infrastructure & Deployment (CI/CD)

- **Strategy**: GitHub Actions Matrix Build (`profile: [asus, lnvo]`)
- **Rationale**: Parallel execution reduces total build time; isolated failure domains.
- **Caching**: `actions/cache` for buildah layers where possible.
- **Registry**: GHCR (ghcr.io/mina/mina-fedora-atomic-*)

### Decision Impact Analysis

**Implementation Sequence:**
1. **Refactor Scripts**: Split `05-install-pkgs.sh` into `05a-drivers.sh`, `05b-core.sh`, etc.
2. **Containerfile Update**: Implement 9 RUN commands calling the split scripts.
3. **Setup Script**: Build `mfa-setup` with `gum` UI and state management.
4. **CI Pipeline**: Verify matrix build configuration.

**Cross-Component Dependencies:**
- **Layering & Scripts**: The Containerfile structure directly dictates the script file organization.
- **Hardware Profiles**: The `ARG HOST_PROFILE` must be correctly propagated from Containerfile -> Shell Scripts.

### Implementation Specifics

**Script Organization Strategy:**
- **Split Strategy**: Granular files (e.g., `05a-drivers.sh`, `05b-core-utils.sh`) to match the 9-layer requirement.
- **Library Management**: `COPY lib.sh /usr/local/bin/lib.sh` early in the build process to share across all layers.

**Package Management Refactoring:**
- **Drivers**: Isolated in `05a-drivers.sh` (NVIDIA/Intel logic).
- **Core Utils**: `05b-core-utils.sh` (CLI tools, fish, starship).
- **GUI Apps**: `05c-gui-apps.sh` (Kitty, Nautilus, Chromium).
- **Assets**: Dedicated `05e-assets.sh` for external font/theme downloads to isolate network flakiness.
- **Cleanup**: `05f-cleanup.sh` for debloat and repo cleanup.

**System Configuration:**
- **Systemd**: Move from imperative `systemctl enable` scripts to declarative presets (`/usr/lib/systemd/system-preset/`).
- **Rationale**: cleaner, idempotent, "cloud-native" approach supported by OSTree.

**Asset Management:**
- **External Downloads**: Accept risk of URL changes (cache-busting) for simplicity, but isolate in separate layer.

## Implementation Patterns & Consistency Rules

### Pattern Categories Defined

**Critical Conflict Points Identified:**
5 areas where AI agents could make different choices (Script Naming, Variables, Logging, Error Handling, State Keys).

### Naming Patterns

**Script Naming Conventions:**
- **Format:** `NNx-descriptive-name.sh` (e.g., `05a-drivers.sh`, `05b-core-utils.sh`)
- **Rationale:** Ensures explicit execution order within a layer category (05) while allowing granular splitting (a, b, c).
- **Example:** `05a-drivers.sh` (Drivers), `05b-core.sh` (Core Utils)

**Variable Naming Conventions:**
- **Globals/Env:** `UPPER_CASE` (e.g., `HOST_PROFILE`, `IMAGE_NAME`)
- **Locals:** `lower_case` (e.g., `package_list`, `install_dir`)
- **Rationale:** Standard Bash convention to distinguish exported environment variables from script-local variables.

### Communication Patterns

**Logging Patterns:**
- **Format:** `log "LEVEL" "Message"` (using `lib.sh`)
- **Example:** `log "INFO" "Installing packages..."`
- **Rationale:** Centralized logging logic allows for consistent formatting, colors, and potential future redirection (e.g., to file or JSON).

**Error Handling Patterns:**
- **Strict Mode:** `set -euo pipefail` at top of every script
- **Rationale:** "Fail fast" is critical for image builds. If any command fails, the build should stop immediately to prevent broken images.

**State Management Patterns:**
- **Key Format:** `snake_case` (e.g., `last_run`, `module_id`)
- **Rationale:** Consistent with Python/Bash standards and `jq` usage.

### Enforcement Guidelines

**All AI Agents MUST:**
- Source `lib.sh` at the start of every script
- Use `log` function instead of `echo`
- Use `set -euo pipefail`
- Follow the `NNx-name.sh` naming convention for new scripts

**Pattern Enforcement:**
- **Verification:** `shellcheck` linting in CI
- **Documentation:** This architecture document serves as the source of truth.

## Project Structure & Boundaries

### Complete Project Directory Structure

```
mina-fedora-atomic/
├── .github/
│   └── workflows/
│       └── build.yml               # CI/CD Pipeline (Matrix)
├── files/                          # OCI Build Context (Copied to image)
│   ├── scripts/                    # Build-time scripts (The 9 Layers)
│   │   ├── lib.sh                  # Shared logging/error library
│   │   ├── 00-setup.sh             # Main orchestrator
│   │   ├── 01-cleanup.sh           # Pre-clean
│   │   ├── 03-prep-env.sh          # Environment prep
│   │   ├── 04-copy-files.sh        # Overlay logic
│   │   ├── 05a-drivers.sh          # Hardware drivers (Akmods)
│   │   ├── 05b-core-utils.sh       # CLI tools
│   │   ├── 05c-gui-apps.sh         # Graphical apps
│   │   ├── 05d-assets.sh           # Fonts/Themes (Network heavy)
│   │   ├── 05e-cleanup.sh          # Debloat/DNF clean
│   │   ├── 06-theming.sh           # System-wide theme apply
│   │   └── 11-final-cleanup.sh     # Final image minimization
│   ├── system/                     # Root filesystem overlay
│   │   ├── etc/
│   │   │   ├── modprobe.d/
│   │   │   └── yum.repos.d/
│   │   └── usr/
│   │       ├── lib/
│   │       │   ├── bootc/
│   │       │   │   └── kargs.d/        # Kernel arguments (Correct location)
│   │       │   └── systemd/
│   │       │       └── system-preset/  # Declarative services
│   │       └── bin/
│   │           └── mfa-setup       # The user setup script
├── Containerfile                   # 9-Layer Build Definition
└── README.md
```

### Architectural Boundaries

**Build Boundaries (OCI):**
- **Inputs:** `files/scripts/` (Scripts), `files/system/` (Config overlay)
- **Outputs:** `ghcr.io/mina/mina-fedora-atomic-*` (Container Image)
- **Constraint:** Code in `scripts/` runs *only* during GitHub Actions build. It does not exist on the final system (except via logs or artifacts if saved).

**Runtime Boundaries (User):**
- **Executable:** `/usr/bin/mfa-setup` (Baked into image)
- **State:** `~/.config/mfa-setup/` (Created at runtime)
- **Constraint:** `mfa-setup` can only modify user-writable areas (`~`, `/etc` via sudo) but cannot modify `/usr` (read-only system).

**Configuration Boundaries:**
- **System Config:** `/usr/lib/...` (Baked defaults), `/etc/...` (User overrides).
- **Service Config:** `/usr/lib/systemd/system-preset/` (Declarative defaults).

### Requirements to Structure Mapping

**Feature/Epic Mapping:**
- **Layer Architecture (FR-1.0)**: Mapped to `files/scripts/05[a-e]-*.sh` scripts.
- **User Setup (FR-2.0)**: Mapped to `files/system/usr/bin/mfa-setup`.
- **Hardware Profiles (FR-3.0)**: Logic in `05a-drivers.sh` + `.github/workflows/build.yml`.
- **Systemd (FR-7.0)**: Logic moved to `files/system/usr/lib/systemd/system-preset/`.

**Cross-Cutting Concerns:**
- **Logging**: `files/scripts/lib.sh` (Build-time), `mfa-setup` internal logging (Runtime).
- **Security**: `files/system/etc/ssh/` (Hardening), `05a-drivers.sh` (Secure Boot modules).

### Integration Points

**Internal Communication:**
- **Build-Time**: Scripts communicate via shared `lib.sh` and return codes.
- **Runtime**: `mfa-setup` communicates with OS via `rpm-ostree`, `flatpak`, `brew` CLI calls.

**External Integrations:**
- **Flathub**: `05c-gui-apps.sh` (Remote addition), `mfa-setup` (Install).
- **GitHub**: `mfa-setup` (Device flow auth).
- **Copr/RPM Fusion**: `05a-drivers.sh` (Enabling/Installing).

### File Organization Patterns

**Configuration Files:**
- **Kernel Args**: `files/system/usr/lib/bootc/kargs.d/*.toml`
- **Systemd Presets**: `files/system/usr/lib/systemd/system-preset/*.preset`

**Source Organization:**
- **Scripts**: Ordered by execution (`00` to `11`).
- **Overlay**: Mirrors target filesystem structure (`files/system/usr/bin` -> `/usr/bin`).

## Architecture Validation Results

### Coherence Validation ✅

**Decision Compatibility:**
- All architectural decisions are coherent and mutually supportive. The decision to split the monolithic `05-install-pkgs.sh` directly enables the 9-layer caching strategy required by the PRD. The use of `ARG HOST_PROFILE` ensures hardware profiles are handled correctly within the build pipeline.

**Pattern Consistency:**
- Naming conventions (`NNx-name.sh`) are consistent and provide clear execution order.
- The use of `lib.sh` across all scripts ensures consistent logging and error handling.
- The adoption of `systemd-presets` aligns with the declarative nature of the OS image.

**Structure Alignment:**
- The project structure correctly segregates build-time logic (`files/scripts`) from runtime configuration (`files/system`).
- Key components like `kargs.d` are placed in the correct `usr/lib/bootc` location for bootc consumption.

### Requirements Coverage Validation ✅

**Epic/Feature Coverage:**
- **Layer Architecture**: Fully covered by script splitting strategy.
- **User Setup**: Fully covered by `mfa-setup` design and state persistence.
- **Hardware Profiles**: Fully covered by matrix build and conditional driver installation.

**Functional Requirements Coverage:**
- All FRs from the PRD (FR-1.0 to FR-7.0) have direct architectural support mapped to specific files or patterns.

**Non-Functional Requirements Coverage:**
- **Update Size (NFR-1.1)**: Addressed by granular layering.
- **Reliability (NFR-2.1)**: Addressed by `set -e` patterns and `state.json` recovery.
- **Security (NFR-3.1)**: Addressed by `gh auth` flow and secret-free build.

### Implementation Readiness Validation ✅

**Decision Completeness:**
- Critical decisions (layering, setup script, state) are documented with specific implementation directives.
- Technology stack is locked (Fedora Atomic, bootc, bash).

**Structure Completeness:**
- Full file tree is defined down to the file level for critical components.
- Boundaries between build-time and runtime are explicit.

**Pattern Completeness:**
- Naming, logging, and error handling patterns are standardized.
- Consistency rules provide clear guidance for implementation agents.

### Gap Analysis Results

**Minor Gaps:**
- **Gum UI Specs**: Specific text/colors for the CLI menus are not defined (implementation detail).
- **Asset Fallback**: No explicit fallback if external font URLs fail (risk accepted).

### Validation Issues Addressed

- **Systemd Logic**: Moved from imperative scripts to declarative presets for better reliability.
- **Script Bloat**: Addressed by splitting monolithic scripts into focused layers.
- **File Placement**: Corrected `kargs.d` location to align with bootc standards.

### Architecture Completeness Checklist

**✅ Requirements Analysis**

- [x] Project context thoroughly analyzed
- [x] Scale and complexity assessed
- [x] Technical constraints identified
- [x] Cross-cutting concerns mapped

**✅ Architectural Decisions**

- [x] Critical decisions documented with versions
- [x] Technology stack fully specified
- [x] Integration patterns defined
- [x] Performance considerations addressed

**✅ Implementation Patterns**

- [x] Naming conventions established
- [x] Structure patterns defined
- [x] Communication patterns specified
- [x] Process patterns documented

**✅ Project Structure**

- [x] Complete directory structure defined
- [x] Component boundaries established
- [x] Integration points mapped
- [x] Requirements to structure mapping complete

### Architecture Readiness Assessment

**Overall Status:** READY FOR IMPLEMENTATION

**Confidence Level:** High

**Key Strengths:**
- Granular layering strategy directly addresses the core update size constraint.
- Separation of concerns between immutable OS (usr) and user state (home/etc).
- Use of native Linux standards (XDG, systemd presets) for robust configuration.

**Areas for Future Enhancement:**
- Automated testing of the `mfa-setup` script logic.
- Potential migration to a more robust language (Go/Rust) for the setup script if complexity grows.

### Implementation Handoff

**AI Agent Guidelines:**

- Follow all architectural decisions exactly as documented
- Use implementation patterns consistently across all components
- Respect project structure and boundaries
- Refer to this document for all architectural questions

**First Implementation Priority:**
Refactoring `05-install-pkgs.sh` into split scripts (`05a`, `05b`, etc.)
