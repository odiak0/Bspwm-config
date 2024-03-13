#!/bin/bash

### Updating system ###

sudo apt update
sudo apt upgrade -y

### Installing packages ###

sudo apt install feh kitty rofi bspwm sxhkd polybar gvfs-backends thunar thunar-archive-plugin thunar-font-manager thunar-media-tags-plugin thunar-volman lxpolkit x11-xserver-utils unzip wget curl pipewire wireplumber pavucontrol xarchiver build-essential linux-headers-$(uname -r) neofetch mangohud neovim lxappearance papirus-icon-theme lightdm fonts-noto-color-emoji psmisc dunst -y

### Installing browser ###

sudo rm -fv /etc/apt/sources.list.d/thorium.list && \
sudo wget --no-hsts -P /etc/apt/sources.list.d/ \
http://dl.thorium.rocks/debian/dists/stable/thorium.list && \
sudo apt update

### Installing theme ###

cd /usr/share/themes/
git clone https://github.com/EliverLara/Nordic.git
cd

### Enable lightdm ###

sudo systemctl enable lightdm
sudo systemctl set-default graphical.target

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
mv -vf ~/bspwm-config/wallpaper/mazda.jpg ~/wallpaper
sudo mv -vf ~/bspwm-config/polybar/config.ini /etc/polybar

GREEN='\033[0;32m'
printf "\n${GREEN} Now you can reboot!\n"
