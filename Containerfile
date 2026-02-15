# Multi-Layer Container Architecture for Mina's Fedora Atomic
# Layers organized by change frequency for optimal caching

# ============================================================================
# LAYER 0: BUILD CONTEXT
# ============================================================================
FROM scratch AS ctx
COPY files /files

# ============================================================================
# LAYER 1: BASE SETUP
# Base OS + cleanup + environment prep
# Cache: Long-term
# ============================================================================
FROM ghcr.io/ublue-os/base-main:43 AS layer-1-base

FROM layer-1-base AS layer-1-setup
COPY --from=ctx /files/scripts/lib.sh /ctx/files/scripts/lib.sh
COPY --from=ctx /files/scripts/layer-01-base.sh /ctx/files/scripts/layer-01-base.sh
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/scripts/layer-01-base.sh

# ============================================================================
# LAYER 2: COMMON KERNEL MODULES
# ============================================================================
FROM ghcr.io/ublue-os/akmods:main-43 AS akmods-common

FROM layer-1-setup AS layer-2-akmods
COPY --from=akmods-common /rpms /tmp/akmods-common
COPY --from=ctx /files/scripts/lib.sh /ctx/files/scripts/lib.sh
COPY --from=ctx /files/scripts/layer-03-akmods.sh /ctx/files/scripts/layer-03-akmods.sh
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/scripts/layer-03-akmods.sh

# ============================================================================
# LAYER 3: NVIDIA KERNEL MODULES (Profile-Conditional)
# ============================================================================
FROM ghcr.io/ublue-os/akmods-nvidia-open:main-43 AS akmods-nvidia

FROM layer-2-akmods AS layer-3-nvidia
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
# LAYER 4: PACKAGE BASE
# COPR repos + RPM Fusion
# ============================================================================
FROM layer-3-nvidia AS layer-4-packages
COPY --from=ctx /files/scripts/lib.sh /ctx/files/scripts/lib.sh
COPY --from=ctx /files/scripts/layer-05-packages.sh /ctx/files/scripts/layer-05-packages.sh
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/scripts/layer-05-packages.sh

# ============================================================================
# LAYER 5: CORE DESKTOP + FILESYSTEMS + NETWORKING
# ============================================================================
FROM layer-4-packages AS layer-5-core
COPY --from=ctx /files/scripts/lib.sh /ctx/files/scripts/lib.sh
COPY --from=ctx /files/scripts/layer-06-core.sh /ctx/files/scripts/layer-06-core.sh
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/scripts/layer-06-core.sh

# ============================================================================
# LAYER 6: MULTIMEDIA + CODECS + EDITORS + GIT
# ============================================================================
FROM layer-5-core AS layer-6-media
COPY --from=ctx /files/scripts/lib.sh /ctx/files/scripts/lib.sh
COPY --from=ctx /files/scripts/layer-07-media.sh /ctx/files/scripts/layer-07-media.sh
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/scripts/layer-07-media.sh

# ============================================================================
# LAYER 7: CLI TOOLS + GUI UTILITIES
# ============================================================================
FROM layer-6-media AS layer-7-apps
COPY --from=ctx /files/scripts/lib.sh /ctx/files/scripts/lib.sh
COPY --from=ctx /files/scripts/layer-08-apps.sh /ctx/files/scripts/layer-08-apps.sh
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/scripts/layer-08-apps.sh

# ============================================================================
# LAYER 8: HARDWARE PROFILE
# Profile-specific packages, configurations, systemd services
# ============================================================================
FROM layer-7-apps AS layer-8-profile
COPY --from=ctx /files /ctx/files
ARG HOST_PROFILE
ARG IMAGE_NAME
ENV HOST_PROFILE="${HOST_PROFILE}" \
    IMAGE_NAME="${IMAGE_NAME}"
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/scripts/layer-09-profile.sh

# ============================================================================
# LAYER 9: THEMING
# Fonts, themes, visual customization
# ============================================================================
FROM layer-8-profile AS layer-9-theme
COPY --from=ctx /files/scripts/lib.sh /ctx/files/scripts/lib.sh
COPY --from=ctx /files/scripts/layer-10-theme.sh /ctx/files/scripts/layer-10-theme.sh
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/scripts/layer-10-theme.sh

# ============================================================================
# LAYER 10: FINALIZATION
# Cleanup, validation, and final setup
# ============================================================================
FROM layer-9-theme AS layer-10-final
COPY --from=ctx /files/scripts/lib.sh /ctx/files/scripts/lib.sh
COPY --from=ctx /files/scripts/layer-11-final.sh /ctx/files/scripts/layer-11-final.sh
ARG HOST_PROFILE
ARG IMAGE_NAME
ENV HOST_PROFILE="${HOST_PROFILE}" \
    IMAGE_NAME="${IMAGE_NAME}"
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/scripts/layer-11-final.sh

# Final validation
RUN bootc container lint
