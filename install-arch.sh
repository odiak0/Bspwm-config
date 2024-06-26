#!/bin/bash

### Set the script to exit on error ###

set -e

### Updating system ###

sudo pacman -Syu

read -rep "Would you like to install the packages? (y/n)" pkgs
echo

if [[ $pkgs =~ ^[Nn]$ ]]; then
    printf "No packages installed. \n"
fi

if [[ $pkgs =~ ^[Yy]$ ]]; then
    printf "Installing packages. \n"

### Installing yay ###

cd
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm --needed
rm -rf ~/yay

### Installing packages ###

yay -S --noconfirm --needed feh btop kitty flameshot xdg-desktop-portal-gtk fuse2 noto-fonts noto-fonts-emoji ttf-caladea ttf-carlito ttf-cascadia-code ttf-dejavu ttf-liberation thorium-browser-bin lightdm-gtk-greeter rofi bspwm sxhkd polybar gvfs thunar thunar-archive-plugin thunar-media-tags-plugin thunar-volman lxsession unzip wget curl pipewire wireplumber pavucontrol xarchiver base-devel linux-headers fastfetch neovim lxappearance papirus-icon-theme lightdm psmisc dunst

### Enabling lightdm ###

sudo systemctl enable lightdm
sudo systemctl set-default graphical.target
fi

read -rep "Would you like to move the configs? (y/n)" configs
echo

if [[ $configs =~ ^[Nn]$ ]]; then
    printf "No configs moved. \n"
fi

if [[ $configs =~ ^[Yy]$ ]]; then
	printf "Moving configs. \n"

### Moving configs ###

cd ~/bspwm-config/
mkdir ~/.config/bspwm
mv -vf ~/bspwm-config/bspwm/bspwmrc ~/.config/bspwm
chmod +x ~/.config/bspwm/bspwmrc
mkdir ~/.config/sxhkd
mv -vf ~/bspwm-config/sxhkd/sxhkdrc ~/.config/sxhkd
chmod +x ~/.config/sxhkd/sxhkdrc
mkdir ~/.config/kitty
mv -vf ~/bspwm-config/kitty/kitty.conf ~/.config/kitty
mkdir ~/.config/rofi
mv -vf ~/bspwm-config/rofi/config.rasi ~/.config/rofi
mkdir ~/wallpaper
mv -vf ~/bspwm-config/wallpaper/* ~/wallpaper
sudo mv -vf ~/bspwm-config/polybar/config.ini /etc/polybar

### Installing theme ###

cd /usr/share/themes/
sudo git clone https://github.com/EliverLara/Nordic.git
cd
fi

read -rep "Would you like to install nvidia drivers? (y/n)" nvidia
echo

if [[ $nvidia =~ ^[Nn]$ ]]; then
    printf "Not installed. \n"
fi

if [[ $nvidia =~ ^[Yy]$ ]]; then
	printf "Installing nvidia drivers. \n"

### Installing nvidia drivers ###

yay -S --noconfirm nvidia lib32-nvidia-utils
fi

GREEN='\033[0;32m'
printf "\n${GREEN} Now you can reboot!\n"
