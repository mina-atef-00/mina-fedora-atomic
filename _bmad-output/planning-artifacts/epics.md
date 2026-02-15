---
stepsCompleted: ['step-01-validate-prerequisites', 'step-02-design-epics', 'step-03-create-stories', 'step-04-final-validation']
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/planning-artifacts/architecture.md
---

# mina-fedora-atomic - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for mina-fedora-atomic, decomposing the requirements from the PRD, UX Design if it exists, and Architecture requirements into implementable stories.

## Requirements Inventory

### Functional Requirements

FR-1.1: The container image SHALL organize software installation into 9 distinct OCI layers based on change frequency to reduce layer rebuild size by ≥80% for configuration-only changes (≤500MB vs current 3GB).
FR-1.2: Modification of Layers 6-7 (GUI apps, theming) SHALL require download of ≤500MB versus current 3GB full-layer downloads.
FR-2.1: The system SHALL provide an interactive setup script accessible via `mfa-setup` command in user PATH, available on-demand rather than automatically executing on boot.
FR-2.2: The setup script SHALL support modular selection via numbered menu interface allowing users to select which modules to run.
FR-2.3: The setup script SHALL implement JSON-based state tracking for crash recovery with resume capability.
FR-2.4: The setup script SHALL execute Modules 2 (Flatpaks) and 3 (Homebrew) in parallel after Chezmoi setup completes.
FR-2.5: The setup script SHALL implement pre-flight validation including disk space, network connectivity, and dependency verification.
FR-3.1: The build system SHALL support 2 hardware profiles (asus, lnvo) via HOST_PROFILE environment variable passed to build scripts.
FR-3.2: The CI/CD pipeline SHALL produce two distinct tagged images: `mina-fedora-atomic-desktop:latest` (ASUS profile) and `mina-fedora-atomic-laptop:latest` (LNVO profile).
FR-4.1: The setup script SHALL authenticate to GitHub using gh CLI device flow for accessing private chezmoi repositories.
FR-4.2: Container images SHALL be signed with Cosign for integrity verification.
FR-4.3: The CI/CD pipeline SHALL include Trivy container scanning for vulnerability detection.
FR-5.1: The setup script SHALL implement retry logic with exponential backoff for network failures.
FR-5.2: The chezmoi module SHALL verify decryption capabilities before applying dotfiles.
FR-6.1: The system SHALL provide Anaconda-based ISO with custom kickstart configuration for graphical installation.
FR-7.1: The system SHALL support atomic updates with rollback capability via `bootc upgrade` and `bootc rollback`.
FR-7.2: The setup script SHALL be stored in `/usr/bin/` to update with new images while runtime state stored in `~/.config/` for user persistence.

### NonFunctional Requirements

NFR-1.1: Configuration changes (Layers 6-7 modifications) SHALL require download of ≤500MB versus current 3GB full-layer downloads.
NFR-1.2: Image builds SHALL complete within 45 minutes in GitHub Actions.
NFR-1.3: Setup script resume operations SHALL complete within 5 seconds of restart.
NFR-2.1: The setup script SHALL maintain 99% success rate with automatic retry logic.
NFR-2.2: Flatpak installations SHALL support native resume capability for interrupted downloads.
NFR-3.1: No credentials SHALL be embedded in container image layers.
NFR-3.2: Images SHALL be signed with Cosign for integrity verification.
NFR-3.3: The CI/CD pipeline SHALL scan images with Trivy for CVEs (non-blocking).
NFR-4.1: The Containerfile SHALL use 9 separate RUN commands creating independently cacheable layers.
NFR-4.2: Layer organization SHALL follow change-frequency pattern to minimize invalidation.
NFR-5.1: The setup script SHALL display download size information using native flatpak output before installation.
NFR-5.2: The setup script SHALL send desktop notifications on completion or error.
NFR-6.1: The system SHALL support two hardware profiles: ASUS desktop with NVIDIA graphics and Lenovo laptop with Intel graphics.
NFR-6.2: The system SHALL track ublue-os/base-main with major version pinning (e.g., :43).
NFR-7.1: System updates SHALL be atomic with rollback capability.
NFR-7.2: ISO download and installation SHALL be available for both hardware profiles.
NFR-8.1: The CI/CD pipeline SHALL use matrix builds to produce two distinct images efficiently.
NFR-8.2: The build system SHALL support BTRFS-based podman storage with zstd compression.
NFR-9.1: The system SHALL maintain Fedora Atomic immutability (no persistent DNF installation after boot).
NFR-9.2: Base image updates SHALL trigger full layer rebuild (architectural constraint of OCI/bootc).
NFR-9.3: All DNF operations SHALL occur during image build phase (not at runtime).

### Additional Requirements

- **Project Context:** Brownfield infrastructure project using Fedora Atomic/bootc ecosystem.
- **Layer Architecture:** Refactor monolithic `05-install-pkgs.sh` into 9 distinct scripts (`05a-drivers.sh`, `05b-core.sh`, etc.) to match Containerfile layers.
- **Script Location:** Setup script must be in `/usr/bin/mfa-setup` (immutable, updates via bootc).
- **State Location:** Runtime state must be in `~/.config/mfa-setup/state.json` (mutable, persistent).
- **Authentication:** Must use `gh auth login --web` (Device Flow).
- **Build System:** GitHub Actions Matrix Build for `asus` and `lnvo` profiles.
- **Concurrency:** Use `gum spin` for parallel execution of Flatpaks and Homebrew.
- **Logging:** Use `lib.sh` for centralized logging and error handling (`set -euo pipefail`).
- **Naming Convention:** Scripts must follow `NNx-descriptive-name.sh` pattern.
- **Systemd:** Use declarative systemd presets (`/usr/lib/systemd/system-preset/`) instead of imperative `systemctl enable`.
- **Directory Structure:** Adhere strictly to the defined project structure (`files/scripts/`, `files/system/`).
- **Hardware Profiles:** Use `ARG HOST_PROFILE` in Containerfile passed to build scripts.

### FR Coverage Map

FR-1.1: Epic 1 - Layer Architecture (Build System)
FR-1.2: Epic 1 - Update Optimization (Build System)
FR-2.1: Epic 2 - Setup Script Availability
FR-2.2: Epic 2 - Interactive Menu System
FR-2.3: Epic 2 - State Tracking & Resume
FR-2.4: Epic 3 - Parallel Module Execution
FR-2.5: Epic 2 - Pre-flight Validation
FR-3.1: Epic 1 - Hardware Profile Logic
FR-3.2: Epic 1 - CI/CD Matrix Build
FR-4.1: Epic 2 - GitHub Authentication
FR-4.2: Epic 1 - Image Signing
FR-4.3: Epic 1 - Vulnerability Scanning
FR-5.1: Epic 2 - Retry Logic
FR-5.2: Epic 3 - Chezmoi Validation
FR-6.1: Epic 1 - ISO Generation
FR-7.1: Epic 1 - Atomic Updates
FR-7.2: Epic 2 - Script Location Strategy

## Epic List

### Epic 1: Core OS Build & Distribution
Enable users to install and boot a secure, hardware-optimized Fedora Atomic workstation that supports atomic updates and rollback.
**FRs covered:** FR-1.1, FR-1.2, FR-3.1, FR-3.2, FR-4.2, FR-4.3, FR-6.1, FR-7.1

### Epic 2: Intelligent Setup Orchestrator
Provide users with a robust, interactive tool (`mfa-setup`) to manage their initial setup, handling authentication, state recovery, and network resilience.
**FRs covered:** FR-2.1, FR-2.2, FR-2.3, FR-2.5, FR-4.1, FR-5.1, FR-7.2

### Epic 3: Advanced Environment Provisioning
Automate the high-performance installation of user tools (Homebrew), applications (Flatpaks), and dotfiles (Chezmoi) with parallel execution and validation.
**FRs covered:** FR-2.4, FR-5.2

<!-- Epic 1 Section -->

## Epic 1: Core OS Build & Distribution

Enable users to install and boot a secure, hardware-optimized Fedora Atomic workstation that supports atomic updates and rollback.

### Story 1.1: Implement 9-Layer Container Architecture

As a user,
I want the container image organized into 9 distinct layers based on change frequency,
So that my daily updates are small (≤500MB) and fast.

**Acceptance Criteria:**

**Given** a Containerfile definition
**When** the image is built
**Then** it MUST contain 9 distinct RUN instructions creating separate layers
**And** Layer 2 MUST contain hardware drivers (akmods)
**And** Layer 6 MUST contain GUI applications
**And** `bootc container lint` MUST pass

### Story 1.2: Hardware Profile Support (ASUS/Lenovo)

As a user with specific hardware (ASUS or Lenovo),
I want the image to include the correct drivers for my GPU,
So that my system boots with full graphical acceleration.

**Acceptance Criteria:**

**Given** the build process is initiated
**When** `ARG HOST_PROFILE=asus` is passed
**Then** `05a-drivers.sh` MUST install NVIDIA drivers and akmods
**And** it MUST NOT install Intel-specific packages

**Given** the build process is initiated
**When** `ARG HOST_PROFILE=lnvo` is passed
**Then** `05a-drivers.sh` MUST install Intel drivers
**And** it MUST NOT install NVIDIA packages

### Story 1.3: Secure CI/CD Pipeline Setup

As a maintainer,
I want automated builds that sign and scan images,
So that I can trust the integrity and security of the distributed OS.

**Acceptance Criteria:**

**Given** a push to the main branch
**When** the GitHub Actions workflow triggers
**Then** it MUST execute a matrix build for both `asus` and `lnvo` profiles in parallel
**And** the resulting images MUST be signed with Cosign
**And** the images MUST be scanned with Trivy with results available as artifacts
**And** the images MUST be pushed to GHCR with `latest` and `sha` tags

### Story 1.4: ISO Generation & Kickstart

As a new user,
I want an ISO installer that sets up my system automatically,
So that I can install the OS without complex manual partitioning.

**Acceptance Criteria:**

**Given** the container images are built and pushed
**When** the ISO generation step runs
**Then** it MUST produce `install-asus-ghcr.iso` and `install-lnvo-ghcr.iso`
**And** the ISOs MUST be configured with a kickstart file (without automated partitioning)
**And** the post-install script MUST execute `bootc switch` to the signed container image


<!-- Epic 2 Section -->

## Epic 2: Intelligent Setup Orchestrator

Provide users with a robust, interactive tool (`mfa-setup`) to manage their initial setup, handling authentication, state recovery, and network resilience.

### Story 2.1: Orchestrator Shell & State Management

As a user,
I want the setup script to remember my progress,
So that I can resume if the installation is interrupted.

**Acceptance Criteria:**

**Given** the script is executed
**When** it starts
**Then** it MUST be located at `/usr/bin/mfa-setup`
**And** it MUST read/write state to `~/.config/mfa-setup/state.json`
**And** the state file MUST track `completed_modules` and `last_run_timestamp`
**And** it MUST offer to "Resume" if a previous incomplete state is detected

### Story 2.2: Interactive Menu System

As a user,
I want a clear menu to select which components to install,
So that I can customize my setup or re-run specific parts.

**Acceptance Criteria:**

**Given** the script is running
**When** the menu is displayed
**Then** it MUST show options for [1] Chezmoi, [2] Flatpaks, [3] Homebrew, [4] All, [5] Exit
**And** it MUST allow selecting multiple options (e.g., "1,3")
**And** it MUST use a TUI library like `gum` for interaction

### Story 2.3: Pre-flight Validation

As a user,
I want the system to check requirements before starting,
So that I don't waste time on a failed installation.

**Acceptance Criteria:**

**Given** the script is initiated
**When** pre-flight checks run
**Then** it MUST verify >20GB free disk space (WARN only if <20GB)
**And** it MUST verify network connectivity to GitHub, Flathub, and Homebrew
**And** it MUST verify required binaries are available
**And** it MUST run primarily in USER space without sudo (for flatpak/brew)
**And** it MUST exit with a clear error if critical checks fail

### Story 2.4: GitHub Authentication Integration

As a user,
I want to authenticate with GitHub securely,
So that I can access my private dotfiles repository.

**Acceptance Criteria:**

**Given** the script needs to access private repos
**When** authentication is required
**Then** it MUST check if `gh` is already authenticated
**And** if not, it MUST run `gh auth login --web`
**And** it MUST wait for the user to complete browser authentication
**And** the token MUST be stored securely

### Story 2.5: Retry Logic & Error Handling

As a user,
I want network operations to retry automatically,
So that temporary glitches don't fail the entire setup.

**Acceptance Criteria:**

**Given** a network operation (git, flatpak, brew)
**When** the operation fails
**Then** the system MUST retry up to 3 times
**And** it MUST use exponential backoff (e.g., 5s, 10s, 20s) between attempts
**And** it MUST log the final error and exit gracefully if all retries fail

<!-- Epic 3 Section -->

## Epic 3: Advanced Environment Provisioning

Automate the high-performance installation of user tools (Homebrew), applications (Flatpaks), and dotfiles (Chezmoi) with parallel execution and validation.

### Story 3.1: Chezmoi Dotfile Management

As a user,
I want my dotfiles applied securely and correctly,
So that my development environment is personalized immediately.

**Acceptance Criteria:**

**Given** the user selects the Chezmoi module
**When** it executes
**Then** it MUST verify the presence of the age decryption key
**And** it MUST run `chezmoi apply --dry-run` first to validate templates
**And** it MUST execute `chezmoi init --apply` if validation passes
**And** it MUST exit with a helpful error if decryption fails

### Story 3.2: Flatpak Application Module

As a user,
I want to install my GUI applications efficiently,
So that I have all my tools ready for work.

**Acceptance Criteria:**

**Given** a list of Flatpak IDs
**When** the Flatpak module runs
**Then** it MUST install the applications from Flathub
**And** it MUST display the download size and progress
**And** it MUST support resuming interrupted downloads (native Flatpak feature)

### Story 3.3: Homebrew Bundle Module

As a user,
I want to install CLI tools from a Brewfile,
So that I have a consistent command-line environment.

**Acceptance Criteria:**

**Given** a Brewfile in the dotfiles repo
**When** the Homebrew module runs
**Then** it MUST install Homebrew if missing
**And** it MUST execute `brew bundle` to install packages
**And** it MUST handle existing packages gracefully

### Story 3.4: Parallel Module Execution

As a user,
I want the installation to be fast,
So that I don't wait sequentially for independent tasks.

**Acceptance Criteria:**

**Given** the user selects two or more independent modules
**When** execution begins
**Then** the modules MUST run simultaneously in parallel processes
**And** the UI MUST show a spinner or progress indicator for each running module
**And** the script MUST wait for ALL modules to complete before finishing
**And** errors in any process MUST be captured and reported at the end
**And** the parallel execution MUST NOT depend on specific module types
