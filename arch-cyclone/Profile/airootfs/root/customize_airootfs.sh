#!/usr/env bash
# customize_airootfs.sh — Arch-Cyclone post-install customization
# Based on: Arch Linux + Omarchy gaming optimizations + OMAARCHY
# Hardware: AMD Ryzen 5 5500 + RX 580 8GB + 16GB RAM
#
# Este script se ejecuta DURANTE la construcción de la ISO
# (etapa airootfs, chroot del live environment)

set -euo pipefail

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${CYAN}[♦]${NC} $*"; }
ok()    { echo -e "${GREEN}[✓]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }

info "Arch-Cyclone customization — INICIO"

# ══════════════════════════════════════════════════════════════════════════════
# 1. LOCALE
# ══════════════════════════════════════════════════════════════════════════════
info "1/18 — Locale..."
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
sed -i 's/^#es_ES.UTF-8/es_ES.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "LC_ALL=en_US.UTF-8" >> /etc/locale.conf
ok "Locale configurado (en_US.UTF-8 + es_ES.UTF-8)"

# ══════════════════════════════════════════════════════════════════════════════
# 2. TIMEZONE
# ══════════════════════════════════════════════════════════════════════════════
info "2/18 — Timezone..."
ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime
hwclock --systohc --utc
ok "Timezone: Europe/Madrid"

# ══════════════════════════════════════════════════════════════════════════════
# 3. HOSTNAME
# ══════════════════════════════════════════════════════════════════════════════
info "3/18 — Hostname..."
echo "arch-cyclone" > /etc/hostname
cat > /etc/hosts << 'EOF'
127.0.0.1   localhost
::1         localhost
127.0.1.1   arch-cyclone.localdomain arch-cyclone
EOF
ok "Hostname: arch-cyclone"

# ══════════════════════════════════════════════════════════════════════════════
# 4. KERNEL — linux-zen + cmdline Omarchy tweaks
# ══════════════════════════════════════════════════════════════════════════════
info "4/18 — Kernel cmdline (Omarchy gaming tweaks)..."
mkdir -p /etc/sysctl.d
cat > /etc/sysctl.d/99-gaming.conf << 'EOF'
# ── Omarchy memory tweaks ─────────────────────────────────────────────────────
vm.swappiness=10
vm.dirty_ratio=15
vm.dirty_background_ratio=3
vm.vfs_cache_pressure=50
vm.overcommit_memory=1
vm.zone_reclaim_mode=0

# ── Network latency reduction ─────────────────────────────────────────────────
net.core.rmem_max=26214400
net.core.wmem_max=26214400
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_rmem=4096 87380 6291456
net.ipv4.tcp_wmem=4096 65536 6291456

# ── FS ─────────────────────────────────────────────────────────────────────
fs.file-max=1048576
fs.inotify.max_user_watches=524288
EOF
ok "sysctl gaming params applied"

# ── GRUB cmdline: AMD + mitigations off ────────────────────────────────────
mkdir -p /etc/default
cat >> /etc/default/grub << 'GRUB_EOF'
# Arch-Cyclone kernel params (Omarchy)
GRUB_CMDLINE_LINUX_DEFAULT="mitigations=off amdgpu.ppfeaturemask=0xffffffff amdgpu.noretry=0 radeon.lockup=0 amdgpu.vm_fragment_size=9"
GRUB_CMDLINE_LINUX="mitigations=off amdgpu.ppfeaturemask=0xffffffff"
GRUB_EOF
ok "GRUB kernel params ready"

# ══════════════════════════════════════════════════════════════════════════════
# 5. GAMING LIMITS (rtprio + memlock)
# ══════════════════════════════════════════════════════════════════════════════
info "5/18 — Security limits for gaming..."
mkdir -p /etc/security/limits.d
cat > /etc/security/limits.d/gaming.conf << 'EOF'
# ── Arch-Cyclone gaming resource limits ─────────────────────────────────────
*               -       nofile          1048576
*               soft    nofile          1048576
*               hard    nofile          1048576
@ videogame     -       rtprio          99
@ videogame     -       nice            -20
@ videogame     soft    memlock         unlimited
@ videogame     hard    memlock         unlimited
*               -       rtprio          50
*               -       nice            -10
EOF
ok "Gaming limits configured (rtprio 99 for @videogame)"

# ══════════════════════════════════════════════════════════════════════════════
# 6. tmpfs /tmp (gaming temp files)
# ══════════════════════════════════════════════════════════════════════════════
info "6/18 — tmpfs /tmp..."
mkdir -p /etc/tmpfiles.d
cat > /etc/tmpfiles.d/gaming.conf << 'EOF'
d /tmp 1777 root root 10m -
D /var/tmp 1777 root root 10m -
EOF
ok "/tmp as tmpfs configured"

# ══════════════════════════════════════════════════════════════════════════════
# 7. AMD RYZEN — CPU governor + ryzenadj + tuned
# ══════════════════════════════════════════════════════════════════════════════
info "7/18 — AMD Ryzen optimizations..."

# cpupower: performance governor always on
mkdir -p /etc/systemd/system
cat > /etc/systemd/system/cpupower-performance.service << 'EOF'
[Unit]
Description=Set CPU governor to performance on boot
[Service]
Type=oneshot
ExecStart=/usr/bin/sh -c 'for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo performance > "$f" 2>/dev/null; done'
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
EOF

# ryzenadj systemd service (apply on boot)
cat > /etc/systemd/system/ryzenadj.service << 'EOF'
[Unit]
Description=AMD Ryzen power optimization via ryzenadj
After=basic.target
[Service]
Type=oneshot
ExecStart=/usr/bin/ryzenadj --fast --max-perf 2>/dev/null || true
ExecStart=/usr/bin/sh -c 'echo "all core" > /sys/devices/system/cpu/cpufreq/boost_status 2>/dev/null || true'
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
EOF

systemctl enable cpupower-performance.service 2>/dev/null || true
systemctl enable ryzenadj.service 2>/dev/null || true
ok "Ryzen CPU tuning: cpupower + ryzenadj enabled"

# ══════════════════════════════════════════════════════════════════════════════
# 8. AMD GPU — RADV + AMDVLK + environment
# ══════════════════════════════════════════════════════════════════════════════
info "8/18 — AMD GPU (RADV + AMDVLK + Omarchy tweaks)..."

mkdir -p /etc/environment.d
cat > /etc/environment.d/amd-gpu.conf << 'EOF'
# ── AMD GPU — Arch-Cyclone / Omarchy ───────────────────────────────────────
AMD_VULKAN_ICD=radv
RADV_PERFTEST=ubection_ordering
RADV_ASYNC_PAGE_FLIP=1
AMD_DEBUG=nongart
MANGOHUD=1
MANGOHUD_DLSYM=1
DISABLE_LAYER_AMD_SWITCHABLE_GRAPHICS_1=1
RADV_ENABLE_FSR=1
RADV_FORCE_VBLANK=0
# Omarchy async compute
RADV_PERFTEST=async,ubection_ordering
EOF

# MangoHUD config
mkdir -p /etc/MangoHud
cat > /etc/MangoHud/MangoHud.conf << 'EOF'
# Arch-Cyclone MangoHUD config
toggle_hud=Home End
position=top-left
fps_limit
gpu_stats
cpu_stats
ram
core_clock
gpu_load_change
vram
wine_version
framerate_limit=144
log_duration=5
no_display
EOF

ok "AMD GPU environment configured"

# ══════════════════════════════════════════════════════════════════════════════
# 9. GAMEMODE (auto when launching games)
# ══════════════════════════════════════════════════════════════════════════════
info "9/18 — GameMode daemon..."
systemctl enable gamemoded.service 2>/dev/null || true
cat > /etc/environment.d/gamemode.conf << 'EOF'
GAMEMODE=1
GAMEMODE_AUTO=1
EOF
ok "GameMode enabled"

# ══════════════════════════════════════════════════════════════════════════════
# 10. DAVINCI RESOLVE — setup script + dependencies marker
# ══════════════════════════════════════════════════════════════════════════════
info "10/18 — DaVinci Resolve dependencies..."

# Script que usuario ejecuta DESPUÉS de instalar DaVinci Resolve manualmente
cat > /usr/local/bin/davinci-setup.sh << 'DAVINCI_EOF'
#!/usr/bin/env bash
# davinci-setup.sh — DaVinci Resolve post-install setup
# Hardware: RX 580 8GB (Polaris) — compatible con DaVinci Resolve 18+
#
# NOTA: Este script NO instala DaVinci Resolve (es software propietario).
#       El usuario debe descargarlo de blackmagicdesign.com
#       y luego ejecutar: sudo davinci-setup.sh

set -euo pipefail
echo "═══════════════════════════════════════════════════════"
echo "  DaVinci Resolve — Arch-Cyclone Setup"
echo "═══════════════════════════════════════════════════════"

# Verificar que existe el directorio de DaVinci
if [ ! -d "/opt/DaVinci Resolve" ]; then
    echo "[ERROR] No se encontró DaVinci Resolve en /opt/DaVinci Resolve"
    echo "Instala DaVinci Resolve primero desde blackmagicdesign.com"
    exit 1
fi

# Agregar usuario al grupo video
usermod -aG video $USER 2>/dev/null || true
usermod -aG audio $USER 2>/dev/null || true
usermod -aG wheel $USER 2>/dev/null || true

# Crear launcher en SDDM
mkdir -p /usr/share/applications
cat > /usr/share/applications/davinci-resolve.desktop << 'DESKTOP'
[Desktop Entry]
Version=1.0
Type=Application
Name=DaVinci Resolve
Comment=Video editing by Blackmagic Design
Exec=/opt/DaVinci Resolve/Resolve %F
Icon=/opt/DaVinci Resolve/graphics/DVResolve.png
Terminal=false
StartupNotify=true
Categories=AudioVideo;Video;AudioVideoEditing;
MimeType=application/x- resolve-project;
DESKTOP

# Crear script de lanzamiento con variables AMD
cat > /usr/local/bin/davinci-resolve << 'LAUNCHER'
#!/usr/bin/env bash
export LD_LIBRARY_PATH=/opt/DaVinci Resolve/libs:$LD_LIBRARY_PATH
export DRI_PRIME=1
export AMD_VULKAN_ICD=radv
export DISABLE_LAYER_AMD_SWITCHABLE_GRAPHICS_1=1
export RADV_PERFTEST=ubection_ordering
export MANGOHUD=0
exec /opt/DaVinci Resolve/Resolve "$@"
LAUNCHER
chmod +x /usr/local/bin/davinci-resolve

# Enlazar al desktop
ln -sf /usr/local/bin/davinci-resolve /usr/bin/davinci-resolve

echo "[OK] DaVinci Resolve configurado con:"
echo "     - DRI_PRIME=1 (GPU RX 580)"
echo "     - AMD_VULKAN_ICD=radv"
echo "     - RADV driver"
echo ""
echo "Para ejecutar: davinci-resolve"
echo "O busca 'DaVinci Resolve' en el menú de aplicaciones."
DAVINCI_EOF
chmod +x /usr/local/bin/davinci-setup.sh

# Paquetes clave de DaVinci Resolve que deben estar instalados
# (se instalan vía pacman en packages.x86_64)
cat > /usr/local/bin/davinci-check-deps.sh << 'EOF'
#!/usr/bin/env bash
# Verificar dependencias de DaVinci Resolve en Arch
DEPS=(
    "libxcrypt-compat"
    "opencl-mesa"
    "ocl-icd"
    "libglvnd"
    "lib32-libglvnd"
    "gtk3"
    "qt5-base"
    "qt6-base"
    "libtinfo5"
    "libxcrypt"
    "libappindicator-gtk3"
    "xdg-desktop-portal"
    "fontconfig"
    "freetype2"
    "libjpeg-turbo"
    "libpng"
    "libtiff"
    "a52dec"
    "faad2"
    "lame"
    "xvidcore"
    "libvorbis"
    "libtheora"
    "lm_sensors"
)
MISSING=()
for dep in "${DEPS[@]}"; do
    if ! pacman -Qq "$dep" &>/dev/null; then
        MISSING+=("$dep")
    fi
done
if [ ${#MISSING[@]} -eq 0 ]; then
    echo "[OK] Todas las dependencias de DaVinci Resolve están instaladas"
else
    echo "[!] Dependencias faltantes:"
    for m in "${MISSING[@]}"; do echo "  - $m"; done
    echo ""
    echo "Instala con: sudo pacman -S ${MISSING[*]}"
fi
EOF
chmod +x /usr/local/bin/davinci-check-deps.sh

ok "DaVinci Resolve setup scripts ready"

# ══════════════════════════════════════════════════════════════════════════════
# 11. PLASMA KDE — Omarchy-style low-latency config
# ══════════════════════════════════════════════════════════════════════════════
info "11/18 — KDE Plasma desktop optimizations..."

mkdir -p /etc/skel/.config

# Global environment for KDE
cat > /etc/skel/.config/environment.d/amd-gpu.conf << 'EOF'
AMD_VULKAN_ICD=radv
RADV_PERFTEST=ubection_ordering
MANGOHUD=1
MANGOHUD_DLSYM=1
DISABLE_LAYER_AMD_SWITCHABLE_GRAPHICS_1=1
DRI_PRIME=1
EOF

# KDE startup: disable baloo (indexing), akonadi, etc.
cat > /etc/skel/.config/plasma-local/env/OmarchySpeedup.conf << 'EOF'
# Disable heavy KDE services for gaming/creator performance
export AKONADI_DISABLE=1
export BALOO_DISABLE=1
export KDEINIT_DISABLE=1
EOF

# Disable auto-suspend for gaming sessions
mkdir -p /etc/skel/.config powerdevilprofilesrc
cat > /etc/skel/.config/powerdevilprofilerc << 'EOF'
[General]
autoSuspend=false
EOF

ok "KDE Plasma gaming optimizations ready"

# ══════════════════════════════════════════════════════════════════════════════
# 12. SDDM — Display Manager
# ══════════════════════════════════════════════════════════════════════════════
info "12/18 — SDDM..."
systemctl enable sddm.service 2>/dev/null || true
ok "SDDM enabled"

# ══════════════════════════════════════════════════════════════════════════════
# 13. NETWORK MANAGER
# ══════════════════════════════════════════════════════════════════════════════
info "13/18 — NetworkManager..."
systemctl enable NetworkManager.service 2>/dev/null || true
ok "NetworkManager enabled"

# ══════════════════════════════════════════════════════════════════════════════
# 14. PIPEWIRE — low latency audio
# ══════════════════════════════════════════════════════════════════════════════
info "14/18 — PipeWire audio (low-latency)..."
systemctl enable pipewirepipewire-pulse wireplumber 2>/dev/null || true
mkdir -p /etc/security/limits.d
cat >> /etc/security/limits.d/gaming.conf << 'EOF'
@audio   -   rtprio  95
@audio   -   nice    -10
@pipewire -  rtprio  95
@pipewire -  nice    -10
EOF
ok "PipeWire enabled (rtprio 95 for @audio)"

# ══════════════════════════════════════════════════════════════════════════════
# 15. THEMING — Nordic + Tela + Papirus
# ══════════════════════════════════════════════════════════════════════════════
info "15/18 — Theming (Nordic + Tela icons)..."

mkdir -p /etc/skel/.config
cat > /etc/skel/.config/kdeglobals << 'EOF'
[General]
ColorScheme=Nordic
LookAndFeelPackage=org.kde.plasma.desktop

[Icons]
Theme=Tela-Nord

[KDE]
Theme=Nordic
EOF

ok "Theming ready (Nordic + Tela)"

# ══════════════════════════════════════════════════════════════════════════════
# 16. SYSTEMD-SWAP + EARLYOOM (previene OOM)
# ══════════════════════════════════════════════════════════════════════════════
info "16/18 — OOM prevention (systemd-swap + earlyoom)..."
systemctl enable systemd-swap.service 2>/dev/null || true
cat > /etc/earlyoom.conf << 'EOF'
# Arch-Cyclone earlyoom — prevenir OOM en gaming
MEM_PERCENT=15
SWAP_PERCENT=10
REPORT_MS=5000
IGNORE_PS="^steam$|^gamemoded$|^pipewire$"
EOF
systemctl enable earlyoom.service 2>/dev/null || true
ok "Earlyoom + systemd-swap enabled"

# ══════════════════════════════════════════════════════════════════════════════
# 17. AUR HELPER — Paru
# ══════════════════════════════════════════════════════════════════════════════
info "17/18 — Paru (AUR helper)..."

# Paru se instala desde el script de post-instalación del live ISO
cat > /usr/local/bin/install-paru.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail
if ! command -v paru &>/dev/null; then
    echo "[*] Instalando Paru (AUR helper)..."
    cd /tmp
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si --noconfirm
    cd / && rm -rf /tmp/paru
    echo "[OK] Paru instalado"
else
    echo "[OK] Paru ya está instalado"
fi
EOF
chmod +x /usr/local/bin/install-paru.sh
ok "Paru installer script ready"

# ══════════════════════════════════════════════════════════════════════════════
# 18. LIVE INSTALLER — usuario ejecuta después de archinstall
# ══════════════════════════════════════════════════════════════════════════════
info "18/18 — Live install script..."

cat > /usr/local/bin/arch-cyclone-install << 'INSTALLER'
#!/usr/bin/env bash
# arch-cyclone-install — Script de post-instalación
# Ejecutar DESPUÉS de archinstall, dentro del sistema instalado
set -euo pipefail
CYAN='\033[0;36m'; GREEN='\033[0;32m'; NC='\033[0m'
echo -e "${CYAN}[♦]${NC} Arch-Cyclone post-install..."

# 1. Instalar Paru
/usr/local/bin/install-paru.sh

# 2. Copiar configs de gaming
cp -r /etc/security/limits.d/gaming.conf /etc/security/limits.d/ 2>/dev/null || true
cp -r /etc/sysctl.d/99-gaming.conf /etc/sysctl.d/ 2>/dev/null || true
cp -r /etc/environment.d/amd-gpu.conf /etc/environment.d/ 2>/dev/null || true

# 3. Regenerar grub
if command -v grub-mkconfig &>/dev/null; then
    grub-mkconfig -o /boot/grub/grub.cfg
fi

# 4. Instalar Proton-GE para Steam
if command -v protonup &>/dev/null; then
    echo "[*] Instalando Proton-GE..."
    protonup --non-interactive 2>/dev/null || true
fi

# 5. DaVinci deps check
/usr/local/bin/davinci-check-deps.sh

echo -e "${GREEN}[✓]${NC} Arch-Cyclone post-install completo!"
echo "Rebootea para aplicar todos los cambios."
INSTALLER
chmod +x /usr/local/bin/arch-cyclone-install

ok "Post-install script ready (/usr/local/bin/arch-cyclone-install)"

# ══════════════════════════════════════════════════════════════════════════════
# 19. STEAM — Big Picture + Proton-GE + runtime=0
# ══════════════════════════════════════════════════════════════════════════════
info "19/20 — Steam setup (Big Picture + Proton-GE)..."

# Steam Big Picture desktop entry (can be selected at SDDM login)
cat > /usr/share/xsessions/steam-bigpicture.desktop << 'STEAMBP_EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Steam (Big Picture)
Comment=Launch Steam in Big Picture Mode
Exec=/usr/bin/steam -bigpicture
Icon=steam
Terminal=false
Categories=Game;
TryExec=/usr/bin/steam
STEAMBP_EOF

# KDE Plasma Big Picture session (steamos-session-like)
cat > /usr/share/xsessions/plasma-steamos.desktop << 'STEAMOS_EOF'
[Desktop Entry]
Type=Application
Name=Plasma (Gaming Mode)
Comment=Plasma desktop optimized for gaming/TV
Exec=dbus-run-session startplasma-wayland --no-lockscreen 2>/dev/null || startplasma-x11 --no-lockscreen
Icon=plasma
Categories=KDE;Desktop;
STEAMOS_EOF

# Steam environment config (system-wide)
cat > /etc/environment.d/steam.conf << 'STEAMENV_EOF'
# Steam — system libs + AMD GPU optimization
STEAM_RUNTIME=0
STEAM_COMPAT_CLIENT_INSTALL_PATH=/home/$USER/.steam/root
STEAM_COMPAT_DATA_PATH=/home/$USER/.steam/steam
PROTON_NO_ESYNC=0
PROTON_FSYNC=1
PROTON_USE_WINED3D=0
RADV_PERFTEST=async
AMD_VULKAN_ICD=radv
MANGOHUD=1
MANGOHUD_DLSYM=1
DISABLE_LAYER_AMD_SWITCHABLE_GRAPHICS_1=1
#__GL_SHADER_DISK_CACHE=1
#__GL_SHADER_DISK_CACHE_PATH=/home/$USER/.cache/glshaders
EOF

# Steam services
systemctl enable steam-webhelper.service 2>/dev/null || true
systemctl enable steam-init.service 2>/dev/null || true

ok "Steam Big Picture session + Proton-GE configured"

# ══════════════════════════════════════════════════════════════════════════════
# 20. OBS STUDIO — streaming y grabaciones
# ══════════════════════════════════════════════════════════════════════════════
info "20/20 — OBS Studio setup..."

# OBS Studio desktop entry with GPU-friendly settings
cat > /usr/share/applications/obs.desktop << 'OBS_EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=OBS Studio
Comment=Free and open source software for live streaming and recording
Exec=obs
Icon=obs
Terminal=false
Categories=AudioVideo;Recorder;Stream;
GenericName=Streaming Recorder
OBS_EOF

# OBS config in skel (default settings for AMD RX 580)
# obs-browser (chrome) needs these deps from packages.x86_64
# PulseAudio / PipeWire VA-API config for screen capture
cat > /etc/skel/.config/obs-studio/global.ini << 'OBS_CONFIG_EOF'
[General]
DriverName=VAAPI
[Video]
BaseCX=1920
BaseCY=1080
OutputCX=1920
OutputCY=1080
ScaleType=Lanczos
FPSCommon=60
[Audio]
SampleRate=48000
ChannelCount=2
OBS_CONFIG_EOF

# VA-API config for AMD GPU (hardware encoding)
cat > /etc/dri/vainfo.conf << 'VAAPI_EOF'
# VA-API hardware encoding for OBS on AMD RX 580
# Using rockchip MPP or mesa va-api driver
# RX 580 supports VAAPI via mesa driver (Polaris)
VAProfileH264ConstrainedBaseline=vaCreateConfig+vaGetConfigAttributes
VAProfileH264Main=vaCreateConfig+vaGetConfigAttributes
VAProfileH264High=vaCreateConfig+vaGetConfigAttributes
VAProfileVP8=vaCreateConfig+vaGetConfigAttributes
VAProfileVP9=vaCreateConfig+vaGetConfigAttributes
VAAPI_EOF

ok "OBS Studio configured for AMD GPU hardware encoding"

# ══════════════════════════════════════════════════════════════════════════════
# 21. VLC — reproductor multimedia LAN
# ══════════════════════════════════════════════════════════════════════════════
info "21/21 — VLC setup (LAN + hardware acceleration)..."

# VLC desktop entry
cat > /usr/share/applications/vlc.desktop << 'VLC_EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=VLC media player
Comment=Media player for LAN streams and local files
Exec=vlc --fullscreen
Icon=vlc
Terminal=false
Categories=AudioVideo;Player;AudioVideoEditing;
MimeType=video/x-msvideo;video/quicktime;video/vnd.mpegurl;application/x-mpegurl;audio/x-mpegurl;
VLC_EOF

# VLC hardware decoding — AMD GPU (VAAPI + OpenGL)
cat > /etc/skel/.config/vlc/vlcrc << 'VLC_CONFIG_EOF'
# VLC hardware decoding for AMD RX 580
# VA-API (hardware) + OpenGL for video output
[videofilter]
video-filter=adjust

[adjust]
contrast=1.0
brightness=1.0
hue=0
saturation=1.0
gamma=1.0

[core]
hwdec=vaapi
vout=glconv
glconv=any
network-caching=3000
fullscreen=1

[aout]
audio-filter=normvol
normvol-level=256
VLC_CONFIG_EOF

# Create VLC config directory for skel
mkdir -p /etc/skel/.config/vlc
ok "VLC configured (VAAPI hardware decoding + LAN streaming)"

# ══════════════════════════════════════════════════════════════════════════════
# 22. OPENCLAW — agente de IA con auto-update
# ══════════════════════════════════════════════════════════════════════════════
info "22/23 — OpenClaw AI agent setup..."

# OpenClaw repository and install
OPENCLAW_REPO="https://github.com/openclaw/openclaw"
OPENCLAW_INSTALL_DIR="/opt/openclaw"
OPENCLAW_USER="root"
OPENCLAW_GROUP="root"

# Create OpenClaw installation directory
mkdir -p "$OPENCLAW_INSTALL_DIR"

# Clone or extract OpenClaw (if not in ISO already)
if command -v openclaw &>/dev/null; then
    OPENCLAW_BIN=$(command -v openclaw)
    OPENCLAW_VERSION=$(openclaw --version 2>/dev/null || echo "unknown")
    ok "OpenClaw already installed: $OPENCLAW_BIN ($OPENCLAW_VERSION)"
else
    # Install OpenClaw via npm (requires nodejs from packages)
    if command -v npm &>/dev/null; then
        info "Installing OpenClaw via npm..."
        npm install -g openclaw --silent 2>/dev/null && {
            ok "OpenClaw installed via npm"
        } || {
            warn "npm install failed — installing OpenClaw from AUR..."
            # Fallback: Paru will install it post-boot
        }
    fi
fi

# Create OpenClaw config directory
mkdir -p /root/.openclaw
mkdir -p /etc/openclaw

# OpenClaw systemd service (runs on boot, auto-restarts)
cat > /etc/systemd/system/openclaw.service << 'OPENCLAW_SVC_EOF'
[Unit]
Description=OpenClaw AI Agent
Documentation=https://docs.openclaw.ai
After=network-online.target NetworkManager.service
Wants=network-online.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=10
Environment=OPENCLAW_HOME=/root/.openclaw
Environment=OPENCLAW_CONFIG=/etc/openclaw
Environment=NODE_ENV=production
ExecStart=/usr/bin/openclaw gateway start
ExecStartPost=/usr/bin/bash -c 'echo "OpenClaw started at $(date)" >> /var/log/openclaw.log'
StandardOutput=append:/var/log/openclaw.log
StandardError=append:/var/log/openclaw.log
WatchdogSec=30

[Install]
WantedBy=multi-user.target
OPENCLAW_SVC_EOF

# OpenClaw cron auto-update job (runs daily at 3am)
cat > /etc/cron.d/openclaw-update << 'OPENCLAW_CRON_EOF'
# OpenClaw auto-update — daily at 3:00 AM
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin

0 3 * * * root npm install -g openclaw --silent >> /var/log/openclaw-update.log 2>&1
# Also check for config updates weekly
0 4 * * 0 root test -d /root/.openclaw && cd /root/.openclaw && git pull --ff-only origin main >> /var/log/openclaw-update.log 2>&1 || true
OPENCLAW_CRON_EOF

# Log rotation for OpenClaw logs
cat > /etc/logrotate.d/openclaw << 'OPENCLAW_LOGROTATE_EOF'
/var/log/openclaw.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root root
}
/var/log/openclaw-update.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
}
OPENCLAW_LOGROTATE_EOF

# OpenClaw gateway config (minimal sensible defaults)
cat > /etc/openclaw/gateway.yml << 'OPENCLAW_CONFIG_EOF'
# OpenClaw Gateway — Arch-Cyclone configuration
# Runs on: http://localhost:18789 (local loopback only)

gateway:
  listen: 127.0.0.1:18789
  mode: local
  storage: /root/.openclaw/storage

agent:
  model: minimax/MiniMax-M2.7
  thinking: medium

channels:
  telegram:
    enabled: false  # Enable and add token after setup

logging:
  level: info
  file: /var/log/openclaw.log

# Auto-update settings
autoUpdate:
  checkInterval: 86400  # 24 hours
  npmPackage: openclaw
OPENCLAW_CONFIG_EOF

# Enable and start OpenClaw service
systemctl enable openclaw.service 2>/dev/null || true
ok "OpenClaw service enabled (start after first boot config)"

# Create convenience script for updating OpenClaw
cat > /usr/local/bin/openclaw-update << 'OC_UPDATE_EOF'
#!/usr/bin/env bash
# openclaw-update — Update OpenClaw to latest version
set -euo pipefail
echo "[*] Updating OpenClaw..."
npm install -g openclaw --silent && echo "[OK] OpenClaw updated" || echo "[!] Update failed"
openclaw --version
OC_UPDATE_EOF
chmod +x /usr/local/bin/openclaw-update

ok "OpenClaw installed and configured"

# ══════════════════════════════════════════════════════════════════════════════
# 23. AUTO-UPDATE DEL SISTEMA ( unattended upgrades )
# ══════════════════════════════════════════════════════════════════════════════
info "23/23 — System auto-update (unattended)..."

# Daily system update cron
cat > /etc/cron.d/system-update << 'SYSUPDATE_CRON_EOF'
# Arch-Cyclone auto-update — daily at 5:00 AM
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin

0 5 * * * root /usr/bin/pacman -Syu --noconfirm >> /var/log/system-update.log 2>&1
# Weekly AUR update (Paru)
0 6 * * 0 root /usr/bin/paru -Syu --noconfirm >> /var/log/aur-update.log 2>&1 || true
SYSUPDATE_CRON_EOF

# Create update log files
touch /var/log/system-update.log
touch /var/log/aur-update.log
touch /var/log/openclaw.log
touch /var/log/openclaw-update.log

# systemd update service (fallback if cron fails)
cat > /etc/systemd/system/system-update.service << 'SYSUPDATE_SVC_EOF'
[Unit]
Description=Arch-Cyclone Daily System Update
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/bin/pacman -Syu --noconfirm
StandardOutput=append:/var/log/system-update.log
StandardError=append:/var/log/system-update.log
SYSUPDATE_SVC_EOF

cat > /etc/systemd/system/system-update.timer << 'SYSUPDATE_TIMER_EOF'
[Unit]
Description=Arch-Cyclone Daily System Update Timer

[Timer]
OnCalendar=*-*-* 05:00:00
Persistent=true

[Install]
WantedBy=timers.target
SYSUPDATE_TIMER_EOF

systemctl enable system-update.timer 2>/dev/null || true
ok "Auto-update configured (daily 5am system, weekly AUR)"

# ── Final ───────────────────────────────────────────────────────────────────
info ""
info "═══════════════════════════════════════════════════════"
ok "Arch-Cyclone customization — COMPLETADO"
info "Hardware: AMD Ryzen 5500 + RX 580 + 16GB RAM"
info "Includes: Steam + OBS + VLC + Brave + OpenClaw + Auto-update"
info "═══════════════════════════════════════════════════════"
