#!/bin/bash

# Colors for better readability
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"

# Check if pacman exists
if ! command -v pacman &> /dev/null; then
    print_message "Error: pacman not found. This script is intended for Arch-based systems." "$RED"
    exit 1
fi

# Function to setup linuxtoolbox
setup_linuxtoolbox() {
    LINUXTOOLBOXDIR="$HOME/linuxtoolbox"

    if [ ! -d "$LINUXTOOLBOXDIR" ]; then
        print_message "Creating linuxtoolbox directory: $LINUXTOOLBOXDIR" "$YELLOW"
        mkdir -p "$LINUXTOOLBOXDIR"
        print_message "linuxtoolbox directory created: $LINUXTOOLBOXDIR" "$GREEN"
    fi

    if [ ! -d "$LINUXTOOLBOXDIR/bspwm-config" ]; then
        print_message "Cloning bspwm-config repository into: $LINUXTOOLBOXDIR/bspwm-config" "$YELLOW"
        if git clone https://github.com/odiak0/bspwm-config "$LINUXTOOLBOXDIR/bspwm-config"; then
            print_message "Successfully cloned bspwm-config repository" "$GREEN"
        else
            print_message "Failed to clone bspwm-config repository" "$RED"
            exit 1
        fi
    fi

    cd "$LINUXTOOLBOXDIR/bspwm-config" || exit
}

# Function to display colored messages
print_message() {
    local message="$1"
    local color="$2"
    echo -e "${color}${message}${ENDCOLOR}"
}

# Function to set up AUR helper
setup_aur_helper() {
    # Ask user to choose between paru and yay
    read -rp "Do you want to use paru or yay as your AUR helper? (p/y) " aur_helper
    if [[ $aur_helper =~ ^[Pp]$ ]]; then
        helper="paru"
    else
        helper="yay"
    fi

    # Install chosen AUR helper if not present
    if ! command -v "$helper" &> /dev/null; then
        print_message "Installing $helper..." "$YELLOW"
        cd || exit
        git clone "https://aur.archlinux.org/$helper.git"
        cd "$helper" || exit
        makepkg -si --noconfirm --needed
        cd .. && rm -rf "$helper"
    fi
}

# Function to install packages
install_packages() {
    print_message "Installing packages..." "$YELLOW"

    setup_aur_helper

    # List of packages to install
    local packages=(
        feh btop kitty picom flameshot xorg-xsetroot xclip xdg-desktop-portal-gtk
        fuse2 noto-fonts noto-fonts-emoji ttf-caladea ttf-carlito ttf-cascadia-code
        ttf-dejavu ttf-liberation google-chrome rofi bspwm sxhkd polybar gvfs thunar
        thunar-archive-plugin thunar-media-tags-plugin thunar-volman lxsession unzip
        wget curl pipewire wireplumber pavucontrol xarchiver base-devel linux-headers
        fastfetch neovim lxappearance papirus-icon-theme sddm psmisc dunst
    )

    "$helper" -S --noconfirm --needed "${packages[@]}"

    # Enable sddm
    sudo systemctl enable sddm
    sudo systemctl set-default graphical.target
}

# Function to move configurations
move_configs() {
    print_message "Moving configurations..." "$YELLOW"

    # Configuration files to move
    local config_files=(
        "bspwm/bspwmrc:~/.config/bspwm/bspwmrc:exec"
        "sxhkd/sxhkdrc:~/.config/sxhkd/sxhkdrc:exec"
        "kitty/kitty.conf:~/.config/kitty/kitty.conf"
        "rofi/config.rasi:~/.config/rofi/config.rasi"
        "polybar/config.ini:/etc/polybar/config.ini"
    )

    # Move each configuration file
    for config in "${config_files[@]}"; do
        IFS=':' read -r src dest exec_flag <<< "$config"
        sudo mkdir -p "$(dirname "$dest")"
        if sudo mv -vf "$LINUXTOOLBOXDIR/bspwm-config/$src" "$dest"; then
            print_message "Successfully moved $src to $dest" "$GREEN"
            [[ "$exec_flag" == "exec" ]] && sudo chmod +x "$dest"
        else
            print_message "Failed to move $src to $dest" "$RED"
        fi
    done

    # Move wallpapers
    mkdir -p ~/wallpaper
    if mv -vf "$LINUXTOOLBOXDIR/bspwm-config/wallpaper/"* ~/wallpaper; then
        print_message "Moved wallpapers successfully" "$GREEN"
    else
        print_message "Failed to move wallpapers" "$RED"
    fi

    # Install theme
    if sudo git clone https://github.com/EliverLara/Nordic.git /usr/share/themes/Nordic; then
        print_message "Installed Nordic theme successfully" "$GREEN"
    else
        print_message "Failed to install Nordic theme" "$RED"
    fi
}

# Function to install NVIDIA drivers
install_nvidia_drivers() {
    print_message "Installing NVIDIA drivers..." "$YELLOW"
    
    # Ensure AUR helper is set up
    if [ -z "$helper" ]; then
        setup_aur_helper
    fi
    
    "$helper" -S --noconfirm nvidia-dkms lib32-nvidia-utils
}

# Main function
main() {
    setup_linuxtoolbox

    print_message "Updating system..." "$YELLOW"
    sudo pacman -Syu

    read -rp "Would you like to install the packages? (y/n) " pkgs
    if [[ $pkgs =~ ^[Yy]$ ]]; then
        install_packages
    else
        print_message "No packages installed." "$RED"
    fi

    read -rp "Would you like to move the configs? (y/n) " configs
    if [[ $configs =~ ^[Yy]$ ]]; then
        move_configs
    else
        print_message "No configs moved." "$RED"
    fi

    read -rp "Would you like to install NVIDIA drivers? (y/n) " nvidia
    if [[ $nvidia =~ ^[Yy]$ ]]; then
        install_nvidia_drivers
    else
        print_message "NVIDIA drivers not installed." "$RED"
    fi

    print_message "Installation completed. You can now reboot your system!" "$GREEN"
}

# Run the main function
main