# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /build_files

# NVIDIA Open Akmods Layer
FROM ghcr.io/ublue-os/akmods-nvidia-open:main-43 AS akmods-nvidia

# Common Akmods Layer
FROM ghcr.io/ublue-os/akmods:main-43 AS akmods-common

# Base Image
FROM ghcr.io/ublue-os/base-main:latest

ARG HOST_PROFILE=lnvo
ARG IMAGE_NAME="${IMAGE_NAME:-mina-fedora-atomic-${HOST_PROFILE}}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-mina}"

### MODIFICATIONS

# 1. Run Common Build
# We bind mount the rpms directory from the akmods image
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=bind,from=akmods-common,source=/rpms,target=/tmp/rpms/akmods-common \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build_files/build_common.sh

# 2. Run Host-Specific Build
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=bind,from=akmods-nvidia,source=/rpms,target=/tmp/rpms/akmods-nvidia \
    --mount=type=bind,from=akmods-common,source=/rpms,target=/tmp/rpms/akmods-common \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    if [ "$HOST_PROFILE" = "asus" ]; then /ctx/build_files/build_desktop.sh; fi && \
    if [ "$HOST_PROFILE" = "lnvo" ]; then /ctx/build_files/build_laptop.sh; fi

### LINTING
RUN bootc container lint
