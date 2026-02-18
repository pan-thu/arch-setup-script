# Arch Linux Installation Guide
## Acer Swift Go 14 OLED — Intel Core Ultra 5 + Intel Arc iGPU

---

## Part 1: Pre-Installation

### 1.1 Create Bootable USB
```bash
# On another Linux machine:
dd bs=4M if=archlinux-*.iso of=/dev/sdX status=progress oflag=sync

# Or use Ventoy / Rufus (Windows)
```

### 1.2 BIOS/UEFI Setup (Acer Swift Go 14)
1. Press **F2** at boot to enter BIOS
2. **Disable Secure Boot** (Main → Security → Secure Boot → Disabled)
3. Set boot mode to **UEFI only**
4. Set USB as first boot device (Boot tab)
5. **Disable Fast Boot** if present
6. Save and exit (F10)

---

## Part 2: Boot into Arch ISO

### 2.1 Connect to the Internet
**WiFi (most likely):**
```bash
iwctl
  device list                        # find your device (usually wlan0)
  station wlan0 scan
  station wlan0 get-networks
  station wlan0 connect "SSID"       # enter password when prompted
  exit

ping -c 3 archlinux.org              # verify connectivity
```

**Ethernet:** plug in and it should work automatically.

### 2.2 Verify UEFI Mode
```bash
cat /sys/firmware/efi/fw_platform_size
# Should output 64 (means UEFI 64-bit — required)
```

### 2.3 Update System Clock
```bash
timedatectl set-ntp true
```

---

## Part 3: Running archinstall

```bash
archinstall
```

### Recommended Settings in archinstall

| Setting              | Recommended Value                        |
|----------------------|------------------------------------------|
| Mirrors              | Select your country/region               |
| Locale               | en_US.UTF-8 (or your locale)             |
| Keyboard Layout      | us (or your layout)                      |
| Disk                 | Select your NVMe drive                   |
| Disk Layout          | Best-effort (ext4 or btrfs — see below)  |
| Encryption           | Optional (LUKS if desired)               |
| Bootloader           | **systemd-boot** (recommended for UEFI)  |
| Swap                 | **zram** (better than traditional swap)  |
| Hostname             | whatever you like (e.g. swiftgo)         |
| Root password        | Set a strong password                    |
| User account         | Create your main user, grant sudo        |
| Profile              | Desktop → **GNOME** or **KDE Plasma**    |
| Audio                | **PipeWire**                             |
| Kernel               | **linux** (or linux-zen for performance) |
| Additional packages  | `git intel-ucode`                        |
| Network              | **NetworkManager**                       |
| Timezone             | Your timezone                            |

> **Filesystem tip:** Choose **btrfs** if you want snapshots (Timeshift/snapper).
> Choose **ext4** for simplicity and broad compatibility.

### After archinstall completes:
```bash
# Do NOT reboot yet — update bootloader microcode first (archinstall handles
# this automatically if you added intel-ucode to additional packages)
reboot
```

---

## Part 4: First Boot

### 4.1 Login and Verify Network
```bash
nmcli device status
nmcli device wifi connect "SSID" password "yourpassword"   # if on WiFi
```

### 4.2 Enable multilib (for Steam and 32-bit libs)
Edit `/etc/pacman.conf` and uncomment these two lines:
```
[multilib]
Include = /etc/pacman.d/mirrorlist
```
Then: `sudo pacman -Sy`

### 4.3 Run the Post-Installation Script
```bash
chmod +x ~/post-install.sh
./post-install.sh
```

---

## Part 5: Hardware Notes (Intel Arc + OLED)

### Intel Arc Integrated GPU
- Requires **mesa**, **vulkan-intel**, and **intel-media-driver** for full acceleration
- Hardware video decode uses VAAPI — set `LIBVA_DRIVER_NAME=iHD`
- For hardware transcoding in OBS/VLC: verify with `vainfo`

### Intel Core Ultra 5 (Meteor Lake)
- **SOF firmware (`sof-firmware`) is mandatory** — without it, audio will not work
- `intel-ucode` must be installed and loaded by bootloader (archinstall handles this)
- `thermald` prevents thermal throttling under load

### OLED Display
- **Reduce screen timeout** in power settings to minimize burn-in risk
- Enable dark theme system-wide (GNOME: Settings → Appearance → Dark)
- Color profile: use `colormgr` or GNOME Color Manager for calibration
- Consider `icc-examin` for profile inspection

### Fingerprint Reader
If detected, install `fprintd` and enroll:
```bash
sudo pacman -S fprintd
fprintd-enroll
```
Then enable via PAM or GNOME Settings → Users.

### Suspend / Hibernate
Modern Intel platforms work well with s2idle (S0ix). If suspend is unreliable:
```bash
# Check current sleep state
cat /sys/power/mem_sleep

# Force s2idle in kernel params (add to bootloader entry):
# mem_sleep_default=s2idle
```

---

## Part 6: Post-Reboot Checklist

- [ ] Audio works (`speaker-test -t wav -c 2`)
- [ ] WiFi/Bluetooth works
- [ ] GPU acceleration works (`vainfo`, `vulkaninfo`)
- [ ] All applications launch correctly
- [ ] `claude` CLI authenticated (`claude --help`)
- [ ] libvirt VMs work (test in virt-manager)
- [ ] Steam launches and can install a game
- [ ] ProtonVPN connects

---

## Useful Commands

```bash
# Check GPU info
lspci -k | grep -A3 VGA
intel_gpu_top                        # real-time GPU usage

# Check audio devices
aplay -l
pactl info

# Check VAAPI (hardware video)
vainfo

# Check Vulkan
vulkaninfo | grep deviceName

# Check CPU microcode loaded
dmesg | grep microcode

# Check Bluetooth
bluetoothctl show
```
