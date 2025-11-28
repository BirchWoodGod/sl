# Personal Suckless Desktop Setup

This repository contains my patched builds of **dwm**, **dmenu**, **st**, and **slstatus** along with the supporting files I use to get a minimal Arch Linux desktop running quickly. Everything lives in this repo so I can clone it on a fresh install and have the same environment in a couple of commands.

> **Note**: The `build_suckless.sh` script was developed with assistance from AI to automate the setup process and provide an enhanced user experience with interactive menus and automatic configuration.

---

## Automated setup with `build_suckless.sh`
The `build_suckless.sh` helper takes care of the entire workflow for a fresh install:

- **Package Management**: Ensures the pacman `multilib` repository is enabled and installs any missing recommended desktop packages via `pacman` (using `sudo` when needed).
- **Network Interface Detection**: Automatically detects available network interfaces and lets you choose which one to use for slstatus bandwidth widgets.
- **Battery Configuration**: Optionally enables battery percentage display in slstatus.
- **DWM Configuration**: Interactive menus to configure dwm modkey (Super/Alt) and status bar highlight color from popular themes (Solarized, Nord, Gruvbox) or custom hex values.
- **Ly Display Manager**: Automatically configures Ly display manager with animation selection (Doom, Matrix, ColorMix) and enables the service.
- **File Management**: Copies helper files from `misc0/` into place and builds each requested component.
- **Desktop Entry Support**: Automatically builds and integrates j4-dmenu-desktop with dmenu for desktop entry support.

```bash
./build_suckless.sh            # full interactive run (dwm, dmenu, st, slstatus)
./build_suckless.sh dwm st     # build only the components you name
./build_suckless.sh -y         # keep current configs, auto-install packages, skip prompts
./build_suckless.sh --help     # show all options
```

During an interactive run the script will:

1. **Package Installation**: Ensure `/etc/pacman.conf` has the `[multilib]` repository enabled, then check `pacman` for the packages I normally install (`feh`, `ly`, `xorg`, `xorg-xinit`, `fastfetch`, `htop`, `nano`, `networkmanager`, `network-manager-applet`, `tldr`, `brightnessctl`, `alsa-utils`, `firefox`, `net-tools`) and offer to install any that are missing. Pass `--skip-packages` if you want to handle this step yourself.

2. **Network Interface Selection**: Automatically detect available network interfaces and present a numbered menu for you to choose which one to use for slstatus bandwidth widgets.

3. **Battery Configuration**: Ask whether to display battery percentage in slstatus.

4. **DWM Configuration**: 
   - **Modkey Selection**: Choose between Super key (Windows/Command) or Alt key as the dwm modifier key
   - **Color Selection**: Present an interactive menu to choose the dwm status bar highlight color from popular themes (Solarized, Nord, Gruvbox) or enter a custom hex value

5. **File Management**: Offer to copy the helper files in `misc0/` to the correct locations:
   - `misc0/xinitrc-config.txt` → `~/.xinitrc`
   - `misc0/dwm.desktop` → `/usr/share/xsessions/dwm.desktop`

6. **Component Building**: Build whichever components you requested via `make clean install` (using `sudo` when needed). When building `dmenu`, j4-dmenu-desktop is automatically built and installed to enable desktop entry support.

7. **Ly Configuration**: After building dwm, automatically configure Ly display manager:
   - Enable and start the Ly service
   - Present animation selection menu (Doom, Matrix, ColorMix, or none)
   - Create backup of Ly config before making changes

You can pre-seed answers with flags if you want a non-interactive run. Examples:

```bash
./build_suckless.sh --interface wlan0 --battery --bar-color "#268bd2" --modkey super
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
  network-manager-applet tldr brightnessctl alsa-utils firefox net-tools
```

**Build dependencies for j4-dmenu-desktop:**
j4-dmenu-desktop requires either Meson (preferred) or CMake to build. Install one of them:

```bash
sudo pacman -S meson        # Preferred build system
# or
sudo pacman -S cmake         # Alternative build system
```

### Display manager: Ly
Ly is my preferred display manager purely for the aesthetics. The automated script handles the complete setup, but if you prefer manual configuration:

```bash
sudo systemctl enable ly
sudo systemctl start ly
```

Configuration lives at `/etc/ly/config.ini`. Available animations include:
- `doom` - Doom-style animation
- `matrix` - Matrix digital rain effect  
- `colormix` - Color mixing animation
- `none` - No animation (default)

The script automatically configures Ly with your chosen animation and enables the service.

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

### dmenu and Desktop Entry Support
The `dmenu` component includes **j4-dmenu-desktop** for desktop entry support. When you build `dmenu`, the script automatically builds and installs j4-dmenu-desktop as well. This enables `dmenu_run` to show both:
- Executables from your `$PATH`
- Applications from `.desktop` files (including AppImage launcher entries)

j4-dmenu-desktop source code is included in `dmenu/j4-dmenu-desktop/` and is licensed under **GPL-3.0-or-later** (see `dmenu/j4-dmenu-desktop/LICENSE`). The build script uses Meson (preferred) or CMake to build j4-dmenu-desktop, so ensure one of these is installed (see [Recommended packages](#recommended-packages) above).

**Note:** j4-dmenu-desktop is a separate work and remains in its own subdirectory. The GPL license applies only to j4-dmenu-desktop, not to the rest of this repository (which uses MIT/X Consortium licenses for the suckless tools).

---

## Status
This is a living setup. Expect tweaks over time as I learn more and refine the workflow.
