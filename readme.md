Hello,

This is a personal configuration of DWM. It's pretty basic and kept a lot of the vanilla options. This repo is here for personal notes, and an all-in-one package.

I do not know how to write in MD, so this is the best I can do until I learn how. 


Minimal Install of Arch Linux; I use archinstall cause I'm a noob and I don't care.

Recommend packages: sudo pacman -Sy feh ly xorg xorg-xinit fastfetch htop nano

I like using the Ly Display Manager for the cool fire animation. Here are some things to note: 

sudo systemctl enable ly
sudo systemctl start ly

The config file for Ly is located:
/etc/ly/config.ini

In the repo, I have included my xinitrc file for launching dwm and the included apps. You can copy my config as such:
cp /sl/misc0/xinitrc-config.txt ~/.xinitrc


In the repo I have included in the misc0 folder dwm.desktop file. You want to cp that in the xsessions directory.
cp /sl/misc0/dwm.desktop /usr/share/xsessions/dwm.desktop


WIP committing changes and coming back to finish



