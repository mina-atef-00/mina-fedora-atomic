# Multi-Stage Container Architecture for Mina's Fedora Atomic
# Stages organized by change frequency for optimal caching

# ============================================================================
# STAGE 0: BUILD CONTEXT
# ============================================================================
FROM scratch AS ctx
COPY files /files

# ============================================================================
# STAGE 1: BASE SETUP
# Base OS + cleanup + environment prep
# ============================================================================
FROM ghcr.io/ublue-os/base-main:43 AS base

FROM base AS setup
COPY --from=ctx /files/scripts/lib.sh /ctx/files/scripts/lib.sh
COPY --from=ctx /files/scripts/base.sh /ctx/files/scripts/base.sh
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/scripts/base.sh

# ============================================================================
# STAGE 2: KERNEL MODULES (Akmods)
# Common + NVIDIA (conditional on profile)
# ============================================================================
FROM ghcr.io/ublue-os/akmods:main-43 AS akmods-common
FROM ghcr.io/ublue-os/akmods-nvidia-open:main-43 AS akmods-nvidia

FROM setup AS akmods
COPY --from=akmods-common /rpms /tmp/akmods-common
COPY --from=akmods-nvidia /rpms /tmp/akmods-nvidia
COPY --from=ctx /files/scripts/lib.sh /ctx/files/scripts/lib.sh
COPY --from=ctx /files/scripts/akmods.sh /ctx/files/scripts/akmods.sh
ARG HOST_PROFILE
ENV HOST_PROFILE="${HOST_PROFILE}"
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/scripts/akmods.sh

# ============================================================================
# STAGE 3: CORE DESKTOP + FILESYSTEMS + NETWORKING
# Includes RPM Fusion and dms COPR
# ============================================================================
FROM akmods AS core
COPY --from=ctx /files/scripts/lib.sh /ctx/files/scripts/lib.sh
COPY --from=ctx /files/scripts/core.sh /ctx/files/scripts/core.sh
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/scripts/core.sh

# ============================================================================
# STAGE 4: MULTIMEDIA + CODECS + EDITORS + GIT
# Uses RPM Fusion already enabled in core stage
# ============================================================================
FROM core AS media
COPY --from=ctx /files/scripts/lib.sh /ctx/files/scripts/lib.sh
COPY --from=ctx /files/scripts/media.sh /ctx/files/scripts/media.sh
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/scripts/media.sh

# ============================================================================
# STAGE 5: CLI TOOLS + GUI UTILITIES
# Enables remaining COPR repos, stores list for cleanup
# ============================================================================
FROM media AS apps
COPY --from=ctx /files/scripts/lib.sh /ctx/files/scripts/lib.sh
COPY --from=ctx /files/scripts/apps.sh /ctx/files/scripts/apps.sh
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/scripts/apps.sh

# ============================================================================
# STAGE 6: HARDWARE PROFILE
# Profile-specific packages, configurations, systemd services
# ============================================================================
FROM apps AS profile
COPY --from=ctx /files /ctx/files
ARG HOST_PROFILE
ARG IMAGE_NAME
ENV HOST_PROFILE="${HOST_PROFILE}" \
    IMAGE_NAME="${IMAGE_NAME}"
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/scripts/profile.sh

# ============================================================================
# STAGE 7: THEMING
# Fonts, themes, visual customization
# ============================================================================
FROM profile AS theme
COPY --from=ctx /files/scripts/lib.sh /ctx/files/scripts/lib.sh
COPY --from=ctx /files/scripts/theme.sh /ctx/files/scripts/theme.sh
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/scripts/theme.sh

# ============================================================================
# STAGE 8: FINALIZATION
# Cleanup, validation, and final setup
# ============================================================================
FROM theme AS final
COPY --from=ctx /files/scripts/lib.sh /ctx/files/scripts/lib.sh
COPY --from=ctx /files/scripts/final.sh /ctx/files/scripts/final.sh
ARG HOST_PROFILE
ARG IMAGE_NAME
ENV HOST_PROFILE="${HOST_PROFILE}" \
    IMAGE_NAME="${IMAGE_NAME}"
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/scripts/final.sh

# Final validation
RUN bootc container lint
