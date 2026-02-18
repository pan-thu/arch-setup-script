#!/usr/bin/env bash
# =============================================================================
# Arch Linux Post-Installation Script
# Hardware: Acer Swift Go 14 OLED (SFG14-73)
#           Intel Core Ultra 5 125H + Intel Arc iGPU
# Desktop:  KDE Plasma (Wayland)
# =============================================================================

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

log()     { echo -e "${GREEN}[✔]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
err()     { echo -e "${RED}[✘]${NC} $*"; exit 1; }
section() {
    echo -e "\n${BLUE}╔══════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  ${CYAN}$*${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}\n"
}

# ── Sanity Checks ─────────────────────────────────────────────────────────────
[[ "$EUID" -eq 0 ]] && err "Run this script as your regular user, NOT root."
command -v pacman &>/dev/null || err "This script requires Arch Linux."
ping -c1 archlinux.org &>/dev/null || err "No internet connection. Connect first."

REAL_USER="${USER}"
log "Running post-install for user: ${REAL_USER}"

# ── Enable multilib (required for Steam and 32-bit libs) ─────────────────────
section "Enabling multilib repository"
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    sudo sed -i '/^#\[multilib\]/,/^#Include = \/etc\/pacman.d\/mirrorlist/{s/^#//}' /etc/pacman.conf
    log "multilib enabled"
else
    log "multilib already enabled"
fi
sudo pacman -Syu --noconfirm

# ── Base Development Tools ────────────────────────────────────────────────────
section "Base development tools"
sudo pacman -S --needed --noconfirm \
    base-devel \
    git \
    curl \
    wget \
    unzip \
    zip \
    p7zip \
    htop \
    man-db \
    man-pages \
    bash-completion \
    reflector \
    neofetch \
    tree \
    ripgrep \
    fd \
    bat \
    fzf

# ── Install yay (AUR helper) ──────────────────────────────────────────────────
section "yay AUR helper"
if ! command -v yay &>/dev/null; then
    git clone https://aur.archlinux.org/yay.git /tmp/yay-build
    (cd /tmp/yay-build && makepkg -si --noconfirm)
    rm -rf /tmp/yay-build
    log "yay installed"
else
    log "yay already installed"
fi

# ── Intel Microcode & Firmware ────────────────────────────────────────────────
# sof-firmware is REQUIRED for Intel Core Ultra (Meteor Lake) audio
# Without it, speakers/mic will not work at all
section "Intel microcode and firmware"
sudo pacman -S --needed --noconfirm \
    intel-ucode \
    linux-firmware \
    sof-firmware \
    alsa-firmware

# Regenerate initramfs so microcode is picked up on next boot
sudo mkinitcpio -P
log "initramfs regenerated"

# ── Intel Arc GPU Drivers ─────────────────────────────────────────────────────
# intel-media-driver (iHD) is the modern VAAPI driver for Arc/Iris Xe
# Do NOT install xf86-video-intel — kernel modesetting is better on Wayland
section "Intel Arc iGPU drivers"
sudo pacman -S --needed --noconfirm \
    mesa \
    lib32-mesa \
    vulkan-intel \
    lib32-vulkan-intel \
    vulkan-icd-loader \
    lib32-vulkan-icd-loader \
    intel-media-driver \
    libva-utils \
    intel-gpu-tools

# iHD is the correct VAAPI backend for Intel Arc / Iris Xe
if ! grep -q "LIBVA_DRIVER_NAME" /etc/environment 2>/dev/null; then
    echo "LIBVA_DRIVER_NAME=iHD" | sudo tee -a /etc/environment
    log "Set LIBVA_DRIVER_NAME=iHD for hardware video acceleration"
fi

# ── Audio: PipeWire ───────────────────────────────────────────────────────────
section "PipeWire audio stack"
sudo pacman -S --needed --noconfirm \
    pipewire \
    pipewire-alsa \
    pipewire-pulse \
    pipewire-jack \
    wireplumber \
    alsa-utils \
    pavucontrol \
    lib32-pipewire \
    lib32-libpulse

systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true
log "PipeWire services enabled"

# ── Bluetooth ─────────────────────────────────────────────────────────────────
section "Bluetooth"
sudo pacman -S --needed --noconfirm \
    bluez \
    bluez-utils \
    blueman

sudo systemctl enable --now bluetooth
log "Bluetooth enabled"

# ── Network ───────────────────────────────────────────────────────────────────
section "NetworkManager"
sudo pacman -S --needed --noconfirm \
    networkmanager \
    network-manager-applet \
    nm-connection-editor

sudo systemctl enable --now NetworkManager

# ── Power Management ──────────────────────────────────────────────────────────
# power-profiles-daemon integrates with KDE's Energy Saving settings
# thermald is essential for Intel Core Ultra thermal management
section "Power management"
sudo pacman -S --needed --noconfirm \
    power-profiles-daemon \
    thermald \
    acpid

sudo systemctl enable --now power-profiles-daemon thermald acpid
log "Power management services enabled"

# ── KDE Plasma Extras ─────────────────────────────────────────────────────────
section "KDE Plasma extras"
sudo pacman -S --needed --noconfirm \
    xdg-desktop-portal-kde \
    xdg-desktop-portal \
    kde-gtk-config \
    breeze-gtk \
    phonon-qt6-vlc \
    kdeconnect \
    kwallet-pam \
    kcm-fcitx5

# ── Fonts ─────────────────────────────────────────────────────────────────────
section "System fonts"
sudo pacman -S --needed --noconfirm \
    noto-fonts \
    noto-fonts-cjk \
    noto-fonts-emoji \
    ttf-liberation \
    ttf-dejavu \
    ttf-fira-code \
    ttf-jetbrains-mono \
    adobe-source-code-pro-fonts \
    otf-font-awesome

# ── Printing ──────────────────────────────────────────────────────────────────
section "Printing support"
sudo pacman -S --needed --noconfirm \
    cups \
    system-config-printer \
    ghostscript \
    cups-pdf

sudo systemctl enable --now cups

# ── Fingerprint Reader ────────────────────────────────────────────────────────
section "Fingerprint reader (fprintd)"
sudo pacman -S --needed --noconfirm fprintd
warn "Enroll fingerprint after reboot: fprintd-enroll"
warn "Then enable in KDE Settings → Users, or configure /etc/pam.d/"

# ── Desktop Integration ───────────────────────────────────────────────────────
section "Desktop integration"
sudo pacman -S --needed --noconfirm \
    flatpak \
    xdg-user-dirs \
    gvfs \
    gvfs-mtp \
    android-tools \
    ffmpeg \
    imagemagick

xdg-user-dirs-update
log "XDG user directories created"

flatpak remote-add --if-not-exists flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo
log "Flathub remote added"

# ── Main Pacman Applications ──────────────────────────────────────────────────
section "Main applications (pacman)"
sudo pacman -S --needed --noconfirm \
    firefox \
    discord \
    neovim \
    obs-studio \
    steam \
    vlc

# ── Java SDK ──────────────────────────────────────────────────────────────────
section "Java SDK (17 and 21)"
sudo pacman -S --needed --noconfirm \
    jdk21-openjdk \
    jdk17-openjdk \
    java-runtime-common \
    java-environment-common

# Java 21 as default; Android Studio works with both 17 and 21
sudo archlinux-java set java-21-openjdk
log "Default Java → 21 (switch: sudo archlinux-java set java-17-openjdk)"

# ── Virtual Machine Manager ───────────────────────────────────────────────────
section "Virtual Machine Manager (KVM/QEMU)"
sudo pacman -S --needed --noconfirm \
    virt-manager \
    qemu-full \
    libvirt \
    edk2-ovmf \
    dnsmasq \
    bridge-utils \
    iptables-nft \
    vde2 \
    dmidecode \
    swtpm

sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt,kvm "${REAL_USER}"
log "Added ${REAL_USER} to libvirt and kvm groups"

# Start and autostart the default NAT network
sudo virsh net-autostart default 2>/dev/null || true
sudo virsh net-start default 2>/dev/null || true
log "libvirt default NAT network configured"

# ── Steam 32-bit Dependencies ─────────────────────────────────────────────────
section "Steam 32-bit libraries"
sudo pacman -S --needed --noconfirm \
    lib32-mesa \
    lib32-vulkan-intel \
    lib32-alsa-plugins \
    lib32-libpulse \
    lib32-pipewire \
    steam-native-runtime \
    gamemode \
    lib32-gamemode

# ── Node.js (required for Claude Code) ───────────────────────────────────────
section "Node.js"
sudo pacman -S --needed --noconfirm nodejs npm
log "Node.js $(node --version) ready"

# ── Claude Code ───────────────────────────────────────────────────────────────
section "Claude Code (native npm install)"
sudo npm install -g @anthropic-ai/claude-code
log "Claude Code installed — run 'claude' after reboot to authenticate"

# ── AUR Applications ──────────────────────────────────────────────────────────
section "AUR applications (this may take a while — building from source)"

AUR_PACKAGES=(
    android-studio
    bitwarden
    teams-for-linux
    outlook-for-linux
    protonvpn
    spotify
    viber
)

for pkg in "${AUR_PACKAGES[@]}"; do
    log "Installing: ${pkg}"
    yay -S --needed --noconfirm --answerdiff=None --answerclean=None "${pkg}" || \
        warn "Failed to install ${pkg} — install manually later"
done

# ── Shell: Zsh (optional) ─────────────────────────────────────────────────────
section "Zsh shell"
sudo pacman -S --needed --noconfirm \
    zsh \
    zsh-completions \
    zsh-autosuggestions \
    zsh-syntax-highlighting

warn "To set zsh as your default shell: chsh -s \$(which zsh)"

# ── Regenerate Bootloader Config ──────────────────────────────────────────────
section "Updating bootloader"
if command -v bootctl &>/dev/null; then
    sudo bootctl update 2>/dev/null || true
    log "systemd-boot updated"
elif command -v grub-mkconfig &>/dev/null; then
    sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
    log "GRUB config updated"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
section "All done!"

cat <<'EOF'
╔══════════════════════════════════════════════════════╗
║  Installed                                           ║
╠══════════════════════════════════════════════════════╣
║  Drivers      Intel Arc (mesa + vulkan-intel)        ║
║               intel-media-driver (VAAPI / iHD)       ║
║               sof-firmware (Core Ultra audio)         ║
║               intel-ucode, linux-firmware            ║
║               bluez (Bluetooth)                      ║
║  Audio        PipeWire + WirePlumber                 ║
║  Apps         Firefox, Discord, Neovim               ║
║               OBS Studio, Steam, VLC                 ║
║  AUR Apps     Android Studio, Bitwarden              ║
║               Microsoft Teams, Outlook               ║
║               ProtonVPN, Spotify, Viber              ║
║  Dev          Claude Code, Node.js, Java 21/17       ║
║  VM           virt-manager + QEMU/KVM + libvirt      ║
║  KDE          xdg-portal-kde, kdeconnect, breeze-gtk ║
║  Other        Flatpak, Printing, Fingerprint reader  ║
╚══════════════════════════════════════════════════════╝
EOF

echo ""
warn "Required after reboot:"
warn "  → 'claude'                   — authenticate Claude Code"
warn "  → 'vainfo'                   — verify Intel Arc VAAPI acceleration"
warn "  → 'fprintd-enroll'           — register fingerprint"
warn "  → Log out/in for libvirt group changes to take effect"
warn "  → KDE Settings → Energy Saving — configure power profiles"
echo ""

read -rp "Reboot now? [y/N]: " confirm
[[ "${confirm,,}" == "y" ]] && sudo reboot || log "Reboot when ready."
