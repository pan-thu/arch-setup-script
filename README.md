# Arch Linux Setup — Acer Swift Go 14 OLED

Post-installation script and guide for a clean Arch Linux setup on the **Acer Swift Go 14 OLED (SFG14-73)**.

| | |
|---|---|
| **CPU** | Intel Core Ultra 5 125H (Meteor Lake) |
| **GPU** | Intel Arc Graphics (integrated) |
| **Display** | 2880×1800 OLED 90 Hz |
| **Desktop** | KDE Plasma 6 — Wayland |

---

## Quick Start

Run the post-install script directly after a fresh Arch install — **no cloning needed**:

```bash
curl -fsSL https://raw.githubusercontent.com/pan-thu/arch-setup-script/main/post-install.sh | bash
```

Or download and inspect it first (recommended):

```bash
curl -fsSL https://raw.githubusercontent.com/pan-thu/arch-setup-script/main/post-install.sh -o post-install.sh
less post-install.sh       # review before running
bash post-install.sh
```

> Run as your **regular user**, not root. The script uses `sudo` internally where needed.

---

## What's Installed

### Drivers & Firmware
| Package | Purpose |
|---------|---------|
| `intel-ucode` | CPU microcode updates |
| `sof-firmware` | **Required** for Intel Core Ultra audio (Meteor Lake SOF) |
| `linux-firmware` | General firmware blobs |
| `xe` (kernel module) | Modern DRM kernel driver for Xe-architecture GPUs — explicitly loaded via early KMS; `i915` is blacklisted |
| `mesa` + `lib32-mesa` | Open-source GPU userspace drivers |
| `vulkan-intel` + `lib32-vulkan-intel` | Vulkan for Intel Arc |
| `intel-media-driver` | VAAPI hardware video decode (iHD backend) |
| `bluez` | Bluetooth |

### Applications
| App | Source |
|-----|--------|
| Firefox | pacman |
| Discord | pacman |
| Neovim | pacman |
| OBS Studio | pacman |
| Steam | pacman |
| VLC | pacman |
| Android Studio | AUR |
| Bitwarden | AUR |
| Microsoft Teams | AUR |
| Outlook for Linux | AUR |
| ProtonVPN | AUR |
| Spotify | AUR |
| Viber | AUR |

### Gaming
| Package | Purpose |
|---------|---------|
| `gamemode` | CPU/GPU performance mode triggered by games |
| `gamescope` | Valve micro-compositor — FSR upscaling, fullscreen fixes |
| `mangohud` | In-game FPS / CPU / GPU overlay |
| `goverlay` | GUI config editor for MangoHud |
| `vkbasalt` | Post-processing effects for Vulkan games (sharpening, SMAA) |
| `wine` + `winetricks` | Run Windows games outside of Steam |
| `lutris` | Multi-platform game manager |
| `protonup-qt` *(AUR)* | Install and manage GE-Proton and other Proton forks |
| `heroic-games-launcher-bin` *(AUR)* | Epic Games Store + GOG launcher |
| `protontricks` *(AUR)* | Winetricks for Steam Proton game prefixes |
| `ananicy-cpp` *(AUR)* | Auto process priority daemon |
| `intel-compute-runtime` | Intel Arc OpenCL for compute workloads |
| `irqbalance` | Distribute CPU interrupts for smoother performance |
| `zram-generator` | Compressed in-RAM swap (zstd, half of RAM size) |

System-level kernel tweaks applied (`/etc/sysctl.d/99-gaming.conf`):
- `vm.swappiness = 10` — keeps game data in RAM longer
- `vm.max_map_count = 2147483642` — required by some games (Elden Ring, modded titles)
- `kernel.nmi_watchdog = 0` — reduces CPU overhead

### Dev & Tools
| Package | Purpose |
|---------|---------|
| `claude` (npm) | Claude Code CLI |
| `nodejs` + `npm` | JavaScript runtime |
| `jdk21-openjdk` + `jdk17-openjdk` | Java SDK (21 set as default) |
| `virt-manager` + `qemu-full` | KVM/QEMU virtual machines |
| `flatpak` | Flathub app support |
| `zsh` | Shell (optional, set manually) |

---

## Gaming Tips

### Initial Setup (do this first after reboot)

1. **Open ProtonUp-Qt** → Install the latest **GE-Proton**
2. **Steam** → Settings → Compatibility → *Enable Steam Play for all other titles* → select GE-Proton
3. Restart Steam

### Steam Launch Options

Add these to a game's launch options (`Right-click game → Properties → Launch Options`):

```bash
# Enable gamemode + MangoHud overlay
gamemoderun MANGOHUD=1 %command%

# gamescope: fix fullscreen/tearing, force resolution, enable FSR upscaling
gamescope -W 2880 -H 1800 -r 90 -f -- gamemoderun %command%

# FSR upscaling (render at 1080p, upscale to native)
gamescope -W 2880 -H 1800 -w 1920 -h 1080 -r 90 -f -U -- gamemoderun %command%
```

### Heroic Games Launcher (Epic/GOG)
- Open Heroic → Settings → Wine → select the GE-Proton version installed via ProtonUp-Qt
- Enable `gamemode` and `MangoHud` in Heroic's per-game settings

### Lutris
- Games → Add game → set Wine version to GE-Proton
- Enable gamemode in runner options

---

## Post-Install Checklist

- [ ] Audio works: `speaker-test -t wav -c 2`
- [ ] VAAPI works: `vainfo` — should show iHD driver + H264/HEVC/AV1 entries
- [ ] OpenCL works: `clinfo` — should show Intel Arc device
- [ ] Vulkan works: `vulkaninfo | grep deviceName`
- [ ] Bluetooth works: `bluetoothctl show`
- [ ] Fingerprint enrolled: `fprintd-enroll`
- [ ] GE-Proton installed via ProtonUp-Qt
- [ ] Steam Compatibility enabled for all titles
- [ ] `claude` authenticated: run `claude` in terminal
- [ ] KDE Energy Saving → set **Performance** profile when gaming

---

## Files

| File | Description |
|------|-------------|
| `post-install.sh` | Automated post-installation script |
| `arch-install-guide.md` | Step-by-step archinstall walkthrough |
