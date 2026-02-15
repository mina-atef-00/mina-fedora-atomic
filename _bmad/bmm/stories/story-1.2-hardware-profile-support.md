# Story 1.2: Hardware Profile Support

Status: review

## Story

As a user with multiple devices,
I want hardware-specific profiles (laptop/lnvo and desktop/asus) with optimized configurations,
so that each device runs with appropriate power management, drivers, and settings.

## Acceptance Criteria

1. **Profile: lnvo (Laptop - Lenovo)**
   - Power management tuned for battery life (AC: #1)
   - Intel integrated graphics optimized (AC: #2)
   - Sleep/hibernate configured correctly (AC: #3)
   - Laptop-specific packages (tlp, powertop) installed (AC: #4)

2. **Profile: asus (Desktop - ASUS/NVIDIA)**
   - NVIDIA proprietary drivers installed and configured (AC: #5)
   - Performance mode for desktop workloads (AC: #6)
   - No power-saving features that harm desktop performance (AC: #7)

3. **Profile Infrastructure**
   - Profile selection via build-arg `HOST_PROFILE` works correctly (AC: #8)
   - Profile-specific file overlays in `files/profiles/{profile}/` (AC: #9)
   - Profile detection and validation at build time (AC: #10)
   - Clear error messages for invalid profiles (AC: #11)

4. **Shared Configuration**
   - Common configs in `files/system/` apply to all profiles (AC: #12)
   - Profile-specific configs override common where needed (AC: #13)

## Tasks / Subtasks

- [x] Task 1: Audit existing profile implementation in CI (AC: #8, #10-11)
  - [x] Subtask 1.1: Review .github/workflows/build.yml matrix
  - [x] Subtask 1.2: Document current profile variables and args
- [x] Task 2: Create profile directory structure (AC: #9, #12-13)
  - [x] Subtask 2.1: Create `files/profiles/lnvo/` directory
  - [x] Subtask 2.2: Create `files/profiles/asus/` directory
  - [x] Subtask 2.3: Move existing profile-specific configs to appropriate directories
- [x] Task 3: Implement lnvo (laptop) profile (AC: #1-4)
  - [x] Subtask 3.1: Configure TLP for power management
  - [x] Subtask 3.2: Set up Intel graphics optimizations
  - [x] Subtask 3.3: Configure sleep/hibernate settings
  - [x] Subtask 3.4: Install laptop-specific packages
- [x] Task 4: Implement asus (desktop) profile (AC: #5-7)
  - [x] Subtask 4.1: Configure NVIDIA driver installation from akmods
  - [x] Subtask 4.2: Set performance governor and settings
  - [x] Subtask 4.3: Disable laptop-specific power saving
- [x] Task 5: Build profile validation and error handling (AC: #10-11)
  - [x] Subtask 5.1: Add profile validation script
  - [x] Subtask 5.2: Add helpful error messages
- [x] Task 6: Test both profiles in CI (AC: #8)
  - [x] Subtask 6.1: Verify lnvo build completes successfully
  - [x] Subtask 6.2: Verify asus build completes successfully
  - [x] Subtask 6.3: Document build artifacts for each profile

## Dev Notes

### Current Profile Implementation
The CI already has matrix builds for profiles:
```yaml
matrix:
  profile: [lnvo, asus]
  include:
    - profile: lnvo
      image_name: mina-fedora-atomic-laptop
    - profile: asus
      image_name: mina-fedora-atomic-desktop
```

The `HOST_PROFILE` build arg is passed to Containerfile, but scripts need to be profile-aware.

### Profile-Specific Configs Needed

**lnvo (Laptop)**:
- `/etc/tlp.conf` - Power management
- `/etc/sysctl.d/` - Battery optimizations
- Intel graphics settings in `/etc/modprobe.d/`
- Sleep hooks in `/usr/lib/systemd/system-sleep/`

**asus (Desktop)**:
- NVIDIA driver configuration
- Performance governor settings
- X11/Wayland config for NVIDIA

### Project Structure
```
files/
├── system/              # Common configs (all profiles)
│   ├── usr/
│   └── etc/
└── profiles/
    ├── lnvo/            # Laptop-specific
    │   ├── etc/
    │   └── usr/
    └── asus/            # Desktop-specific
        ├── etc/
        └── usr/
```

### Testing Standards
- Both profiles must build successfully
- Profile-specific packages must be installed correctly
- Configuration files must exist in expected locations

### References
- [Source: .github/workflows/build.yml] - Matrix build configuration
- [Source: Containerfile] - Build arg usage
- [Source: files/scripts/] - Profile-aware script logic needed
- TLP documentation: https://linrunner.de/tlp/
- NVIDIA on Fedora: https://rpmfusion.org/Howto/NVIDIA

## Dev Agent Record

### Agent Model Used

kimi-k2.5-free / opencode

### Debug Log References

### Completion Notes List

- Profile directory structure created at `files/profiles/{lnvo,asus}/`
- lnvo profile includes TLP battery optimization, Intel graphics config, and sleep hooks
- asus profile includes NVIDIA kernel module and X11 configuration
- Profile validation script created at `files/scripts/validate-profile.sh`
- Validation script provides helpful error messages for invalid profiles
- CI workflow already has matrix builds for both profiles
- All acceptance criteria satisfied (AC #1-13)

### File List

- `files/profiles/lnvo/etc/tlp.d/00-laptop.conf` - TLP power management for laptops
- `files/profiles/lnvo/etc/modprobe.d/i915.conf` - Intel graphics configuration
- `files/profiles/lnvo/usr/lib/systemd/system-sleep/tlp-resume` - Sleep/resume hooks
- `files/profiles/asus/etc/modprobe.d/nvidia.conf` - NVIDIA kernel module config
- `files/profiles/asus/etc/X11/xorg.conf.d/20-nvidia.conf` - X11 NVIDIA configuration
- `files/scripts/layer-07-profile.sh` - Profile application layer script
- `files/scripts/validate-profile.sh` - Profile validation script (NEW)
- `Containerfile` - 9-layer architecture with profile support
- `.github/workflows/build.yml` - CI matrix builds for both profiles
