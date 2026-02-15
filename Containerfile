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
# ============================================================================
FROM ghcr.io/ublue-os/base-main:43 AS layer-1-base

FROM layer-1-base AS layer-1-setup
COPY --from=ctx /files/scripts/lib.sh /ctx/files/scripts/lib.sh
COPY --from=ctx /files/scripts/01-base.sh /ctx/files/scripts/01-base.sh
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/scripts/01-base.sh

# ============================================================================
# LAYER 2: KERNEL MODULES (Akmods)
# Common + NVIDIA (conditional on profile)
# ============================================================================
FROM ghcr.io/ublue-os/akmods:main-43 AS akmods-common
FROM ghcr.io/ublue-os/akmods-nvidia-open:main-43 AS akmods-nvidia

FROM layer-1-setup AS layer-2-akmods
COPY --from=akmods-common /rpms /tmp/akmods-common
COPY --from=akmods-nvidia /rpms /tmp/akmods-nvidia
COPY --from=ctx /files/scripts/lib.sh /ctx/files/scripts/lib.sh
COPY --from=ctx /files/scripts/02-akmods.sh /ctx/files/scripts/02-akmods.sh
ARG HOST_PROFILE
ENV HOST_PROFILE="${HOST_PROFILE}"
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/scripts/02-akmods.sh

# ============================================================================
# LAYER 3: CORE DESKTOP + FILESYSTEMS + NETWORKING
# Includes RPM Fusion and dms COPR
# ============================================================================
FROM layer-2-akmods AS layer-3-core
COPY --from=ctx /files/scripts/lib.sh /ctx/files/scripts/lib.sh
COPY --from=ctx /files/scripts/03-core.sh /ctx/files/scripts/03-core.sh
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/scripts/03-core.sh

# ============================================================================
# LAYER 4: MULTIMEDIA + CODECS + EDITORS + GIT
# Uses RPM Fusion already enabled in layer 3
# ============================================================================
FROM layer-3-core AS layer-4-media
COPY --from=ctx /files/scripts/lib.sh /ctx/files/scripts/lib.sh
COPY --from=ctx /files/scripts/04-media.sh /ctx/files/scripts/04-media.sh
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/scripts/04-media.sh

# ============================================================================
# LAYER 5: CLI TOOLS + GUI UTILITIES
# Enables remaining COPR repos, stores list for cleanup
# ============================================================================
FROM layer-4-media AS layer-5-apps
COPY --from=ctx /files/scripts/lib.sh /ctx/files/scripts/lib.sh
COPY --from=ctx /files/scripts/05-apps.sh /ctx/files/scripts/05-apps.sh
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/scripts/05-apps.sh

# ============================================================================
# LAYER 6: HARDWARE PROFILE
# Profile-specific packages, configurations, systemd services
# ============================================================================
FROM layer-5-apps AS layer-6-profile
COPY --from=ctx /files /ctx/files
ARG HOST_PROFILE
ARG IMAGE_NAME
ENV HOST_PROFILE="${HOST_PROFILE}" \
    IMAGE_NAME="${IMAGE_NAME}"
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/scripts/06-profile.sh

# ============================================================================
# LAYER 7: THEMING
# Fonts, themes, visual customization
# ============================================================================
FROM layer-6-profile AS layer-7-theme
COPY --from=ctx /files/scripts/lib.sh /ctx/files/scripts/lib.sh
COPY --from=ctx /files/scripts/07-theme.sh /ctx/files/scripts/07-theme.sh
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/scripts/07-theme.sh

# ============================================================================
# LAYER 8: FINALIZATION
# Cleanup, validation, and final setup
# ============================================================================
FROM layer-7-theme AS layer-8-final
COPY --from=ctx /files/scripts/lib.sh /ctx/files/scripts/lib.sh
COPY --from=ctx /files/scripts/08-final.sh /ctx/files/scripts/08-final.sh
ARG HOST_PROFILE
ARG IMAGE_NAME
ENV HOST_PROFILE="${HOST_PROFILE}" \
    IMAGE_NAME="${IMAGE_NAME}"
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/scripts/08-final.sh

# Final validation
RUN bootc container lint
