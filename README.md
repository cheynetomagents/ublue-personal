# ublue-personal

A personal custom [bootc](https://github.com/bootc-dev/bootc) OCI image based on [Fedora Silverblue](https://fedoraproject.org/silverblue/) via [Universal Blue](https://universal-blue.org/). Layers ZFS kernel modules and a curated set of packages on top of `ghcr.io/ublue-os/silverblue-main:stable`. Built and published daily via GitHub Actions.

**Image:** `ghcr.io/cheynetomagents/ublue-personal:latest`

## What's included

- **ZFS** — kernel modules via [ublue-os/akmods-zfs](https://github.com/ublue-os/akmods)
- **Virtualization** — libvirt, QEMU/KVM, virt-manager, distrobox
- **Networking** — Tailscale, NetBird, Wireshark, nmap, kismet
- **System tools** — cockpit (+ files, machines, networking, ostree, podman, storage), htop, iotop, nvtop, smartmontools, sysstat, lm_sensors, tmux, vim, zsh
- **Desktop** — Ghostty, GNOME tweaks, pop-shell, guake, gparted, pavucontrol, input-remapper
- **Security** — ClamAV, firejail
- **Media** — ffmpegthumbnailer, gstreamer OpenH264, totem
- **Dev/infra** — android-tools, asciinema, cloud-utils, podman-compose, podlet, sshfs, guestfs-tools

**Enabled services:** podman.socket, libvirtd, cockpit, clamav-freshclam, tailscaled, netbird, smartd, sysstat, ZFS targets

## Rebasing to this image

From any Fedora Atomic / bootc system:

```bash
sudo bootc switch ghcr.io/cheynetomagents/ublue-personal:latest
reboot
```

To upgrade after a new build is published:

```bash
sudo bootc upgrade
reboot
```

To check what image your system is currently running:

```bash
sudo bootc status
```

## CI/CD

The image is rebuilt automatically every day at 10:05am UTC and on every push to `main`. After each successful build, a smoke test workflow runs inside the published image to verify packages and systemd units.

### Manually triggering a build

1. Go to the [Actions tab](https://github.com/cheynetomagents/ublue-personal/actions/workflows/build.yml)
2. Click **"Build container image"**
3. Click **"Run workflow"** → **"Run workflow"**

To run just the tests against the current published image:

1. Go to [Actions → Test container image](https://github.com/cheynetomagents/ublue-personal/actions/workflows/test.yml)
2. Click **"Run workflow"**

### Image tags

| Tag | Description |
|-----|-------------|
| `latest` | Most recent successful build |
| `latest.YYYYMMDD` | Dated snapshot |
| `YYYYMMDD` | Same dated snapshot (short form) |

## Local development

Requires [just](https://just.systems) and podman.

```bash
just build          # Build image locally
just lint           # shellcheck all .sh files
just format         # shfmt all .sh files
just clean          # Remove build artifacts

# VM testing
just build-qcow2    # Build QCOW2 disk image
just run-vm-qcow2   # Run in QEMU via podman, opens browser
just spawn-vm       # Run with systemd-vmspawn (GUI console)
```

To run smoke tests against a locally built image:

```bash
podman run --rm --privileged \
  --entrypoint /bin/bash \
  -v "$(pwd)/build_files/test.sh:/test.sh:ro" \
  ublue-personal:latest \
  /test.sh
```

## Customization

All packages and enabled services are in [`build_files/build.sh`](./build_files/build.sh). Edit that file and push to `main` — CI rebuilds and republishes automatically.

The `akmods-zfs` tag in [`Containerfile`](./Containerfile) must match the Fedora release of the base image (`coreos-stable-43` for Fedora 43). Update the number when rebasing to a new Fedora release. See [MAINTENANCE.md](./MAINTENANCE.md) for full details.
