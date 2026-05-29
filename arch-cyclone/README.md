# Arch-Cyclone

> Arch Linux para gaming y creación de contenido, optimizado para **AMD Ryzen 5 5500 + RX 580 8GB + 16GB RAM**

**Basado en:** Arch Linux + Omarchy gaming optimizations + OMAARCHY philosophy

## 🤖 OpenClaw — Agente de IA (arranca con el sistema)

- **OpenClaw** instalado y configurado como servicio systemd
- **Arranca solo**: `systemctl enable openclaw.service`
- **Auto-update**: npm install -g openclaw diario a las 3am
- **Actualizaciones del sistema**: pacman -Syu diario a las 5am, AUR (paru) semanal
- **Logs**: `/var/log/openclaw.log`, `/var/log/system-update.log`
- Gateway local: `http://localhost:18789`

### Configurar Telegram en OpenClaw (post-install)
```bash
# Editar /etc/openclaw/gateway.yml
# Cambiar telegram.enabled: false → true y añadir tu token
sudo nano /etc/openclaw/gateway.yml
sudo systemctl restart openclaw
```

## 🎮 Gaming (Steam + Proton-GE)

- **Steam** con `STEAM_RUNTIME=0` (librerías del sistema, no Steam runtime)
- **Proton-GE** via `protonup-qt` (instala desde GUI)
- **Steam Big Picture Mode** como opción de escritorio en SDDM → selecciona al hacer login
- **GameMode** auto-optimiza CPU/RAM/scheduler al lanzar juegos
- **MangoHud** overlay FPS/CPU/GPU en Vulkan/OpenGL
- **Heroic Games Launcher** Epic/GOG/Amazon Games

## 🎬 OBS Studio (streaming/grabación)

- **OBS Studio** preinstalado con soporte VA-API hardware encoding
- Configurado para AMD RX 580 (codecs: H.264, H.265, VP8, VP9)
- Pantalla + aplicaciones + audio capture listos
- Dependencias: `libndi`, `vlc`, `pipewire-jack`, `x264`, `x265`

## 📺 VLC (multimedia LAN)

- **VLC** con VA-API hardware decoding (AMD GPU)
- Optimizado para streams LAN: `network-caching=3000`
- Reproducción de red local, Samba, NFS

## 🌐 Brave navegador

- **Brave** preinstalado (ñ Mask + tracker blocking + GPU acceleration)

## 🎬 DaVinci Resolve

- **Steam** con `STEAM_RUNTIME=0` (librerías del sistema, no Steam runtime)
- **Proton-GE** via `protonup-qt` (instala desde GUI)
- **Steam Big Picture Mode** como opción de escritorio en SDDM → selecciona al hacer login
- **GameMode** auto-optimiza CPU/RAM/scheduler al lanzar juegos
- **MangoHud** overlay FPS/CPU/GPU en Vulkan/OpenGL
- **Heroic Games Launcher** Epic/GOG/Amazon Games

## 🎬 OBS Studio (streaming/grabación)

- **OBS Studio** preinstalado con soporte VA-API hardware encoding
- Configurado para AMD RX 580 (codecs: H.264, H.265, VP8, VP9)
- Pantalla + aplicaciones + audio capture listos
- Dependencias: `libndi`, `vlc`, `pipewire-jack`, `x264`, `x265`

## 📺 VLC (multimedia LAN)

- **VLC** con VA-API hardware decoding (AMD GPU)
- Optimizado para streams LAN: `network-caching=3000`
- Reproducción de red local, Samba, NFS

## 🌐 Brave navegador

- **Brave** preinstalado (ñ Mask + tracker blocking + GPU acceleration)

## 🎬 DaVinci Resolve

## 🖥️ Hardware objetivo

| Componente | Modelo |
|------------|--------|
| CPU | AMD Ryzen 5 5500 (Cezanne / Zen 3) |
| RAM | 16GB DDR4 |
| GPU | AMD RX 580 8GB (Polaris 10) |
| Almacenamiento | SSD NVMe o SATA |
| Uso | Gaming + Streaming + DaVinci Resolve |

---

## 🎮 Optimizaciones Omarchy incluidas

### Kernel
- **linux-zen** — kernel con mejores schedulers para desktop AMD
- `mitigations=off` — reduce latencia ~2-5ms en gaming
- `amdgpu.ppfeaturemask=0xffffffff` — máxima frecuencia GPU
- `amdgpu.noretry=0` — retry en vez de caída en errores de comandos GPU
- `radeon.lockup=0` — reduce lockups en RX 500 series

### CPU AMD Ryzen
- **cpupower** service → governor `performance` siempre activo
- **ryzenadj** → max performance, undervolt inteligente
- `vm.swappiness=10` — reduce swap uso, mantiene RAM libre para juegos
- `vm.overcommit_memory=1` — mejor comportamiento con Wine/Proton

### GPU AMD RX 580
- **RADV** (driver Vulkan open source) como ICD default
- **AMDVLK** como alternativa (en `/etc/environment.d/amd-gpu.conf`)
- `RADV_PERFTEST=async,ubection_ordering` — async compute + ordenamiento optimizado
- `RADV_ASYNC_PAGE_FLIP=1` — page flip asíncrono, reduce tearing
- `AMD_DEBUG=nongart` — elimina checks de GART en Polaris
- **MangoHud** preinstalado y configurado → overlay FPS/CPU/GPU en games
- DRI_PRIME=1 → fuerza GPU dedicada

### Gaming stack
- **GameMode** (gamemoded) → optimiza CPU/gov, RAM, scheduler al lanzar juegos
- **MangoHud** → overlay de rendimiento en Vulkan/OpenGL
- **Steam + ProtonGE** → compatibilidad máxima con juegos Windows
- **Wine + DXVK + VKD3D** → juegos Windows en Linux
- **Heroic Games Launcher** → Epic, GOG, Amazon Games

### Audio baja latencia
- **PipeWire** + WirePlumber con rtprio 95
- `/etc/security/limits.d/gaming.conf` → @audio rtprio 95, nice -10
- `PIPEWIRE_LATENCY=256/48000`

### Red
- `tcp_fastopen=3`, `tcp_slow_start_after_idle=0` → menor latencia en multijugador
- `net.core.rmem_max=26214400` → buffers mayores para gaming

### Estabilidad en gaming
- **earlyoom** → previene OOM (mem < 15%, swap < 10% → mata proceso)
- **systemd-swap** → swap inteligente en ZRAM/disco
- `/tmp` en tmpfs (10% RAM máx) → acceso ultra-rápido a archivos temporales

---

## 🎬 DaVinci Resolve

### Estado
DaVinci Resolve **no está preinstalado** (es software propietario).
Los scripts y dependencias para funcionando en RX 580 (Polaris) **sí están preparadas**.

### Dependencias instaladas
```
libxcrypt-compat, opencl-mesa, ocl-icd, libglvnd,
qt5-base, qt6-base, gtk3, libtinfo5, libappindicator-gtk3,
xdg-desktop-portal, fontconfig, freetype2, lm_sensors,
a52dec, faad2, lame, xvidcore, libvorbis, libtheora
```

### Post-install de DaVinci Resolve
1. Descarga DaVinci Resolve 18+ de [blackmagicdesign.com](https://www.blackmagicdesign.com/products/davinciresolve)
2. Instala el `.zip` o `.run` manualmente
3. Ejecuta:
```bash
sudo davinci-setup.sh
```
Esto configura:
- DRI_PRIME=1 (fuerza RX 580)
- AMD_VULKAN_ICD=radv
- Launcher en `/usr/bin/davinci-resolve`
- Entry en SDDM

### Verificar dependencias
```bash
sudo davinci-check-deps.sh
```

### Notas para RX 580 (Polaris 10)
- DaVinci Resolve 18+ funciona en Polaris (requiere OpenCL + Vulkan)
- La RX 580 tiene soporte completo de Vulkan 1.3 via RADV
- 8GB VRAM son suficientes para proyectos 1080p y algunos 4K

---

## 🔧 Construcción de la ISO

### Requisitos
- Una máquina con Arch Linux (o container Arch en otra distro)
- `archiso` instalado
- ~15GB espacio libre
- Conexión a internet (descarga todos los paquetes)

### Construcción local
```bash
# 1. Instalar archiso
sudo pacman -S archiso

# 2. Clonar/descargar este perfil
cd arch-cyclone

# 3. Compilar ISO
sudo ./build.sh

# 4. La ISO estará en ./out/
ls out/
```

### Compilación en GitHub Actions (sin Linux local)
1. Sube esta carpeta a un repositorio GitHub
2. Activa GitHub Actions en el repo
3. El workflow `GHA-BUILD.yml` compila la ISO automáticamente
4. Descarga el artefacto `.iso` desde Actions → Artifacts

### Construcción en macOS (con Docker/Podman)
```bash
# Con Docker (requiere imagen archlinux/base)
docker run --rm -v $(pwd):/work archlinux/base pacman -Syu --noconfirm archiso
docker run --rm -v $(pwd):/work archlinux/base /bin/bash -c "cd /work && ./build.sh"
```

---

## 📦 Instalación en el PC

### 1. Crear USB booteable
```bash
# En Linux/macOS
sudo dd if=arch-cyclone.iso of=/dev/sdX bs=4M status=progress
# (reemplaza /dev/sdX con tu USB, cuidado con el disco correcto)
```

### 2. Arrancar desde USB
- Boot menu → USB (UEFI)
- Selecciona "Arch-Cyclone (live)"

### 3. Conectar a red
```bash
# WiFi
nmtui

# Ethernet (DHCP automático)
dhcpcd
```

### 4. Particionar disco
```bash
# Particionado rápido (UEFI + BIOS)
cfdisk /dev/nvme0n1  # o /dev/sda

# Ejemplo particiones:
# /dev/nvme0n1p1 512M  EF00  EFI System
# /dev/nvme0n1p2  16G  8200  Linux swap
# /dev/nvme0n1p3  rest  8304  Linux filesystem
```

### 5. Formatear
```bash
mkfs.fat -F32 /dev/nvme0n1p1        # EFI
mkswap /dev/nvme0n1p2                 # Swap
swapon /dev/nvme0n1p2
mkfs.btrfs /dev/nvme0n1p3             # Root (o ext4/xfs)
```

### 6. Montar
```bash
mount /dev/nvme0n1p3 /mnt
mkdir -p /mnt/boot/EFI
mount /dev/nvme0n1p1 /mnt/boot/EFI
```

### 7. Instalar base Arch
```bash
pacstrap /mnt base linux-zen linux-zen-headers amd-ucode \
  base-devel nano reflector sudo networkmanager
```

### 8. Configurar
```bash
arch-chroot /mnt
# Ejecutar las configs de este perfil...
```

### 9. Post-install automático
```bash
# Dentro del chroot (o desde el live después de archinstall):
arch-chroot /mnt
/usr/local/bin/arch-cyclone-install
```

### 10. Reboot
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

### Verificar Ryzen
```bash
lscpu | grep "Model name"
# AMD Ryzen 5 5500

cpupower frequency-info | grep "current policy"
# Should show: "performance"
```

### Test MangoHud
```bash
MANGOHUD=1 glxgears
# Muestra FPS overlay
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
# Primera vez: instalar Steam runtime
# En Settings → Compatibility → ProtonGE
```

---

## 📁 Estructura del perfil archiso

```
arch-cyclone/
├── build.sh                      # Compila la ISO
├── README.md                     # Este archivo
├── GHA-BUILD.yml                 # GitHub Actions workflow
└── Profile/
    ├── packages.x86_64           # Lista de paquetes
    ├── profiledef.sh             # Definición del perfil ISO
    └── airootfs/                 # Root filesystem del live
        ├── etc/
        │   ├── environment        # Vars de entorno (GPU, gaming)
        │   ├── locale.gen         # Locales
        │   ├── mkinitcpio.conf   # Initramfs
        │   ├── pacman.conf        # Pacman + multilib
        │   └── ...                # (locale.conf, timezone, hostname, sudoers, etc.)
        ├── root/
        │   └── customize_airootfs.sh   # Script principal de personalización
        └── usr/local/bin/
            ├── arch-cyclone-install    # Post-install helper
            ├── davinci-setup.sh        # Configuración DaVinci
            └── davinci-check-deps.sh   # Verificador de dependencias
```

---

## ⚠️ Notas importantes

1. **RX 580 (Polaris 10)** es compatible con DaVinci Resolve 18+ vía Vulkan+RADV
2. **No instalar chaotic-aur** a menos que quieras software aún más bleeding-edge
3. **DaVinci Resolve** requiere el instalador oficial de blackmagicdesign.com (no está en AUR por cuestiones de licencia)
4. **Steam** con ProtonGE es la forma más fácil de jugar juegos Windows
5. **Steam Deck / OLED** — esta ISO NO está optimizada para eso, es specifically para el hardware de arriba

---

## 🔄 Actualizar el sistema

```bash
# Actualizar paquetes
sudo pacman -Syu

# Actualizar AUR (paru)
paru -Syu

# Nueva versión de kernel
sudo pacman -S linux-zen
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

---

## 🗑️ Desinstalar / Limpiar

```bash
# Limpiar caché de pacman
sudo pacman -Scc

# Limpiar AUR build files
paru -Scc

# Limpiar tmp de builds
rm -rf /tmp/archiso*
rm -rf ~/archiso_build/
```

---

**Arch-Cyclone** — *gaming Linux para el hardware que ya tienes* 🖤
