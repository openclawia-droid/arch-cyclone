#!/usr/bin/env bash
# live-install.sh - Arch-Cyclone post-boot installation helper
# Run this AFTER booting from the live ISO and connecting to the internet.

set -euo pipefail

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════╗"
echo "║      Arch-Cyclone Live Installer          ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

# ── Check internet ────────────────────────────────────────────────────────────
if ! ping -c 1 8.8.8.8 &>/dev/null; then
    echo -e "${YELLOW}[!] No internet connection detected.${NC}"
    echo "    Please connect to WiFi or Ethernet before continuing."
    exit 1
fi
echo -e "${GREEN}[+] Internet connection OK${NC}"

# ── Launch archinstall ────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}[*] Launching archinstall for guided installation...${NC}"
echo "    Partition your drive, set user accounts, and select packages."
echo "    When archinstall finishes, run this script again from"
echo "    /usr/local/bin/live-install.sh to apply post-install tweaks."
echo ""
read -rp "Press Enter to launch archinstall, or Ctrl+C to exit: "

archinstall

# ── Post-install optimizations ───────────────────────────────────────────────
echo ""
echo -e "${GREEN}[+] Applying Arch-Cyclone post-install optimizations...${NC}"

TARGET="/mnt"
if [ ! -d "$TARGET" ]; then
    echo "Error: $TARGET does not exist. archinstall may have failed."
    exit 1
fi

# Copy all configs from live environment to installed system
cp /etc/environment.d/amd-gpu.conf  "$TARGET/etc/environment.d/"  2>/dev/null || true
cp /etc/sysctl.d/99-gaming.conf      "$TARGET/etc/sysctl.d/"       2>/dev/null || true
cp /etc/security/limits.d/gaming.conf "$TARGET/etc/security/limits.d/" 2>/dev/null || true
cp /etc/tmpfiles.d/gaming.conf       "$TARGET/etc/tmpfiles.d/"     2>/dev/null || true

# Enable gaming services
arch-chroot "$TARGET" systemctl enable NetworkManager.service    2>/dev/null || true
arch-chroot "$TARGET" systemctl enable sddm.service             2>/dev/null || true
arch-chroot "$TARGET" systemctl enable gamemoded.service        2>/dev/null || true
arch-chroot "$TARGET" systemctl enable cpupower-performance.service 2>/dev/null || true
arch-chroot "$TARGET" systemctl enable earlyoom.service         2>/dev/null || true
arch-chroot "$TARGET" systemctl enable systemd-swap.service      2>/dev/null || true
arch-chroot "$TARGET" systemctl enable pipewirepipewire-pulse wireplumber 2>/dev/null || true

# ── Paru AUR helper ───────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}[*] Installing Paru AUR helper...${NC}"
arch-chroot "$TARGET" /usr/local/bin/install-paru.sh 2>/dev/null || true

# ── Steam post-install ────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}[*] Steam setup...${NC}"

# Create Steam compat directory for Proton-GE
arch-chroot "$TARGET" mkdir -p /home/\${SUDO_USER:-$USER}/.steam/root/compatibility
arch-chroot "$TARGET" mkdir -p /home/\${SUDO_USER:-$USER}/.steam/root/compatibility/downloads/proton
arch-chroot "$TARGET" chmod -R 755 /home/*/.steam 2>/dev/null || true

# Steam environment for AMD GPU (runtime=0 uses system libs instead of steam runtime)
arch-chroot "$TARGET" mkdir -p /etc/environment.d
cat > "$TARGET/etc/environment.d/steam.conf" << 'STEAM_EOF'
# Steam — use system libraries instead of Steam runtime for AMD GPU
STEAM_RUNTIME=0
STEAM_COMPAT_CLIENT_INSTALL_PATH=/home/$USER/.steam/root
PROTON_NO_ESYNC=0
PROTON_FSYNC=1
PROTON_USE_WINED3D=0
MANGOHUD=1
RADV_PERFTEST=async
AMD_VULKAN_ICD=radv
STEAM_EOF

# ── Proton-GE helper ─────────────────────────────────────────────────────────
# protonup-qt is in packages.x86_64 — verify it's installed
arch-chroot "$TARGET" which protonup-qt &>/dev/null && {
    echo -e "${GREEN}[+] protonup-qt found — use it to install Proton-GE${NC}"
} || {
    echo -e "${YELLOW}[!] protonup-qt not found — install with: paru -S protonup-qt${NC}"
}

# ── Final message ────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║           Arch-Cyclone Installation Complete!                  ║"
echo "╠═══════════════════════════════════════════════════════════════╣"
echo "║                                                               ║"
echo "║  1. Reboot                                                    ║"
echo "║  2. Log in with your user                                    ║"
echo "║  3. Install Proton-GE: protonup-qt                           ║"
echo "║     (Steam → Settings → Compatibility → Proton-GE)            ║"
echo "║  4. Verify GPU:  mangohud glxgears                           ║"
echo "║  5. Launch Steam and enjoy!                                  ║"
echo "║                                                               ║"
echo "║  For DaVinci Resolve:                                          ║"
echo "║    1. Download from blackmagicdesign.com                       ║"
echo "║    2. sudo davinci-setup.sh                                  ║"
echo "║    3. davinci-resolve                                         ║"
echo "║                                                               ║"
echo "║  Docs:  cat /usr/local/bin/README.arch-cyclone                ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"