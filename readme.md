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

<pre>[multilib]
Include = /etc/pacman.d/mirrorlist </pre>


Recommended packages:
<pre> sudo pacman -Sy feh ly xorg xorg-xinit fastfetch htop nano networkmanager network-manager-applet tldr </pre>

---

## Display Manager: Ly
I like using the Ly Display Manager for the cool fire animation.  

Enable and start Ly:
<pre>sudo systemctl enable ly
sudo systemctl start ly </pre>

Config file location:
`/etc/ly/config.ini`

Be sure to log back into the shell after starting ly.

---

## Xinitrc Config
In the repo, I have included my xinitrc file for launching dwm and the included apps.  
You can copy my config as such:

<pre> cp /sl/misc0/xinitrc-config.txt ~/.xinitrc </pre>

---

## DWM Desktop Entry
In the misc0 folder of the repo, I included the dwm.desktop file.  
You’ll want to copy it into the xsessions directory:

<pre> cp /sl/misc0/dwm.desktop /usr/share/xsessions/dwm.desktop </pre>

(This isn't really needed as you can start xinit from ly, but I like the entry to say "dwm".)

---

## Building DWM, dmenu, st, sltatus

Things to know: dwm and st have been pre-patched. The patches used are full screen, systray, scrolling, and mouse scrolling.

You can configure the apps by editing `config.h` in each of the directories. 

Compiling dwm is pretty easy, same with the rest of the apps. Go into each directory and just type:

<pre> sudo make clean install </pre>

(thinking about making a script for this)

---

## Notes
WIP — committing changes and coming back to finish.






