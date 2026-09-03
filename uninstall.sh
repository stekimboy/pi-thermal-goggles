#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo: sudo ./uninstall.sh" >&2
  exit 1
fi

TARGET_USER="${SUDO_USER:-}"
[[ -n "$TARGET_USER" && "$TARGET_USER" != "root" ]] || {
  echo "ERROR: run with sudo from the configured user." >&2
  exit 1
}
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
CONFIG=/boot/firmware/config.txt
[[ -f "$CONFIG" ]] || CONFIG=/boot/config.txt
BACKUP="$CONFIG.tc001-thermal-goggles.backup"

XINITRC="$TARGET_HOME/.xinitrc"
XINIT_BACKUP="$TARGET_HOME/.xinitrc.tc001-thermal-goggles.backup"
if [[ -f "$XINIT_BACKUP" ]]; then
  mv "$XINIT_BACKUP" "$XINITRC"
  chown "$TARGET_USER:$TARGET_USER" "$XINITRC"
  echo "Restored previous $XINITRC"
else
  rm -f "$XINITRC"
fi

PROFILE="$TARGET_HOME/.bash_profile"
if [[ -f "$PROFILE" ]]; then
  sed -i '/# >>> tc001-thermal-goggles >>>/,/# <<< tc001-thermal-goggles <<</d' "$PROFILE"
fi

if [[ -f "$BACKUP" ]]; then
  cp "$BACKUP" "$CONFIG"
  echo "Restored original Raspberry Pi boot config from $BACKUP"
else
  echo "No boot-config backup found; composite settings were left unchanged."
fi

echo "Autostart integration removed."
echo "The upstream ~/PyThermalCamera clone and installed apt packages were left in place."
echo "Reboot to apply display changes."
