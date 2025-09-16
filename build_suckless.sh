#!/usr/bin/env bash
# Build helper for patched suckless utilities.
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DEFAULT_COMPONENTS=(dwm dmenu st slstatus)

if [ "$#" -gt 0 ]; then
  COMPONENTS=("$@")
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

run_make() {
  if [ ${#SUDO_CMD[@]} -gt 0 ]; then
    "${SUDO_CMD[@]}" "$@"
  else
    "$@"
  fi
}

for component in "${COMPONENTS[@]}"; do
  target_dir="${REPO_ROOT}/${component}"
  if [ ! -d "${target_dir}" ]; then
    echo "Skipping ${component}: directory not found." >&2
    continue
  fi

  echo "==> Building ${component}";
  (cd "${target_dir}" && run_make make clean install)
  echo
  echo "${component} build complete."
  echo

done

echo "All requested components built."
