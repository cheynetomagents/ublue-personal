# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /

# ZFS akmod RPMs built by ublue-os.
# Tag must match the kernel flavor + Fedora release of the base image below.
# silverblue-main:stable ships Fedora's mainline kernel (~6.17.x-300.fc43).
# coreos-stable-43 tracks the same kernel series on Fedora 43.
# Bump the Fedora version suffix when rebasing onto a newer Fedora release.
FROM ghcr.io/ublue-os/akmods-zfs:coreos-stable-43 AS akmods-zfs

# Base Image: ublue-os Silverblue (GNOME, bootc-native rebuild of Fedora Silverblue)
FROM ghcr.io/ublue-os/silverblue-main:43

### MODIFICATIONS
## Packages and ZFS integration are configured in build_files/build.sh.
## The akmods-zfs layer is bind-mounted into /run/akmods-zfs so build.sh can
## install the prebuilt ZFS RPMs without baking them into the image cache.

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=bind,from=akmods-zfs,source=/,target=/run/akmods-zfs \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
