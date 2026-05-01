# Maintenance Guide

This guide covers day-to-day maintenance of this custom ublue image.

## Rebasing your system onto this image

After CI builds and pushes the image to GHCR, switch your running system to it:

```bash
sudo bootc switch ghcr.io/cheynetomagents/ublue-personal:latest
```

Reboot to apply. To check the current image your system is tracking:

```bash
sudo bootc status
```

To pull the latest version of the same image (after CI pushes a new build):

```bash
sudo bootc upgrade
reboot
```

## Adding or removing packages

Edit `build_files/build.sh`. All package installation is in the `dnf5 install -y` block. Systemd units to enable are at the bottom of the file. Push to `main` — CI rebuilds and republishes the image automatically.

If a package requires a third-party repo, add the repo setup before the install block and disable it at the end of the script (after `dnf5 install`) so users don't inherit the repo on their systems.

## Bumping the Fedora release (rebasing to a new Fedora version)

Two places must be updated together:

1. **`Containerfile`** — change the base image tag to the new Fedora release number:
   ```
   FROM ghcr.io/ublue-os/silverblue-main:43
   ```
   Replace `43` with the new Fedora release number. Note: the `stable` tag no longer exists upstream.

2. **`Containerfile`** — change the `akmods-zfs` tag to match the new Fedora version:
   ```
   FROM ghcr.io/ublue-os/akmods-zfs:coreos-stable-43
   ```
   Replace `43` with the new Fedora release number (e.g. `coreos-stable-44` for Fedora 44). The `coreos-stable-<N>` tag tracks the same kernel series as Silverblue on that Fedora release. **Both tags must be bumped together** — mismatched versions will break ZFS module loading.

   Available tags can be found at: `https://github.com/ublue-os/akmods/pkgs/container/akmods-zfs`

## CI/CD overview

- **Build workflow** (`.github/workflows/build.yml`): runs daily at 10:05am UTC on every push to `main` and on pull requests. Builds with `buildah`, pushes to `ghcr.io/cheynetomagents/ublue-personal`, and signs the image with cosign.
- **Test workflow** (`.github/workflows/test.yml`): triggers automatically after a successful build. Pulls the published image and runs `build_files/test.sh` inside a container to verify packages and systemd units.
- **Disk image workflow** (`.github/workflows/build-disk.yml`): optional, produces ISO/qcow2 images.

To check build status: visit the **Actions** tab in the GitHub repository.

To trigger a manual build: go to Actions → "Build container image" → "Run workflow".

## Image tags

Each build produces three tags:
- `latest` — always points to the most recent successful build
- `latest.YYYYMMDD` — dated snapshot of `latest`
- `YYYYMMDD` — same dated snapshot without the `latest.` prefix

## Running smoke tests locally

The tests in `build_files/test.sh` are designed to run inside the built container. To run them against a locally built image:

```bash
just build
podman run --rm --privileged \
  --entrypoint /bin/bash \
  -v "$(pwd)/build_files/test.sh:/test.sh:ro" \
  ublue-personal:latest \
  /test.sh
```

Or against the published image:

```bash
podman run --rm --privileged \
  --entrypoint /bin/bash \
  -v "$(pwd)/build_files/test.sh:/test.sh:ro" \
  ghcr.io/cheynetomagents/ublue-personal:latest \
  /test.sh
```

## Cosign image signing

The CI workflow signs every pushed image using a cosign private key stored as the `SIGNING_SECRET` GitHub Actions repository secret. The corresponding public key (`cosign.pub`) is safe to commit to the repository.

To verify an image signature locally:

```bash
cosign verify --key cosign.pub ghcr.io/cheynetomagents/ublue-personal:latest
```

**Never commit `cosign.key`** — it is listed in `.gitignore`. If the key is ever exposed, generate a new keypair:

```bash
COSIGN_PASSWORD="" cosign generate-key-pair
```

Then update the `SIGNING_SECRET` in GitHub repository settings (Settings → Secrets and Variables → Actions).

## Security considerations

- **Secrets**: All secrets (`SIGNING_SECRET`, `GITHUB_TOKEN`) are managed via GitHub Actions secrets. Nothing sensitive should ever be committed to the repository.
- **`.gitignore`**: `cosign.key` is explicitly ignored. Do not remove this entry.
- **Third-party repos**: `build.sh` adds the Tailscale and NetBird repos via `curl` and enables the Ghostty COPR temporarily. These repos are disabled at the end of the script so they are not active on user systems.
- **Pinned action versions**: All GitHub Actions steps use pinned commit SHAs (not floating tags) to protect against supply-chain attacks on upstream actions.
- **PR builds**: The workflow does not push or sign images on pull requests — only on pushes to `main`. This prevents untrusted PRs from publishing images under your name.
