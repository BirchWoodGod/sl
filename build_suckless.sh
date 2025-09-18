#!/usr/bin/env bash
# Build helper for patched suckless utilities.
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DEFAULT_COMPONENTS=(dwm dmenu st slstatus)
RECOMMENDED_PACKAGES=(
  feh
  ly
  xorg
  xorg-xinit
  fastfetch
  htop
  nano
  networkmanager
  network-manager-applet
  tldr
  brightnessctl
  alsa-utils
  firefox
)

ACCEPT_DEFAULTS=0
SLSTATUS_INTERFACE=""
BATTERY_CHOICE=""
BAR_COLOR=""
COPY_XINIT=""
COPY_DESKTOP=""
CHECK_PACKAGES=1

usage() {
  cat <<'EOF'
Usage: ./build_suckless.sh [options] [component...]

Build patched suckless components and optionally configure them beforehand.

Options:
  -h, --help              Show this help message and exit
  -y, --accept-defaults   Skip interactive prompts and keep current settings
      --interface IFACE   Set network interface for slstatus netspeed widgets
      --battery           Enable the battery widget in slstatus
      --no-battery        Disable the battery widget in slstatus
      --bar-color COLOR   Hex color to use for the dwm selected bar background
      --copy-xinit        Copy misc0/xinitrc-config.txt to ~/.xinitrc
      --no-copy-xinit     Skip copying the xinitrc helper (useful with -y)
      --copy-desktop      Copy misc0/dwm.desktop to /usr/share/xsessions/
      --no-copy-desktop   Skip copying the desktop file (useful with -y)
      --skip-packages      Skip installing recommended pacman packages

Components default to: dwm dmenu st slstatus
EOF
}

COMPONENT_ARGS=()

while (($#)); do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -y|--accept-defaults)
      ACCEPT_DEFAULTS=1
      ;;
    --interface)
      if [ $# -lt 2 ]; then
        echo "Error: --interface requires a value." >&2
        exit 1
      fi
      SLSTATUS_INTERFACE="$2"
      shift
      ;;
    --battery)
      BATTERY_CHOICE="enable"
      ;;
    --no-battery)
      BATTERY_CHOICE="disable"
      ;;
    --bar-color)
      if [ $# -lt 2 ]; then
        echo "Error: --bar-color requires a value." >&2
        exit 1
      fi
      BAR_COLOR="$2"
      shift
      ;;
    --copy-xinit)
      COPY_XINIT="yes"
      ;;
    --no-copy-xinit)
      COPY_XINIT="no"
      ;;
    --copy-desktop)
      COPY_DESKTOP="yes"
      ;;
    --no-copy-desktop)
      COPY_DESKTOP="no"
      ;;
    --skip-packages)
      CHECK_PACKAGES=0
      ;;
    --)
      shift
      while (($#)); do
        COMPONENT_ARGS+=("$1")
        shift
      done
      break
      ;;
    -*)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
    *)
      COMPONENT_ARGS+=("$1")
      ;;
  esac
  shift
done

if [ ${#COMPONENT_ARGS[@]} -gt 0 ]; then
  COMPONENTS=("${COMPONENT_ARGS[@]}")
else
  COMPONENTS=("${DEFAULT_COMPONENTS[@]}")
fi

# Determine privilege escalation command if needed.
if [ "${EUID:-$(id -u)}" -eq 0 ]; then
  SUDO_CMD=()
else
  if command -v sudo >/dev/null 2>&1; then
    SUDO_CMD=(sudo)
  else
    echo "Error: sudo not found. Run this script as root or install sudo." >&2
    exit 1
  fi
fi

run_with_privilege() {
  if [ ${#SUDO_CMD[@]} -gt 0 ]; then
    "${SUDO_CMD[@]}" "$@"
  else
    "$@"
  fi
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: required command '$1' not found. $2" >&2
    exit 1
  fi
}

component_selected() {
  local target="$1"
  for component in "${COMPONENTS[@]}"; do
    if [ "$component" = "$target" ]; then
      return 0
    fi
  done
  return 1
}

prompt_yes_no() {
  local prompt="$1"
  local default_answer="$2"
  local response
  local suffix=""

  case "$default_answer" in
    y|Y)
      suffix="[Y/n]"
      ;;
    n|N)
      suffix="[y/N]"
      ;;
    *)
      suffix="[y/n]"
      ;;
  esac

  while true; do
    read -r -p "$prompt $suffix " response || response=""
    response=${response:-$default_answer}
    case "$response" in
      y|Y)
        return 0
        ;;
      n|N)
        return 1
        ;;
      *)
        echo "Please answer y or n." >&2
        ;;
    esac
  done
}

ensure_multilib_repo_enabled() {
  local pacman_conf="/etc/pacman.conf"

  if [ ! -f "$pacman_conf" ]; then
    echo "Warning: $pacman_conf not found; skipping multilib repository configuration." >&2
    return
  fi

  if grep -Eq '^[[:space:]]*\[multilib\][[:space:]]*$' "$pacman_conf"; then
    if awk '/^[[:space:]]*\[multilib\][[:space:]]*$/{flag=1;next} /^[[:space:]]*\[/{flag=0} flag && $0 ~ /^[[:space:]]*Include[[:space:]]*=[[:space:]]*\/etc\/pacman.d\/mirrorlist/{found=1} END{exit !found}' "$pacman_conf"; then
      echo "pacman multilib repository already enabled."
      return
    fi
  fi

  if ! grep -Eq '^[[:space:]]*#\s*\[multilib\]' "$pacman_conf"; then
    echo "Warning: unable to find a commented multilib section in $pacman_conf; please enable it manually if needed." >&2
    return
  fi

  require_command python3 "Python 3 is needed to update $pacman_conf."

  echo "Enabling pacman multilib repository in $pacman_conf."
  if run_with_privilege python3 - "$pacman_conf" <<'PY'; then
import sys

path = sys.argv[1]
with open(path, encoding='utf-8') as fh:
    lines = fh.readlines()

changed = False
for idx, line in enumerate(lines):
    stripped = line.lstrip()
    bare = stripped.lstrip('#').strip()
    if bare.lower() == '[multilib]':
        prefix = line[: len(line) - len(stripped)]
        desired = f"{prefix}[multilib]\n"
        if line != desired:
            lines[idx] = desired
            changed = True

        j = idx + 1
        while j < len(lines):
            next_line = lines[j]
            next_stripped = next_line.strip()
            if not next_stripped:
                j += 1
                continue
            if next_stripped.startswith('['):
                break
            bare_next = next_line.lstrip().lstrip('#').strip()
            if bare_next.lower().startswith('include'):
                prefix_next = next_line[: len(next_line) - len(next_line.lstrip())]
                desired_next = f"{prefix_next}{bare_next}\n"
                if next_line != desired_next:
                    lines[j] = desired_next
                    changed = True
                break
            j += 1
        break

if changed:
    with open(path, 'w', encoding='utf-8') as fh:
        fh.writelines(lines)
PY
  then
    if grep -Eq '^[[:space:]]*\[multilib\][[:space:]]*$' "$pacman_conf" && \
       awk '/^[[:space:]]*\[multilib\][[:space:]]*$/{flag=1;next} /^[[:space:]]*\[/{flag=0} flag && $0 ~ /^[[:space:]]*Include[[:space:]]*=[[:space:]]*\/etc\/pacman.d\/mirrorlist/{found=1} END{exit !found}' "$pacman_conf"; then
      echo "Enabled pacman multilib repository."
    else
      echo "Warning: attempted to enable multilib but validation failed; please verify $pacman_conf manually." >&2
    fi
  else
    echo "Warning: failed to update $pacman_conf; please enable multilib manually." >&2
  fi
}

ensure_recommended_packages() {
  if [ "$CHECK_PACKAGES" -eq 0 ]; then
    echo "Skipping recommended package installation check."
    return
  fi

  if ! command -v pacman >/dev/null 2>&1; then
    echo "Warning: pacman not found; skipping recommended package installation." >&2
    return
  fi

  ensure_multilib_repo_enabled

  local missing_packages=()
  for package in "${RECOMMENDED_PACKAGES[@]}"; do
    if ! pacman -Qi "$package" >/dev/null 2>&1; then
      missing_packages+=("$package")
    fi
  done

  if [ ${#missing_packages[@]} -eq 0 ]; then
    echo "All recommended packages are already installed."
    return
  fi

  echo "Recommended packages not found: ${missing_packages[*]}"

  local should_install="yes"
  if [ "$ACCEPT_DEFAULTS" -eq 0 ]; then
    if prompt_yes_no "Install recommended packages with pacman?" "y"; then
      should_install="yes"
    else
      should_install="no"
    fi
  fi

  if [ "$should_install" = "yes" ]; then
    local pacman_cmd=(pacman -Sy --needed)
    if [ "$ACCEPT_DEFAULTS" -eq 1 ]; then
      pacman_cmd+=(--noconfirm)
    fi
    pacman_cmd+=("${missing_packages[@]}")
    echo "Installing recommended packages: ${missing_packages[*]}"
    run_with_privilege "${pacman_cmd[@]}"
    echo "Recommended packages installation complete."
  else
    echo "Skipping installation of recommended packages."
  fi
}

configure_slstatus_interface() {
  local config_file="${REPO_ROOT}/slstatus/config.h"
  local current_iface
  current_iface=$(sed -n 's/.*netspeed_rx.*"\([^"]*\)".*/\1/p' "$config_file" | head -n1)
  current_iface=${current_iface:-unknown}

  local chosen_iface="$SLSTATUS_INTERFACE"
  if [ -z "$chosen_iface" ] && [ "$ACCEPT_DEFAULTS" -eq 0 ]; then
    read -r -p "Network interface for slstatus netspeed widgets (current: ${current_iface}): " chosen_iface || chosen_iface=""
  fi

  if [ -n "$chosen_iface" ]; then
    require_command python3 "Python 3 is needed to update slstatus/config.h."
    python3 - "$config_file" "$chosen_iface" <<'PY'
import re
import sys

path, iface = sys.argv[1:3]
with open(path, encoding='utf-8') as fh:
    data = fh.read()

pattern = re.compile(r'(\{\s*netspeed_(?:rx|tx)\s*,\s*"[^"]*",\s*")([^"]*)(".*)')

def repl(match):
    return f"{match.group(1)}{iface}{match.group(3)}"

new_data, count = pattern.subn(repl, data)
if count == 0:
    sys.stderr.write('Warning: could not locate netspeed entries to update.\n')
else:
    with open(path, 'w', encoding='utf-8') as fh:
        fh.write(new_data)
PY
    echo "Updated slstatus network interface to '${chosen_iface}'."
  fi
}

configure_slstatus_battery() {
  local config_file="${REPO_ROOT}/slstatus/config.h"
  local desired_state="$1"

  if [ -z "$desired_state" ] && [ "$ACCEPT_DEFAULTS" -eq 0 ]; then
    if prompt_yes_no "Enable battery status in slstatus?" "n"; then
      desired_state="enable"
    else
      desired_state="disable"
    fi
  elif [ -z "$desired_state" ]; then
    desired_state="disable"
  fi

  if [ "$desired_state" = "enable" ]; then
    require_command python3 "Python 3 is needed to update slstatus/config.h."
    python3 - "$config_file" <<'PY'
import sys

path = sys.argv[1]
with open(path, encoding='utf-8') as fh:
    lines = fh.readlines()

updated = []
for line in lines:
    stripped = line.lstrip()
    indent = line[: len(line) - len(stripped)]
    if stripped.startswith('//{ battery_perc'):
        updated.append(f"{indent}{stripped[2:]}")
    else:
        updated.append(line)

with open(path, 'w', encoding='utf-8') as fh:
    fh.writelines(updated)
PY
    echo "Enabled slstatus battery widget (uses BAT0 by default)."
  else
    require_command python3 "Python 3 is needed to update slstatus/config.h."
    python3 - "$config_file" <<'PY'
import sys

path = sys.argv[1]
with open(path, encoding='utf-8') as fh:
    lines = fh.readlines()

updated = []
for line in lines:
    stripped = line.lstrip()
    indent = line[: len(line) - len(stripped)]
    if stripped.startswith('{ battery_perc'):
        updated.append(f"{indent}//{stripped}")
    else:
        updated.append(line)

with open(path, 'w', encoding='utf-8') as fh:
    fh.writelines(updated)
PY
    echo "Disabled slstatus battery widget."
  fi
}

configure_dwm_bar_color() {
  local config_file="${REPO_ROOT}/dwm/config.h"
  local current_color
  current_color=$(sed -n 's/.*col_cyan\[] = "\(.*\)";/\1/p' "$config_file" | head -n1)
  current_color=${current_color:-#000000}

  local chosen_color="$BAR_COLOR"
  if [ -z "$chosen_color" ] && [ "$ACCEPT_DEFAULTS" -eq 0 ]; then
    read -r -p "Hex color for dwm selected bar background (current: ${current_color}): " chosen_color || chosen_color=""
  fi

  if [ -n "$chosen_color" ]; then
    require_command python3 "Python 3 is needed to update dwm/config.h."
    python3 - "$config_file" "$chosen_color" <<'PY'
import re
import sys

path, color = sys.argv[1:3]
with open(path, encoding='utf-8') as fh:
    data = fh.read()

pattern = re.compile(r'(static const char col_cyan\[] = ")([^"]+)(";)')
if not pattern.search(data):
    sys.stderr.write('Warning: could not locate col_cyan definition.\n')
else:
    new_data = pattern.sub(rf"\1{color}\3", data, count=1)
    with open(path, 'w', encoding='utf-8') as fh:
        fh.write(new_data)
PY
    echo "Updated dwm selected bar color to '${chosen_color}'."
  fi
}

copy_with_backup() {
  local source="$1"
  local destination="$2"
  local use_privilege="$3"

  if [ ! -e "$source" ]; then
    echo "Warning: source file '$source' not found, skipping copy." >&2
    return
  fi

  local timestamp
  timestamp=$(date +%Y%m%d%H%M%S)
  if [ -e "$destination" ]; then
    local backup="${destination}.${timestamp}.bak"
    if [ "$use_privilege" = "yes" ]; then
      run_with_privilege cp "$destination" "$backup"
    else
      cp "$destination" "$backup"
    fi
    echo "Existing $(basename "$destination") backed up to ${backup}."
  fi

  if [ "$use_privilege" = "yes" ]; then
    run_with_privilege install -Dm644 "$source" "$destination"
  else
    install -Dm644 "$source" "$destination"
  fi
  echo "Installed $(basename "$source") to ${destination}."
}

setup_misc_files() {
  local xinit_source="${REPO_ROOT}/misc0/xinitrc-config.txt"
  local xinit_target="$HOME/.xinitrc"
  local desktop_source="${REPO_ROOT}/misc0/dwm.desktop"
  local desktop_target="/usr/share/xsessions/dwm.desktop"

  local should_copy_xinit="$COPY_XINIT"
  if [ -z "$should_copy_xinit" ]; then
    if [ "$ACCEPT_DEFAULTS" -eq 0 ]; then
      if prompt_yes_no "Copy xinitrc helper to ${xinit_target}?" "y"; then
        should_copy_xinit="yes"
      else
        should_copy_xinit="no"
      fi
    else
      should_copy_xinit="no"
    fi
  fi

  if [ "$should_copy_xinit" = "yes" ]; then
    copy_with_backup "$xinit_source" "$xinit_target" "no"
  fi

  local should_copy_desktop="$COPY_DESKTOP"
  if [ -z "$should_copy_desktop" ]; then
    if [ "$ACCEPT_DEFAULTS" -eq 0 ]; then
      if prompt_yes_no "Copy dwm.desktop to ${desktop_target}? (requires root)" "y"; then
        should_copy_desktop="yes"
      else
        should_copy_desktop="no"
      fi
    else
      should_copy_desktop="no"
    fi
  fi

  if [ "$should_copy_desktop" = "yes" ]; then
    copy_with_backup "$desktop_source" "$desktop_target" "yes"
  fi
}

ensure_recommended_packages

if component_selected "slstatus"; then
  configure_slstatus_interface
  configure_slstatus_battery "$BATTERY_CHOICE"
fi

if component_selected "dwm"; then
  configure_dwm_bar_color
fi

setup_misc_files

for component in "${COMPONENTS[@]}"; do
  target_dir="${REPO_ROOT}/${component}"
  if [ ! -d "${target_dir}" ]; then
    echo "Skipping ${component}: directory not found." >&2
    continue
  fi

  echo "==> Building ${component}";
  (cd "${target_dir}" && run_with_privilege make clean install)
  echo
  echo "${component} build complete."
  echo

done

echo "All requested components built."
