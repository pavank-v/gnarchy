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

install_extension() {
    UUID="$1"

    INFO=$(curl -s "https://extensions.gnome.org/extension-query/?search=$UUID")

    EXT=$(echo "$INFO" | jq -r ".extensions[] | select(.uuid==\"$UUID\")")

    if [[ -z "$EXT" ]]; then
        echo "✗ Extension not found on GNOME Extensions: $UUID"
        return
    fi

    SHELL_VERSION=$(gnome-shell --version | awk '{print $3}' | cut -d. -f1)

    VERSION=$(echo "$EXT" | jq -r ".shell_version_map.\"$SHELL_VERSION\".version")

    if [[ "$VERSION" == "null" || -z "$VERSION" ]]; then
        VERSION=$(echo "$EXT" | jq -r '.shell_version_map | to_entries | last.value.version')
    fi

    if [[ -z "$VERSION" ]]; then
        echo "✗ Could not determine version for $UUID"
        return
    fi

    ZIP_URL="https://extensions.gnome.org/download-extension/${UUID}.shell-extension.zip?version=${VERSION}"

    echo "→ Downloading $UUID (version $VERSION)"
    wget -O "/tmp/$UUID.zip" "$ZIP_URL" || {
        echo "✗ Failed downloading $UUID"
        return
    }

    echo "→ Installing $UUID"
    gnome-extensions install "/tmp/$UUID.zip" --force
}

# -------------------------
# Install Gnome Extensions
# -------------------------
if [[ -f gnome-extensions.txt ]]; then
    echo -e "${YELLOW}-> Installing GNOME extensions... ${RESET}"
    while IFS= read -r ext; do
        install_extension "$ext"
    done < gnome-extensions.txt
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
    cp -r configfiles/.[!.]* ~/.config/
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

