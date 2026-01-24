# 1. The Context
FROM scratch AS ctx
COPY files /files

FROM ghcr.io/ublue-os/akmods-nvidia-open:main-43 AS akmods-nvidia
FROM ghcr.io/ublue-os/akmods:main-43 AS akmods-common
FROM ghcr.io/ublue-os/base-main:latest

ARG HOST_PROFILE
ARG IMAGE_NAME
ARG IMAGE_VENDOR

# Env Vars for scripts to read
ENV HOST_PROFILE="${HOST_PROFILE}"
ENV IMAGE_NAME="${IMAGE_NAME}"

# 4. The Execution 
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=bind,from=akmods-nvidia,source=/rpms,target=/tmp/rpms/akmods-nvidia \
    --mount=type=bind,from=akmods-common,source=/rpms,target=/tmp/rpms/akmods-common \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/files/scripts/00-setup.sh

# 5. Linting
RUN bootc container lint
