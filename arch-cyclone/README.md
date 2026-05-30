# Arch-Cyclone

> Arch Linux para **gaming y creación de contenido**, optimizado para AMD Ryzen 5 5500 + RX 580 8GB + 16GB RAM

**Basado en:** Arch Linux + Omarchy gaming optimizations

---

## 🖥️ Hardware objetivo

| Componente | Modelo |
|------------|--------|
| CPU | AMD Ryzen 5 5500 (Cezanne / Zen 3) |
| RAM | 16GB DDR4 |
| GPU | AMD RX 580 8GB (Polaris 10) |
| Almacenamiento | SSD NVMe o SATA |
| Uso | Gaming + Streaming + DaVinci Resolve |

---

## 🎮 Gaming (Steam + Proton-GE)

- **Steam** con `STEAM_RUNTIME=0` (librerías del sistema)
- **Proton-GE** via `protonup-qt` (instala desde GUI)
- **GameMode** auto-optimiza CPU/RAM/scheduler al lanzar juegos
- **MangoHud** overlay FPS/CPU/GPU en Vulkan/OpenGL
- **Heroic Games Launcher** Epic/GOG/Amazon Games
- **Wine + DXVK + VKD3D** juegos Windows en Linux

## 🎬 OBS Studio (streaming/grabación)

- **OBS Studio** preinstalado con soporte VA-API hardware encoding
- Codecs: H.264, H.265, VP8, VP9 (AMD RX 580)
- Dependencias: `libndi`, `vlc`, `pipewire-jack`, `x264`, `x265`

## 🌐 Navegador

- **Brave** preinstalado (ñ Mask + tracker blocking + GPU acceleration)

## 📺 VLC (multimedia LAN)

- VA-API hardware decoding (AMD GPU)
- Optimizado para streams LAN: `network-caching=3000`
- Reproducción de red local, Samba, NFS

## 🖥️ OpenClaw — Agente de IA

- **OpenClaw** instalado y configurado como servicio systemd
- **Arranca solo**: `systemctl enable openclaw.service`
- **Auto-update**: npm install -g openclaw diario a las 3am
- **Actualizaciones del sistema**: pacman -Syu diario a las 5am, AUR (paru) semanal
- Gateway local: `http://localhost:18789`

### Configurar Telegram en OpenClaw
```bash
sudo nano /etc/openclaw/gateway.yml
# telegram.enabled: false → true + añadir token
sudo systemctl restart openclaw
```

---

## ⚙️ Optimizaciones incluidas

### Kernel
- **linux-zen** — kernel con mejores schedulers para desktop AMD
- `mitigations=off` — reducción de latencia ~2-5ms en gaming
- `amdgpu.ppfeaturemask=0xffffffff` — máxima frecuencia GPU
- `amdgpu.noretry=0` — retry en vez de caída en errores GPU
- `radeon.lockup=0` — reduce lockups en RX 500 series

### CPU AMD Ryzen
- **cpupower** service → governor `performance` siempre activo
- **ryzenadj** → max performance, undervolt inteligente
- `vm.swappiness=10` — reduce swap, mantiene RAM libre para juegos
- `vm.overcommit_memory=1` — mejor comportamiento con Wine/Proton

### GPU AMD RX 580
- **RADV** (driver Vulkan open source) como ICD default
- **AMDVLK** alternativo en `/etc/environment.d/amd-gpu.conf`
- `RADV_PERFTEST=async,ubection_ordering` — async compute optimizado
- `RADV_ASYNC_PAGE_FLIP=1` — page flip asíncrono, menos tearing
- **MangoHud** preinstalado → overlay FPS/CPU/GPU en games
- DRI_PRIME=1 → fuerza GPU dédiée

### Audio baja latencia
- **PipeWire** + WirePlumber con rtprio 95
- `/etc/security/limits.d/gaming.conf` → @audio rtprio 95, nice -10
- `PIPEWIRE_LATENCY=256/48000`

### Red
- `tcp_fastopen=3`, `tcp_slow_start_after_idle=0`
- `net.core.rmem_max=26214400` → buffers mayores para gaming

### Estabilidad
- **earlyoom** → previene OOM (mem < 15%, swap < 10%)
- **systemd-swap** → swap inteligente en ZRAM/disco
- `/tmp` en tmpfs (10% RAM máx)

---

## 🔧 Construcción de la ISO

### Requisitos
- Arch Linux (o container Arch en otra distro)
- `archiso` instalado
- ~15GB espacio libre
- Conexión a internet

### Construcción local
```bash
sudo pacman -S archiso
sudo ./build.sh
# ISO estará en ./out/
```

### GitHub Actions (automático)
1. Sube este repo a GitHub
2. Activa Actions en el repo
3. Descarga el artefacto `.iso` desde Actions → Artifacts

---

## 📦 Instalación en el PC

### 1. Crear USB booteable
```bash
sudo dd if=arch-cyclone.iso of=/dev/sdX bs=4M status=progress
```

### 2. Arrancar desde USB
- Boot menu → USB (UEFI)
- Selecciona "Arch-Cyclone (live)"

### 3. Conectar a red
```bash
nmtui          # WiFi
dhcpcd         # Ethernet
```

### 4. Particionar (UEFI + BIOS)
```bash
cfdisk /dev/nvme0n1

# Ejemplo:
# /dev/nvme0n1p1 512M  EF00  EFI System
# /dev/nvme0n1p2  16G  8200  Linux swap
# /dev/nvme0n1p3  rest  8304  Linux filesystem
```

### 5. Formatear y montar
```bash
mkfs.fat -F32 /dev/nvme0n1p1    # EFI
mkswap /dev/nvme0n1p2 && swapon /dev/nvme0n1p2
mkfs.btrfs /dev/nvme0n1p3        # Root

mount /dev/nvme0n1p3 /mnt
mkdir -p /mnt/boot/EFI
mount /dev/nvme0n1p1 /mnt/boot/EFI
```

### 6. Instalar base Arch
```bash
pacstrap /mnt base linux-zen linux-zen-headers amd-ucode \
  base-devel nano reflector sudo networkmanager
```

### 7. Post-install automático (Desde live o chroot)
```bash
arch-chroot /mnt
/usr/local/bin/arch-cyclone-install
```

### 8. Reboot
```bash
exit
reboot
```

---

## 🚀 Primera comprobación post-arranque

### Verificar GPU AMD
```bash
glxinfo | grep "OpenGL renderer"
# Debería decir: "Polaris 10" o "AMD Radeon RX 580"

vulkaninfo | grep "GPU"
# RADV + Vulkan 1.3
```

### Test MangoHud
```bash
MANGOHUD=1 glxgears
# Muestra overlay FPS
```

### Test GameMode
```bash
gamemoded &
gamemode -s
# Status: "active"
```

### Steam
```bash
steam
# En Settings → Compatibility → ProtonGE
```

---

## 📁 Estructura del perfil archiso

```
arch-cyclone/
├── build.sh                      # Compila la ISO
├── README.md                     # Este archivo
├── GHA-BUILD.yml                 # GitHub Actions workflow
├── .gitignore
└── Profile/
    ├── packages.x86_64           # Lista de paquetes
    ├── profiledef.sh             # Definición del perfil ISO
    └── airootfs/                 # Root filesystem del live
        ├── etc/
        │   ├── environment        # Vars de entorno (GPU, gaming)
        │   ├── pacman.conf        # Pacman + multilib
        │   └── ...
        ├── root/
        │   └── customize_airootfs.sh   # Personalización
        └── usr/local/bin/
            ├── arch-cyclone-install
            └── davinci-*.sh
```

---

## 🗑️ Limpiar

```bash
# Caché pacman
sudo pacman -Scc

# AUR build files
paru -Scc

# Tmp de builds
rm -rf /tmp/archiso*
```

---

**Arch-Cyclone** — *gaming Linux para el hardware que ya tienes* 🖤
