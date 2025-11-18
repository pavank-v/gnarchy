#!/usr/bin/env bash

if [[ $EUID -eq 0 ]]; then
    echo "Please run as a normal user, not root."
    exit 1
fi

sudo -v
set -e

# =============================
# Arch gnome reproducible setup
# =============================

# colors for pretty output
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RESET="\033[0m"

echo -e "${GREEN} Starting ARCH GNOME setup...${RESET}"

# -------------
# Update system
# -------------
echo -e "${YELLOW}-> Updating system... ${RESET}"
sudo pacman -Syu --noconfirm

# --------------------
# Install yay (AUR)
# --------------------
if ! command -v yay &>/dev/null; then
    echo -e "${YELLOW}-> Installing yay... ${RESET}"
    sudo pacman -Sy --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    (cd /tmp/yay && makepkg -si --noconfirm)
fi

if ! command -v yay &>/dev/null; then
    echo "Yay installation failed, exiting."
    exit 1
fi

# -------------------
# Installing packages
# -------------------
if [[ -f pkglist.txt ]]; then
    echo -e "${YELLOW}-> Installing packages from pkglist.txt...${RESET}"
    yay -S --noconfirm --needed - < pkglist.txt
else
    echo "pkglist.txt is missing"
fi

# ----------------
# Setting up keyd
# ----------------
# echo -e "${YELLOW}-> Setting up keyd...${RESET}"
# git clone https://github.com/rvaiya/keyd /tmp/keyd
# ( cd /tmp/keyd && make && sudo make install )
# sudo systemctl enable --now keyd
#
# if [[ -d keydconfig/ ]]; then
#     echo -e "${YELLOW}-> Copying keyd config...${RESET}"
#     sudo cp -r keydconfig/* /etc/keyd/
# else
#     echo -e "keydconfig is missing"
# fi

# -----------------
# Setting up neovim
# -----------------
git clone https://github.com/pavank-v/nvim ~/.config/nvim

echo -e "${YELLOW}-> Installing Neovim plugins and LSP servers...${RESET}"
nvim --headless "+Lazy! sync" +qa || true
nvim --headless "+MasonInstallAll" +qa || true

# ---------------------------
# Copy Wallpapers to Pictures
# ---------------------------
if [[ -d wallpapers/ ]]; then
    echo -e "${YELLOW}-> Copying wallpapers to Pictures...${RESET}"
    mkdir -p ~/Pictures/wallpapers
    cp -r wallpapers/* ~/Pictures/wallpapers/
else
    echo -e "wallpapers dir is missing"
fi

# --------------------
# Install Gnome themes
# --------------------
echo -e "${YELLOW}-> Installing Orchis and Colloid themes...${RESET}"
mkdir -p ~/.themes ~/.icons

# Orchis Theme
if [[ ! -d ~/.themes/Orchis-Grey-Dark ]]; then
    git clone https://github.com/vinceliuice/Orchis-theme.git /tmp/Orchis-theme
    /tmp/Orchis-theme/install.sh -t grey -c dark --shell
fi

# Colloid Icons
if [[ ! -d ~/.icons/Colloid-Dark ]]; then
    git clone https://github.com/vinceliuice/Colloid-icon-theme.git /tmp/Colloid-icon-theme
    /tmp/Colloid-icon-theme/install.sh -t default
fi

# -------------------------
# Install Gnome Extensions
# -------------------------
if [[ -d extensions ]]; then
    echo -e "${YELLOW}-> Installing GNOME extensions from local ZIPs... ${RESET}"
    for zip in extensions/*.zip; do
        if [[ -f "$zip" ]]; then
            echo "→ Installing $(basename "$zip")"
            gnome-extensions install "$zip" --force || {
                echo "✗ Failed installing $zip"
            }
        fi
    done
else
    echo "extensions/ directory is missing. Skipping GNOME extension restore."
fi

# ----------------------
# Restore Gnome Settings
# ----------------------
if [[ -f gnome-settings.dconf ]]; then
    echo -e "${YELLOW}-> Restoring gnome settings...${RESET}"
    dconf load /org/gnome/ < gnome-settings.dconf
fi

# -----------------
# Restore dotfiles
# -----------------
if [[ -d dotfiles ]]; then
    echo -e "${YELLOW}-> Copying dotfiles...${RESET}"
    cp -r dotfiles/.[!.]* ~/
fi

# --------------------
# Restore configfiles
# --------------------
if [[ -d configfiles ]]; then
    echo -e "${YELLOW}-> Copying configfiles...${RESET}"
    cp -r configfiles/* ~/.config/
fi

# -----------------
# Set up Oh My Zsh
# -----------------
if [[ $SHELL != "/bin/zsh" ]]; then
    echo -e "${YELLOW}-> Setting zsh as default shell...${RESET}"
    chsh -s /bin/zsh
fi

if [[ ! -d ~/.oh-my-zsh ]]; then
    echo -e "${YELLOW}-> Installing Oh My Zsh... ${RESET}"
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# ------------------------------
# Cleanup
# ------------------------------
echo -e "${YELLOW}-> Cleaning temporary files...${RESET}"
rm -rf /tmp/Orchis-theme /tmp/Colloid-icon-theme /tmp/yay /tmp/keyd

# ------------------------------
# Done
# ------------------------------
echo -e "${GREEN} Setup complete!${RESET}"
echo "You may need to reboot for all GNOME settings to take effect."

