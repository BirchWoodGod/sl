# Personal Suckless Desktop Setup

This repository contains my patched builds of **dwm**, **dmenu**, **st**, and **slstatus** along with the supporting files I use to get a minimal Arch Linux desktop running quickly. Everything lives in this repo so I can clone it on a fresh install and have the same environment in a couple of commands.

---

## Automated setup with `build_suckless.sh`
The `build_suckless.sh` helper takes care of the entire workflow for a fresh install:


- Ensures the pacman `multilib` repository is enabled and installs any missing recommended desktop packages via `pacman` (using `sudo` when needed).
- Lets you interactively adjust slstatus' network interface and battery widgets.
- Lets you set the dwm status bar highlight color (written to `dwm/config.h`).
- Copies helper files from `misc0/` into place and builds each requested component.

```bash
./build_suckless.sh            # full interactive run (dwm, dmenu, st, slstatus)
./build_suckless.sh dwm st     # build only the components you name
./build_suckless.sh -y         # keep current configs, auto-install packages, skip prompts
./build_suckless.sh --help     # show all options
```

During an interactive run the script will:

1. Ensure `/etc/pacman.conf` has the `[multilib]` repository enabled, then check `pacman` for the packages I normally install (`feh`, `ly`, `xorg`, `xorg-xinit`, `fastfetch`, `htop`, `nano`, `networkmanager`, `network-manager-applet`, `tldr`, `brightnessctl`, `alsa-utils`, `firefox`) and offer to install any that are missing. Pass `--skip-packages` if you want to handle this step yourself.
2. Ask for the network interface used by the slstatus bandwidth widgets.
3. Ask whether to display battery percentage in slstatus.
4. Let you pick the hex color for the highlighted dwm bar (the value written to `dwm/config.h` line 19).
5. Offer to copy the helper files in `misc0/` to the correct locations:
   - `misc0/xinitrc-config.txt` → `~/.xinitrc`
   - `misc0/dwm.desktop` → `/usr/share/xsessions/dwm.desktop`
6. Build whichever components you requested via `make clean install` (using `sudo` when needed).

You can pre-seed answers with flags if you want a non-interactive run. Examples:

```bash
./build_suckless.sh --interface wlan0 --battery --bar-color "#268bd2"
./build_suckless.sh --no-copy-desktop --copy-xinit dmenu
./build_suckless.sh --skip-packages -y           # keep configs and skip the package check entirely
```

The script checks whether you are already root; otherwise it uses `sudo` if available. Run it from the repository root after adjusting any configuration you want.

---

## Manual setup reference

### Minimal Arch install notes
- I rely on `archinstall` because it gets me to a working base system fast.
- Enable the `multilib` repo before installing extras by editing `/etc/pacman.conf` and ensuring the block below is uncommented (the automation will do this for you if needed):

  ```ini
  [multilib]
  Include = /etc/pacman.d/mirrorlist
  ```

### Recommended packages
If you prefer to handle packages manually, install them with:

```bash
sudo pacman -Sy feh ly xorg xorg-xinit fastfetch htop nano networkmanager \
  network-manager-applet tldr brightnessctl alsa-utils firefox
```

### Display manager: Ly
Ly is my preferred display manager purely for the aesthetics.

```bash
sudo systemctl enable ly
sudo systemctl start ly
```

Configuration lives at `/etc/ly/config.ini`. After starting Ly make sure to log back into the shell once so you can continue setup tasks.

### Xinitrc and desktop entry
The `misc0` directory contains helper files:

- `xinitrc-config.txt` – copy to `~/.xinitrc` if you start dwm manually.
- `dwm.desktop` – copy to `/usr/share/xsessions/dwm.desktop` if you want a proper entry in display managers.

```bash
cp /sl/misc0/xinitrc-config.txt ~/.xinitrc
sudo cp /sl/misc0/dwm.desktop /usr/share/xsessions/dwm.desktop
```


### Building the suckless components by hand
Change into each directory (`dwm`, `dmenu`, `st`, `slstatus`) and run:

```bash
sudo make clean install
```

Each project ships with a `config.h` you can tweak before building. `dwm` and `st` already include the patches I rely on (fullscreen, systray, scrollback, mouse scrolling).

---

## Status
This is a living setup. Expect tweaks over time as I learn more and refine the workflow.
