#!/bin/bash

# Colors for better readability
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"

# Function to display colored messages
print_message() {
    local message="$1"
    local color="$2"
    if [ "$color" = "$RED" ]; then
        whiptail --title "Error" --msgbox "$message" 8 78
    else
        echo -e "${color}${message}${ENDCOLOR}"
    fi
}

# Function to detect package manager
detect_package_manager() {
    if command -v apt-get &> /dev/null; then
        PACKAGER="apt-get"
        PACKAGER_INSTALL="sudo apt-get install -y"
        PACKAGER_UPDATE="sudo apt-get update && sudo apt-get upgrade -y"
    elif command -v dnf &> /dev/null; then
        PACKAGER="dnf"
        PACKAGER_INSTALL="sudo dnf install -y"
        PACKAGER_UPDATE="sudo dnf upgrade -y"
    elif command -v pacman &> /dev/null; then
        PACKAGER="pacman"
        PACKAGER_INSTALL="sudo pacman -S --noconfirm"
        PACKAGER_UPDATE="sudo pacman -Syu"
    else
        print_message "Error: Unsupported package manager. Please install packages manually." "$RED"
        exit 1
    fi
}

# Function to check and install Git
check_and_install_git() {
    if ! command -v git &> /dev/null; then
        print_message "Git is not installed. Installing Git..." "$YELLOW"
        $PACKAGER_INSTALL git
        if command -v git &> /dev/null; then
            print_message "Git has been successfully installed." "$GREEN"
        else
            print_message "Failed to install Git. Please install it manually and run this script again." "$RED"
            exit 1
        fi
    else
        print_message "Git is already installed." "$GREEN"
    fi
}

# Function to setup linuxtoolbox
setup_linuxtoolbox() {
    check_and_install_git

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

# Function to set up AUR helper (only for Arch-based systems)
setup_aur_helper() {
    if [ "$PACKAGER" != "pacman" ]; then
        return
    fi

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

    # Package manager specific packages
    local pacman_packages=(
        feh btop kitty picom flameshot xorg-xsetroot xclip xdg-desktop-portal-gtk
        fuse2 noto-fonts noto-fonts-emoji ttf-caladea ttf-carlito ttf-cascadia-code
        ttf-dejavu ttf-liberation google-chrome rofi bspwm sxhkd polybar gvfs thunar
        thunar-archive-plugin thunar-media-tags-plugin thunar-volman lxsession unzip
        wget curl pipewire wireplumber pavucontrol xarchiver base-devel linux-headers
        fastfetch neovim lxappearance papirus-icon-theme sddm psmisc dunst
    )

    local apt_packages=(
        feh btop kitty picom flameshot x11-xserver-utils xclip xdg-desktop-portal-gtk
        fuse fonts-noto fonts-noto-color-emoji fonts-crosextra-caladea fonts-crosextra-carlito
        fonts-dejavu fonts-liberation2 rofi bspwm
        sxhkd polybar gvfs-backends thunar thunar-archive-plugin thunar-media-tags-plugin
        thunar-volman lxpolkit unzip wget curl pipewire wireplumber pavucontrol
        xarchiver build-essential linux-headers-amd64 neovim lxappearance
        papirus-icon-theme sddm psmisc dunst
    )

    local dnf_packages=(
        feh btop kitty picom flameshot xsetroot xclip xdg-desktop-portal-gtk
        fuse google-noto-emoji-fonts google-carlito-fonts
        cascadia-code-fonts dejavu-sans-fonts liberation-fonts rofi bspwm sxhkd
        polybar gvfs thunar thunar-archive-plugin thunar-media-tags-plugin thunar-volman
        lxpolkit unzip wget curl pipewire wireplumber pavucontrol xarchiver kernel-devel
        fastfetch neovim lxappearance papirus-icon-theme sddm psmisc dunst
    )

    case $PACKAGER in
        pacman)
            setup_aur_helper
            "$helper" -S --noconfirm --needed "${pacman_packages[@]}"
            sudo systemctl enable sddm
            sudo systemctl set-default graphical.target
            ;;
        apt-get)
            for package in "${apt_packages[@]}"; do
                $PACKAGER_INSTALL "$package"
            done
            sudo systemctl set-default graphical.target
            ;;
        dnf)
            for package in "${dnf_packages[@]}"; do
                $PACKAGER_INSTALL "$package"
            done
            sudo systemctl set-default graphical.target
            ;;
    esac
}

# Function to move configurations
move_configs() {
    print_message "Moving configs..." "$YELLOW"

    # Configuration files to move
    config_files=(
        "bspwm/bspwmrc:$HOME/.config/bspwm/bspwmrc:exec"
        "sxhkd/sxhkdrc:$HOME/.config/sxhkd/sxhkdrc:exec"
        "kitty/kitty.conf:$HOME/.config/kitty/kitty.conf"
        "rofi/config.rasi:$HOME/.config/rofi/config.rasi"
        "polybar/config.ini:/etc/polybar/config.ini"
    )

    # Move each configuration file
    for config in "${config_files[@]}"; do
        IFS=':' read -r src dest exec_flag <<< "$config"
        src="$LINUXTOOLBOXDIR/bspwm-config/$src"
        
        if [ ! -e "$src" ]; then
            print_message "Source does not exist: $src" "$RED"
            continue
        fi

        sudo mkdir -p "$(dirname "$dest")"
        if [ -d "$src" ]; then
            if sudo mv -vf "$src" "$(dirname "$dest")"; then
                print_message "Successfully moved directory $src to $(dirname "$dest")" "$GREEN"
            else
                print_message "Failed to move directory $src to $(dirname "$dest")" "$RED"
            fi
        else
            if sudo mv -vf "$src" "$dest"; then
                print_message "Successfully moved $src to $dest" "$GREEN"
            else
                print_message "Failed to move $src to $dest" "$RED"
            fi
        fi

        if [[ "$exec_flag" == "exec" ]]; then
            sudo chmod +x "$dest"
            print_message "Made $dest executable" "$GREEN"
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
    
    case $PACKAGER in
        pacman)
            $PACKAGER_INSTALL nvidia-dkms lib32-nvidia-utils
            ;;
        apt-get)
            whiptail --title "NVIDIA Driver Installation" --msgbox "For Debian/Ubuntu-based systems, please install NVIDIA drivers manually.\n\nRefer to your distribution's documentation for the correct installation process." 10 60
            ;;
        dnf)
            whiptail --title "NVIDIA Driver Installation" --msgbox "For Fedora-based systems, please install NVIDIA drivers manually.\n\nRefer to the Fedora documentation for the correct installation process." 10 60
            ;;
        *)
            print_message "Automatic NVIDIA driver installation not supported for this distribution. Please install manually." "$RED"
            ;;
    esac
}

# Main function
main() {
    detect_package_manager
    setup_linuxtoolbox

    print_message "Updating system..." "$YELLOW"
    $PACKAGER_UPDATE

    if whiptail --title "Install Packages" --yesno "Would you like to install the packages?" 8 78; then
        install_packages
    else
        print_message "No packages installed." "$YELLOW"
    fi

    if whiptail --title "Move Configs" --yesno "Would you like to move the configs?\n\nWARNING: This will overwrite existing configuration files. Make sure you have backups if needed." 12 78; then
        move_configs
    else
        print_message "No configs moved." "$YELLOW"
    fi

    if whiptail --title "Install NVIDIA Drivers" --yesno "Would you like to install NVIDIA drivers?" 8 78; then
        install_nvidia_drivers
    else
        print_message "NVIDIA drivers not installed." "$YELLOW"
    fi

    whiptail --title "Installation Complete" --msgbox "Installation completed. You can now reboot your system!" 8 78
}

# Run the main function
main