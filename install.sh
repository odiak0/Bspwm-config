#!/bin/bash

GREEN="\e[32m"
ENDCOLOR="\e[0m"

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

cd || exit
git clone https://aur.archlinux.org/yay.git
cd yay || exit
makepkg -si --noconfirm --needed
rm -rf ~/yay

### Installing packages ###

yay -S --noconfirm --needed feh btop kitty picom flameshot xorg-xsetroot xclip xdg-desktop-portal-gtk fuse2 noto-fonts noto-fonts-emoji ttf-caladea ttf-carlito ttf-cascadia-code ttf-dejavu ttf-liberation thorium-browser-bin rofi bspwm sxhkd polybar gvfs thunar thunar-archive-plugin thunar-media-tags-plugin thunar-volman lxsession unzip wget curl pipewire wireplumber pavucontrol xarchiver base-devel linux-headers fastfetch neovim lxappearance papirus-icon-theme sddm psmisc dunst

### Enabling sddm ###

sudo systemctl enable sddm
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

cd ~/bspwm-config/ || exit
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

cd /usr/share/themes/ || exit
sudo git clone https://github.com/EliverLara/Nordic.git
cd || exit
fi

read -rep "Would you like to install nvidia drivers? (y/n)" nvidia
echo

if [[ $nvidia =~ ^[Nn]$ ]]; then
    printf "Not installed. \n"
fi

if [[ $nvidia =~ ^[Yy]$ ]]; then
	printf "Installing nvidia drivers. \n"

### Installing nvidia drivers ###

yay -S --noconfirm nvidia-dkms lib32-nvidia-utils
fi

echo -e "${GREEN}Now you can reboot!${ENDCOLOR}"