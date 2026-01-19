# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /

# NVIDIA Open Akmods Layer
# This image contains the nvidia-open drivers and addons
FROM ghcr.io/ublue-os/akmods-nvidia-open:main-43 AS akmods-nvidia

# Common Akmods Layer
# This image contains v4l2loopback and other common kmods
FROM ghcr.io/ublue-os/akmods:main-43 AS akmods-common

# Base Image
FROM ghcr.io/ublue-os/base-main:latest

ARG HOST_PROFILE=lnvo
ARG IMAGE_NAME="${IMAGE_NAME:-mina-fedora-atomic-${HOST_PROFILE}}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-mina}"

### MODIFICATIONS
## Modifications are done in build scripts
## We use bind mounts to provide akmods to the build scripts

# 1. Run Common Build
# We bind mount the common akmods to /tmp/rpms/akmods-common so build_common.sh can find them
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=bind,from=akmods-common,source=/rpms,target=/tmp/rpms/akmods-common \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build_files/build_common.sh

# 2. Run Host-Specific Build
# We bind mount both akmods (just in case) or specific ones. 
# build_desktop.sh needs akmods-nvidia.
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=bind,from=akmods-nvidia,source=/rpms,target=/tmp/rpms/akmods-nvidia \
    --mount=type=bind,from=akmods-common,source=/rpms,target=/tmp/rpms/akmods-common \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    if [ "$HOST_PROFILE" = "asus" ]; then /ctx/build_files/build_desktop.sh; fi && \
    if [ "$HOST_PROFILE" = "lnvo" ]; then /ctx/build_files/build_laptop.sh; fi

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
