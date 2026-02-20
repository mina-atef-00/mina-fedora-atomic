# Story 4.6: Library Integration and Build Script Updates

Status: review

## Story

As a maintainer,
I want the logging library integrated into existing build scripts,
so that all builds use the new logging system consistently.

## Acceptance Criteria

1. **Given** the base.sh script runs **When** Stage 1 (early setup) executes **Then** `dnf5 install -y gum` is called **And** installation failure is handled gracefully with fallback

2. **Given** lib.sh is created at `files/scripts/lib.sh` **When** build scripts source the library **Then** all logging functions are available **And** `log_init()` initializes configuration

3. **Given** existing build scripts exist **When** they are updated to use lib.sh **Then** `source /ctx/files/scripts/lib.sh` is added **And** `print_header()` is called at build start **And** `print_footer()` is called at build end

4. **Given** Containerfile RUN stages execute **When** each layer builds **Then** `start_phase()` is called with layer-appropriate name **And** `end_phase()` is called at layer completion **And** phase names map to Containerfile layer purposes

5. **Given** the main build entry point runs **When** build starts **Then** header displays within first 100ms **And** phases progress sequentially **And** footer displays final status

6. **Given** a build completes successfully **When** footer is displayed **Then** all metrics are accurate (duration, size, packages, tags) **And** tags include :latest, :latest.DATE, :DATE formats

## Tasks / Subtasks

- [x] Update base.sh for Gum installation (AC: 1)
  - [x] Add `dnf5 install -y gum` to Stage 1
  - [x] Handle installation failure gracefully
  - [x] Log installation status
- [x] Create lib.sh sourcing pattern (AC: 2-3)
  - [x] Add `source /ctx/files/scripts/lib.sh` to build scripts
  - [x] Add `log_init()` call after sourcing
  - [x] Add `print_header()` at build start
  - [x] Add `print_footer()` at build end
- [x] Update Containerfile phases (AC: 4)
  - [x] Wrap each RUN stage with `start_phase()` and `end_phase()`
  - [x] Map phase names to layer purposes:
    - Phase 1: Environment Preparation
    - Phase 2: System Overlay
    - Phase 3: Package Installation
    - Phase 4: COPR Repositories
    - Phase 5: Theming & Fonts
    - Phase 6: Service Configuration
    - Phase 7: Cleanup
    - Phase 8: Finalization
- [x] Implement metrics collection (AC: 6)
  - [x] Track build start time
  - [x] Calculate final duration
  - [x] Collect image size
  - [x] Count packages installed/removed
  - [x] Generate tag formats: :latest, :latest.DATE, :DATE

## Dev Notes

### Files to Update

1. **files/scripts/lib.sh** (created in Story 4.1)
   - Ensure all functions are properly exported

2. **files/scripts/base.sh**
   - Add Gum installation in Stage 1
   - Add `source /ctx/files/scripts/lib.sh`
   - Add `log_init()` and `print_header()`

3. **Containerfile**
   - Each RUN stage should call phase functions
   - Final stage should call `print_footer()`

### Phase Mapping

| Phase | Containerfile Stage | Purpose |
|-------|---------------------|---------|
| 1 | base.sh Stage 1 | Environment setup |
| 2 | COPY overlay files | System overlay |
| 3 | dnf5 install | Package installation |
| 4 | COPR enable | COPR repositories |
| 5 | Theme/font install | Theming & Fonts |
| 6 | systemctl enable | Service configuration |
| 7 | dnf5 clean | Cleanup |
| 8 | bootc lint | Finalization |

### Integration Pattern

```bash
#!/bin/bash
source /ctx/files/scripts/lib.sh
log_init

print_header \
  --image "mina-fedora-atomic-desktop" \
  --profile "${HOST_PROFILE}" \
  --base "ghcr.io/ublue-os/base-main:43"

# Build phases...
start_phase "Environment Preparation"
# ... phase work ...
end_phase

print_footer \
  --duration "${BUILD_DURATION}" \
  --size "${IMAGE_SIZE}" \
  --status "success"
```

### Dependencies
- Requires ALL previous stories (4.1-4.5) to be complete
- This is the final integration story

### References
- PRD: `_bmad-output/planning-artifacts/epic-logging/gum-logging-prd.md` (Section 7)
- Architecture: `_bmad-output/planning-artifacts/architecture.md`

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

- Implemented Gum installation in base.sh Stage 1 with graceful fallback
- Added log_init() call to all build scripts (base.sh, akmods.sh, core.sh, media.sh, apps.sh, profile.sh, theme.sh, final.sh)
- Added print_header() call in base.sh at build start
- Added print_footer() call in final.sh at build end with metrics collection
- Wrapped each build phase with start_phase()/end_phase() calls:
  - Phase 1: Environment Preparation (base.sh)
  - Phase 2: System Overlay (akmods.sh)
  - Phase 3: Package Installation (core.sh)
  - Phase 4: COPR Repositories (media.sh)
  - Phase 5: Theming & Fonts (apps.sh)
  - Phase 6: Service Configuration (profile.sh)
  - Phase 7: Cleanup (theme.sh)
  - Phase 8: Finalization (final.sh)
- Implemented metrics collection in final.sh: duration, image size, package count, tags

### File List

- files/scripts/base.sh (modified)
- files/scripts/akmods.sh (modified)
- files/scripts/core.sh (modified)
- files/scripts/media.sh (modified)
- files/scripts/apps.sh (modified)
- files/scripts/profile.sh (modified)
- files/scripts/theme.sh (modified)
- files/scripts/final.sh (modified)

### Change Log

- 2026-02-20: Integrated logging library into all build scripts with phase tracking and metrics collection

### Status

review
