# Project Context

## Purpose
Personalized Fedora Atomic bootc image for Mina's devices (laptop and desktop). Builds container images with pre-configured system settings, development tools, and hardware-specific optimizations (Intel laptop, NVIDIA desktop).

## Tech Stack
- **OS**: Fedora Atomic (bootc-based)
- **Base Images**: ghcr.io/ublue-os/base-main:latest, ghcr.io/ublue-os/akmods, ghcr.io/ublue-os/akmods-nvidia-open
- **Build System**: Podman, multi-stage Containerfile
- **CI/CD**: GitHub Actions with matrix builds
- **Image Signing**: Cosign
- **Package Management**: DNF5, COPR repositories
- **Window Manager**: Niri ( compositor/window manager), DMS (display manager service)

## Project Conventions

### Code Style
- Shell scripts use `set -ouex pipefail`
- YAML files use 2-space indentation
- No comments in code (per AGENTS.md)
- Consistent naming: profile names (lnvo, asus), image names (mina-fedora-atomic-{profile})

### Architecture Patterns
- Modular build system: `build_common.sh` + `{profile}.sh` scripts
- Multi-profile builds via matrix strategy in GitHub Actions
- Akmods provided via bind mounts from separate container images
- System configuration via `/usr/lib/` paths (bootc kargs, udev, polkit, systemd presets)

### Testing Strategy
- `bootc container lint` for image validation
- No automated test suite; manual verification of builds

### Git Workflow
- Conventional commits (feat/, refactor/, chore/)
- Feature branches for new profiles or major changes
- 8 commit history after restructure (see commit log)

## Domain Context
- **bootc**: Fedora's container-based OS update system
- **akmods**: Dynamic kernel module building for kernel drivers
- **ublue-os**: Universal Blue organization providing base images and akmods
- **COPR**: Fedora's community build system for additional packages
- **systemd presets**: Pre-enable user services at image build time
- **udev rules**: Device node configuration for controllers/gamepads

## Important Constraints
- Must work with UEFI systems only (`match-architectures = ["x86_64"]`)
- Profile-specific builds (laptop vs desktop) with different hardware needs
- Image signing required for production deployments
- Build caching via GitHub Actions for speed optimization

## External Dependencies
- GitHub Container Registry (ghcr.io) for image hosting
- UBlue base images and akmods from ghcr.io/ublue-os/*
- COPR repositories: che/nerd-fonts, avengemedia/dms, atim/bottom
- Cosign for image signing verification
