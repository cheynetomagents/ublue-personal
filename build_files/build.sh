#!/bin/bash

set -ouex pipefail

### ZFS: install the prebuilt akmod RPMs bind-mounted from the akmods-zfs stage.
### RPMs live under rpms/kmods/zfs/ in the akmods-zfs image.
ZFS_RPMS=(
    /run/akmods-zfs/rpms/kmods/zfs/kmod-zfs-*.rpm
    /run/akmods-zfs/rpms/kmods/zfs/libnvpair[0-9]-*.rpm
    /run/akmods-zfs/rpms/kmods/zfs/libuutil[0-9]-*.rpm
    /run/akmods-zfs/rpms/kmods/zfs/libzfs[0-9]-*.rpm
    /run/akmods-zfs/rpms/kmods/zfs/libzpool[0-9]-*.rpm
    /run/akmods-zfs/rpms/kmods/zfs/python3-pyzfs-*.rpm
    /run/akmods-zfs/rpms/kmods/zfs/zfs-[0-9]*.rpm
)
dnf5 install -y "${ZFS_RPMS[@]}"

### Third-party repos needed for a few packages that aren't in Fedora or RPMFusion.
# Tailscale
curl -fsSL https://pkgs.tailscale.com/stable/fedora/tailscale.repo \
    -o /etc/yum.repos.d/tailscale.repo
# NetBird
curl -fsSL https://pkgs.netbird.io/yum/netbird.repo \
    -o /etc/yum.repos.d/netbird.repo
# Ghostty (COPR -- upstream-recommended Fedora source)
dnf5 -y copr enable pgdev/ghostty

### Package overlays (the set previously layered on stock Silverblue)
dnf5 install -y \
    android-tools \
    asciinema \
    btrfs-assistant \
    clamav \
    clamd \
    cloud-utils \
    cockpit \
    cockpit-files \
    cockpit-machines \
    cockpit-networkmanager \
    cockpit-ostree \
    cockpit-podman \
    cockpit-storaged \
    distrobox \
    ffmpegthumbnailer \
    file-roller-nautilus \
    firejail \
    ghostty \
    gnome-directory-thumbnailer \
    gnome-shell-extension-pop-shell \
    gnome-shell-extension-pop-shell-shortcut-overrides \
    gnome-tweaks \
    gparted \
    gstreamer1-plugin-openh264 \
    guake \
    guestfs-tools \
    htop \
    input-remapper \
    iotop \
    kismet \
    ksmtuned \
    libvirt \
    lm_sensors \
    mc \
    netbird \
    nmap \
    nvtop \
    pavucontrol \
    podlet \
    podman-compose \
    qemu-kvm \
    qemu-virtiofsd \
    radeontop \
    smartmontools \
    sshfs \
    sysstat \
    tailscale \
    tmux \
    totem \
    vim \
    virt-manager \
    virt-viewer \
    wireshark \
    zsh

# Turn off COPRs so they aren't enabled on user systems by default.
dnf5 -y copr disable pgdev/ghostty

### Enable service units for the installed packages
systemctl enable podman.socket
systemctl enable libvirtd.service
systemctl enable cockpit.socket
systemctl enable clamav-freshclam.service
systemctl enable tailscaled.service
systemctl enable netbird.service
systemctl enable smartd.service
systemctl enable sysstat.service
systemctl enable zfs-import-cache.service
systemctl enable zfs-import.target
systemctl enable zfs-mount.service
systemctl enable zfs.target
