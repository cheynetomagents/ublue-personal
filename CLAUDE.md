# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A personal custom [bootc](https://github.com/bootc-dev/bootc) OCI image derived from `ghcr.io/ublue-os/silverblue-main:stable` (GNOME Fedora Silverblue). It layers ZFS kernel modules and a curated set of packages on top of the upstream ublue image. The built image is published to GHCR via GitHub Actions and consumed via `bootc switch` / `bootc upgrade` on the running system.

## Key Files

- `Containerfile` — Multi-stage build. Pulls prebuilt ZFS RPMs from `ghcr.io/ublue-os/akmods-zfs:main-43`, bind-mounts them, then runs `build_files/build.sh` against the Silverblue base. Ends with `bootc container lint`.
- `build_files/build.sh` — All package installation and systemd unit enables happen here. This is the primary file to edit when adding/removing packages or services.
- `Justfile` — Local build and VM-testing commands (see below).
- `disk_config/` — TOML configs for bootc-image-builder: `disk.toml` (qcow2/raw), `iso-gnome.toml`, `iso-kde.toml`.
- `.github/workflows/build.yml` — CI: builds with buildah and pushes to GHCR on every push to `main`. Signs the image with cosign using `SIGNING_SECRET`.
- `.github/workflows/build-disk.yml` — Optional CI for producing ISO/qcow2 disk images, optionally uploading to S3.

## Common Commands

```bash
just build                  # Build container image locally with podman
just lint                   # shellcheck all .sh files
just format                 # shfmt all .sh files
just check                  # Validate Justfile syntax
just fix                    # Auto-fix Justfile syntax
just clean                  # Remove build artifacts (output/, changelog.md, etc.)

# VM testing (requires prior build or pulls from remote)
just build-qcow2            # Build QCOW2 disk image via bootc-image-builder
just run-vm-qcow2           # Run QCOW2 in a podman container with QEMU, opens browser
just spawn-vm               # Run with systemd-vmspawn (GUI console)
```

## Architecture / Build Flow

1. **Multi-stage Containerfile**: The `akmods-zfs` stage is bind-mounted (not copied) so ZFS RPMs are available during `build.sh` but not baked into a separate layer.
2. **`build.sh`**: Runs inside the container build. It installs ZFS RPMs from the bind mount, adds third-party repos (Tailscale, NetBird, Ghostty COPR), installs all layered packages via `dnf5`, disables the COPR after use, and enables systemd units.
3. **CI**: GitHub Actions uses `buildah-build` (not docker) and `push-to-registry` from redhat-actions. The image is tagged `latest`, `latest.YYYYMMDD`, and `YYYYMMDD`. Cosign signing requires the `SIGNING_SECRET` repository secret.

## Important Constraints

- The `akmods-zfs` tag (`main-43`) must match the kernel flavor and Fedora release of the base image. Bump it when rebasing to a new Fedora release.
- COPRs added in `build.sh` must be disabled at the end of the script so they are not active on end-user systems.
- Do not commit `cosign.key` — it must be stored only as the `SIGNING_SECRET` GitHub Actions secret.
- The image name is derived from the GitHub repository name by the CI workflow (`IMAGE_NAME: "${{ github.event.repository.name }}"`). The local default is `ublue-personal` (first line of `Justfile`).
