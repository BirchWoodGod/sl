# Personal Suckless Desktop Setup

This repository contains my patched builds of **dwm**, **dmenu**, **st**, and **slstatus** along with the supporting files I use to get a minimal Arch Linux desktop running quickly. Everything lives in this repo so I can clone it on a fresh install and have the same environment in a couple of commands.

---

## Minimal Arch Install Notes
- I rely on `archinstall` because it gets me to a working base system fast.
- Enable the `multilib` repo before installing extras by editing `/etc/pacman.conf` and ensuring the block below is uncommented:

  ```ini
  [multilib]
  Include = /etc/pacman.d/mirrorlist
  ```

### Recommended packages
After the base install I normally grab these packages:

```bash
sudo pacman -Sy feh ly xorg xorg-xinit fastfetch htop nano networkmanager \
  network-manager-applet tldr brightnessctl alsa-utils alsamixer firefox
```

---

## Display Manager: Ly
Ly is my preferred display manager purely for the aesthetics.

```bash
sudo systemctl enable ly
sudo systemctl start ly
```

Configuration lives at `/etc/ly/config.ini`. After starting Ly make sure to log back into the shell once so you can continue setup tasks.

---

## Xinitrc and Desktop Entry
The `misc0` directory contains helper files:

- `xinitrc-config.txt` – copy to `~/.xinitrc` if you start dwm manually.
- `dwm.desktop` – copy to `/usr/share/xsessions/dwm.desktop` if you want a proper entry in display managers.

```bash
cp /sl/misc0/xinitrc-config.txt ~/.xinitrc
sudo cp /sl/misc0/dwm.desktop /usr/share/xsessions/dwm.desktop
```

---

## Building the Suckless Components
`build_suckless.sh` automates compiling and installing each component with `make clean install`.

```bash
./build_suckless.sh            # builds dwm, dmenu, st, slstatus
./build_suckless.sh dwm st     # build only the components you name
```

The script checks whether you are already root; otherwise it uses `sudo` if available. Run it from the repository root after adjusting any configuration you want.

If you prefer to build manually, change into each directory (`dwm`, `dmenu`, `st`, `slstatus`) and run:

```bash
sudo make clean install
```

Each project ships with a `config.h` you can tweak before building. `dwm` and `st` already include the patches I rely on (fullscreen, systray, scrollback, mouse scrolling).

---

## Status
This is a living setup. Expect tweaks over time as I learn more and refine the workflow.
