#!/bin/bash
# Image smoke tests — run inside the built container.
# Exit non-zero on any failure; CI will catch it.

set -euo pipefail

PASS=0
FAIL=0

ok() {
    echo "  PASS: $*"
    PASS=$((PASS + 1))
}

fail() {
    echo "  FAIL: $*"
    FAIL=$((FAIL + 1))
}

section() {
    echo ""
    echo "=== $* ==="
}

# ── bootc lint ────────────────────────────────────────────────────────────────
section "bootc container lint"
if bootc container lint; then
    ok "bootc container lint"
else
    fail "bootc container lint"
fi

# ── ZFS kernel module RPMs ────────────────────────────────────────────────────
section "ZFS packages"
for pkg in kmod-zfs zfs; do
    if rpm -q "$pkg" &>/dev/null; then
        ok "rpm: $pkg"
    else
        fail "rpm: $pkg not installed"
    fi
done

# ── Key layered packages ──────────────────────────────────────────────────────
section "Layered packages"
PACKAGES=(
    ghostty
    tailscale
    netbird
    libvirt
    cockpit
    distrobox
    podman-compose
    firejail
    wireshark
    htop
    tmux
    vim
    zsh
    virt-manager
    smartmontools
    sysstat
    clamav
    gparted
)

for pkg in "${PACKAGES[@]}"; do
    if rpm -q "$pkg" &>/dev/null; then
        ok "rpm: $pkg"
    else
        fail "rpm: $pkg not installed"
    fi
done

# ── Systemd units enabled ─────────────────────────────────────────────────────
section "Systemd units"
UNITS=(
    podman.socket
    libvirtd.service
    cockpit.socket
    clamav-freshclam.service
    tailscaled.service
    netbird.service
    smartd.service
    sysstat.service
    zfs-import-cache.service
    zfs-import.target
    zfs-mount.service
    zfs.target
)

for unit in "${UNITS[@]}"; do
    if systemctl is-enabled "$unit" &>/dev/null; then
        ok "systemd enabled: $unit"
    else
        fail "systemd not enabled: $unit"
    fi
done

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
