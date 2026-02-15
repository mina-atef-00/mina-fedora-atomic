# Story 1.1: 9-Layer Container Architecture

Status: ready-for-dev

## Story

As a system architect,
I want a 9-layer container architecture with clear separation of concerns,
so that builds are optimized for caching, maintainability, and atomic updates work correctly.

## Acceptance Criteria

1. **Layer 1 - Base**: Foundation image from ublue-os/base-main with proper tagging (AC: #1)
2. **Layer 2 - Kernel Modules**: Common akmods integration via bind mounts (AC: #2)
3. **Layer 3 - GPU Drivers**: NVIDIA akmods for desktop profile only (AC: #3)
4. **Layer 4 - System Context**: Build context and file overlays (AC: #4)
5. **Layer 5 - Package Base**: Core package installation layer (AC: #5)
6. **Layer 6 - Desktop Environment**: Niri compositor and DMS setup (AC: #6)
7. **Layer 7 - Hardware Profile**: Profile-specific configurations (lnvo/asus) (AC: #7)
8. **Layer 8 - Theming**: Visual customization layer (AC: #8)
9. **Layer 9 - Finalization**: Cleanup, linting, and validation (AC: #9)
10. Each layer must be independently cacheable and follow Docker best practices (AC: #10)
11. Build times must be under 15 minutes with warm cache (AC: #11)

## Tasks / Subtasks

- [ ] Task 1: Analyze current Containerfile and identify layer optimization opportunities (AC: #1-4)
  - [ ] Subtask 1.1: Document current layer structure and caching behavior
  - [ ] Subtask 1.2: Identify redundant operations across scripts
- [ ] Task 2: Design 9-layer architecture with proper separation (AC: #1-9)
  - [ ] Subtask 2.1: Define layer boundaries and responsibilities
  - [ ] Subtask 2.2: Create layer dependency diagram
- [ ] Task 3: Implement Layer 1-3 (Base, Kernel, GPU) (AC: #1-3)
  - [ ] Subtask 3.1: Optimize FROM statements with specific tags
  - [ ] Subtask 3.2: Configure akmods bind mounts correctly
- [ ] Task 4: Implement Layer 4-6 (Context, Packages, Desktop) (AC: #4-6)
  - [ ] Subtask 4.1: Refactor 00-setup.sh into layer-aware scripts
  - [ ] Subtask 4.2: Separate package installation by concern
- [ ] Task 5: Implement Layer 7-9 (Profile, Theme, Final) (AC: #7-9)
  - [ ] Subtask 5.1: Create profile-specific overlay directories
  - [ ] Subtask 5.2: Optimize cleanup and validation steps
- [ ] Task 6: Validate caching and build performance (AC: #10-11)
  - [ ] Subtask 6.1: Run test builds with cache warm/cold
  - [ ] Subtask 6.2: Document layer cache hit rates

## Dev Notes

### Current Architecture Analysis
The existing Containerfile uses a simplified multi-stage approach:
- FROM scratch AS ctx (build context)
- FROM ghcr.io/ublue-os/akmods-nvidia-open:main-43 AS akmods-nvidia
- FROM ghcr.io/ublue-os/akmods:main-43 AS akmods-common
- FROM ghcr.io/ublue-os/base-main:43 (final)

The build executes via 00-setup.sh which chains: 01-cleanup.sh → 03-prep-env.sh → 04-copy-files.sh → 05-install-pkgs.sh → 06-theming.sh → 10-systemd.sh → 11-final-cleanup.sh

### Target 9-Layer Architecture
```dockerfile
# Layer 1: Base OS
FROM ghcr.io/ublue-os/base-main:43 AS layer-1-base

# Layer 2: Kernel Modules (common akmods)
FROM layer-1-base AS layer-2-kernel
COPY --from=akmods-common /rpms /tmp/akmods-common

# Layer 3: GPU Drivers (NVIDIA - desktop only)
FROM layer-2-kernel AS layer-3-gpu
COPY --from=akmods-nvidia /rpms /tmp/akmods-nvidia

# Layer 4: Build Context
FROM scratch AS layer-4-context
COPY files /files

# Layer 5: Package Base
FROM layer-3-gpu AS layer-5-packages
RUN --mount=from=layer-4-context... install base packages

# Layer 6: Desktop Environment
FROM layer-5-packages AS layer-6-desktop
RUN install niri, dms, wayland tools

# Layer 7: Hardware Profile
FROM layer-6-desktop AS layer-7-profile
ARG HOST_PROFILE
RUN apply-profile ${HOST_PROFILE}

# Layer 8: Theming
FROM layer-7-profile AS layer-8-theme
RUN apply themes and icons

# Layer 9: Finalization
FROM layer-8-theme AS layer-9-final
RUN cleanup, bootc lint
```

### Testing Standards
- bootc container lint must pass
- Build caching verified via `podman build --layers=true`
- Image size tracked and optimized

### Project Structure Notes
- Containerfile: Root level container definition
- files/scripts/: Build scripts need refactoring for layer boundaries
- files/system/: System configs to be applied in Layer 4
- disk_config/: ISO configuration (Story 1.4)

### References
- [Source: Containerfile] - Current multi-stage setup
- [Source: openspec/project.md] - Project conventions and constraints
- [Source: .github/workflows/build.yml] - CI/CD matrix build strategy
- bootc best practices: https://github.com/bootc-dev/bootc/docs

## Dev Agent Record

### Agent Model Used

kimi-k2.5-free / opencode

### Debug Log References

### Completion Notes List

### File List
