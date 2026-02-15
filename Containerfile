# 9-Layer Container Architecture for Mina's Fedora Atomic
# Each layer represents a distinct concern with optimal caching

# ============================================================================
# LAYER 0: BUILD CONTEXT
# Configuration files and scripts
# ============================================================================
FROM scratch AS ctx
COPY files /files

# ============================================================================
# LAYER 1: BASE OS
# Foundation layer from Universal Blue
# Cache: Long-term (base image changes infrequently)
# ============================================================================
FROM ghcr.io/ublue-os/base-main:43 AS layer-1-base

# ============================================================================
# LAYER 2: PRE-CLEANUP
# Remove default backgrounds and clean repo metadata
# Cache: Medium-term
# ============================================================================
FROM layer-1-base AS layer-2-cleanup
COPY --from=ctx /files/scripts/lib.sh /ctx/files/scripts/lib.sh
COPY --from=ctx /files/scripts/layer-01-cleanup.sh /ctx/files/scripts/layer-01-cleanup.sh
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/scripts/layer-01-cleanup.sh

# ============================================================================
# LAYER 3: ENVIRONMENT PREPARATION
# Create required directories and setup /opt
# Cache: Long-term
# ============================================================================
FROM layer-2-cleanup AS layer-3-prep
COPY --from=ctx /files/scripts/lib.sh /ctx/files/scripts/lib.sh
COPY --from=ctx /files/scripts/layer-02-prep.sh /ctx/files/scripts/layer-02-prep.sh
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/scripts/layer-02-prep.sh

# ============================================================================
# LAYER 4: COMMON KERNEL MODULES
# Common akmods for all profiles (v4l2loopback, etc.)
# Cache: Medium-term (akmods update with kernel)
# ============================================================================
FROM ghcr.io/ublue-os/akmods:main-43 AS akmods-common

FROM layer-3-prep AS layer-4-akmods
COPY --from=akmods-common /rpms /tmp/akmods-common
COPY --from=ctx /files/scripts/lib.sh /ctx/files/scripts/lib.sh
COPY --from=ctx /files/scripts/layer-03-akmods.sh /ctx/files/scripts/layer-03-akmods.sh
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/scripts/layer-03-akmods.sh

# ============================================================================
# LAYER 5: NVIDIA KERNEL MODULES (Profile-Conditional)
# NVIDIA kernel modules for desktop profile only
# Cache: Medium-term (driver updates)
# ============================================================================
FROM ghcr.io/ublue-os/akmods-nvidia-open:main-43 AS akmods-nvidia

FROM layer-4-akmods AS layer-5-nvidia
COPY --from=akmods-nvidia /rpms /tmp/akmods-nvidia
COPY --from=ctx /files/scripts/lib.sh /ctx/files/scripts/lib.sh
COPY --from=ctx /files/scripts/layer-04-nvidia.sh /ctx/files/scripts/layer-04-nvidia.sh
ARG HOST_PROFILE
ENV HOST_PROFILE="${HOST_PROFILE}"
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/scripts/layer-04-nvidia.sh

# ============================================================================
# LAYER 6: PACKAGE BASE
# Core repositories and COPR setup
# Cache: Medium-term (repo changes)
# ============================================================================
FROM layer-5-nvidia AS layer-6-packages
COPY --from=ctx /files/scripts/lib.sh /ctx/files/scripts/lib.sh
COPY --from=ctx /files/scripts/layer-05-packages.sh /ctx/files/scripts/layer-05-packages.sh
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/scripts/layer-05-packages.sh

# ============================================================================
# LAYER 7: DESKTOP ENVIRONMENT
# Niri compositor, DMS, core desktop packages
# Cache: Medium-term (desktop packages)
# ============================================================================
FROM layer-6-packages AS layer-7-desktop
COPY --from=ctx /files/scripts/lib.sh /ctx/files/scripts/lib.sh
COPY --from=ctx /files/scripts/layer-06-desktop.sh /ctx/files/scripts/layer-06-desktop.sh
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/scripts/layer-06-desktop.sh

# ============================================================================
# LAYER 8: HARDWARE PROFILE
# Profile-specific packages, configurations, systemd services
# Cache: Short-term (profile changes)
# ============================================================================
FROM layer-7-desktop AS layer-8-profile
COPY --from=ctx /files /ctx/files
ARG HOST_PROFILE
ARG IMAGE_NAME
ENV HOST_PROFILE="${HOST_PROFILE}" \
    IMAGE_NAME="${IMAGE_NAME}"
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/scripts/layer-07-profile.sh

# ============================================================================
# LAYER 9: THEMING
# Fonts, themes, visual customization
# Cache: Short-term (theme changes)
# ============================================================================
FROM layer-8-profile AS layer-9-theme
COPY --from=ctx /files/scripts/lib.sh /ctx/files/scripts/lib.sh
COPY --from=ctx /files/scripts/layer-08-theme.sh /ctx/files/scripts/layer-08-theme.sh
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/scripts/layer-08-theme.sh

# ============================================================================
# LAYER 10: FINALIZATION
# Cleanup, validation, and final setup
# Cache: Always execute (final layer)
# ============================================================================
FROM layer-9-theme AS layer-10-final
COPY --from=ctx /files/scripts/lib.sh /ctx/files/scripts/lib.sh
COPY --from=ctx /files/scripts/layer-09-final.sh /ctx/files/scripts/layer-09-final.sh
ARG HOST_PROFILE
ARG IMAGE_NAME
ENV HOST_PROFILE="${HOST_PROFILE}" \
    IMAGE_NAME="${IMAGE_NAME}"
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/scripts/layer-09-final.sh

# Final validation
RUN bootc container lint
