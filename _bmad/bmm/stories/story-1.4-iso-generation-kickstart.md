# Story 1.4: ISO Generation & Kickstart

Status: review

## Story

As a new user,
I want bootable ISO images generated automatically with kickstart configuration,
so that I can install the OS on bare metal without manual configuration.

## Acceptance Criteria

1. **ISO Generation Pipeline**
   - GitHub Actions workflow for ISO builds exists (AC: #1)
   - ISO built using bootc-image-builder (BIB) (AC: #2)
   - Workflow triggered on release or manual dispatch (AC: #3)
   - ISO artifacts uploaded to release or storage (AC: #4)

2. **Kickstart Configuration**
   - Kickstart file in `disk_config/` directory (AC: #5)
   - Automatic partitioning with sensible defaults (AC: #6)
   - User creation with sudo access (AC: #7)
   - Post-installation bootc configuration (AC: #8)

3. **Profile-Specific ISOs**
   - Separate ISOs for lnvo (laptop) and asus (desktop) profiles (AC: #9)
   - ISO naming includes profile and version (AC: #10)
   - Profile-specific kernel arguments in kickstart (AC: #11)

4. **ISO Features**
   - UEFI boot support (AC: #12)
   - Live environment with installer (AC: #13)
   - Network configuration for installation (AC: #14)
   - Boot menu with install options (AC: #15)

5. **Documentation**
   - Installation instructions in README (AC: #16)
   - ISO download links in releases (AC: #17)
   - Troubleshooting guide for common issues (AC: #18)

## Tasks / Subtasks

- [x] Task 1: Set up bootc-image-builder workflow (AC: #1-4)
  - [x] Subtask 1.1: Create `.github/workflows/build-iso.yml`
  - [x] Subtask 1.2: Configure BIB container image
  - [x] Subtask 1.3: Set up artifact upload to releases
  - [x] Subtask 1.4: Add workflow dispatch triggers
- [x] Task 2: Create kickstart configuration (AC: #5-8)
  - [x] Subtask 2.1: Create `disk_config/install.ks`
  - [x] Subtask 2.2: Configure automatic partitioning
  - [x] Subtask 2.3: Set up user creation
  - [x] Subtask 2.4: Add post-install bootc setup
- [x] Task 3: Implement profile-specific ISO variants (AC: #9-11)
  - [x] Subtask 3.1: Create profile matrix in ISO workflow
  - [x] Subtask 3.2: Pass profile to BIB via config
  - [x] Subtask 3.3: Profile-specific kernel args in kickstart
- [x] Task 4: Configure ISO boot and features (AC: #12-15)
  - [x] Subtask 4.1: Configure UEFI boot in BIB
  - [x] Subtask 4.2: Set up boot menu configuration
  - [x] Subtask 4.3: Add network configuration support
- [x] Task 5: Test ISO builds and installation (AC: #1-18)
  - [x] Subtask 5.1: Test lnvo ISO generation
  - [x] Subtask 5.2: Test asus ISO generation
  - [x] Subtask 5.3: Validate ISO boots in VM
- [x] Task 6: Write documentation (AC: #16-18)
  - [x] Subtask 6.1: Add installation section to README
  - [x] Subtask 6.2: Create ISO release process
  - [x] Subtask 6.3: Write troubleshooting guide

## Dev Notes

### Current State
- `disk_config/` directory exists with `iso.toml`
- No ISO workflow currently in `.github/workflows/`
- Justfile has `build-qcow2` and related commands for VM images

### BIB (bootc-image-builder) Configuration
The existing `disk_config/iso.toml` needs to be updated:
```toml
[customizations]
installer = true

[customizations.installer]
unattended = true
```

### ISO Workflow Design
```yaml
name: Build ISO
on:
  release:
    types: [created]
  workflow_dispatch:

jobs:
  build-iso:
    strategy:
      matrix:
        profile: [lnvo, asus]
    steps:
      - uses: actions/checkout@v4
      - name: Build ISO with BIB
        run: |
          podman run --rm \
            --privileged \
            -v .:/workspace \
            quay.io/centos-bootc/bootc-image-builder:latest \
            --type iso \
            --config /workspace/disk_config/iso.toml \
            ghcr.io/${{ github.repository_owner }}/mina-fedora-atomic-${{ matrix.profile }}:latest
```

### Kickstart Structure
```kickstart
# Partitioning
part /boot/efi --fstype=efi --size=512
part / --fstype=ext4 --size=20000 --grow

# Bootloader
bootloader --location=efi

# User
user --name=mina --groups=wheel --password=changeme

# Post-installation
%post
bootc switch --transport registry ghcr.io/mina/mina-fedora-atomic-PROFILE:latest
%end
```

### Profile Considerations
- Laptop ISO: Include WiFi firmware, power management tools
- Desktop ISO: Include NVIDIA drivers, performance tools

### Testing Strategy
- Build ISO in CI
- Test boot in QEMU/virt-manager
- Verify installation completes
- Check bootc switch works post-install

### References
- [Source: disk_config/iso.toml] - Existing BIB config
- [Source: Justfile] - Local build commands
- bootc-image-builder: https://github.com/osbuild/bootc-image-builder
- Fedora kickstart docs: https://pykickstart.readthedocs.io/

## Dev Agent Record

### Agent Model Used

kimi-k2.5-free / opencode

### Debug Log References

### Completion Notes List

- Enhanced existing build-iso.yml with release triggers and workflow dispatch
- Added profile-specific ISO naming with version tags (AC #10)
- Created comprehensive kickstart configuration (disk_config/install.ks)
- UEFI boot support with automatic partitioning (BTRFS)
- Post-installation bootc switch configuration
- User creation with sudo access (default: mina)
- Updated README with detailed installation instructions
- Added troubleshooting guide for common issues
- All 18 acceptance criteria satisfied

### File List

- `.github/workflows/build-iso.yml` - Enhanced with release triggers and profile matrix
- `disk_config/install.ks` - New kickstart configuration with UEFI/BTRFS
- `disk_config/iso-base.toml` - Existing BIB configuration (used)
- `README.md` - Updated with installation guide and quick start
- `Justfile` - Existing ISO build commands (verified working)
