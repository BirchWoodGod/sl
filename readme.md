# Personal DWM Configuration

Hello,

This is a personal configuration of DWM. It's pretty basic and keeps a lot of the vanilla options.  
This repo is here for personal notes and as an all-in-one package.

I do not know how to write in MD yet, so this is the best I can do until I learn how. ;)

---

## Minimal Install of Arch Linux
I use archinstall because I'm a noob and I don't care.  

Make sure you enable multilib before installing the recommended packages. 
`/etc/pacman.conf`

<pre> ```[multilib]
Include = /etc/pacman.d/mirrorlist ``` </pre>


Recommended packages:
`sudo pacman -Sy feh ly xorg xorg-xinit fastfetch htop nano networkmanager network-manager-applet`

---

## Display Manager: Ly
I like using the Ly Display Manager for the cool fire animation.  

Enable and start Ly:
`sudo systemctl enable ly`
`sudo systemctl start ly`

Config file location:
`/etc/ly/config.ini`

---

## Xinitrc Config
In the repo, I have included my xinitrc file for launching dwm and the included apps.  
You can copy my config as such:

`cp /sl/misc0/xinitrc-config.txt ~/.xinitrc`

---

## DWM Desktop Entry
In the misc0 folder of the repo, I included the dwm.desktop file.  
You’ll want to copy it into the xsessions directory:

`cp /sl/misc0/dwm.desktop /usr/share/xsessions/dwm.desktop`

---

## Notes
WIP — committing changes and coming back to finish.


