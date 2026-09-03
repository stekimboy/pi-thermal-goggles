#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Run this installer with sudo: sudo ./install.sh" >&2
  exit 1
fi

TARGET_USER="${SUDO_USER:-}"
if [[ -z "$TARGET_USER" || "$TARGET_USER" == "root" ]]; then
  echo "ERROR: run with sudo from the user that should own/run the goggles session." >&2
  exit 1
fi

TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPSTREAM_DIR="$TARGET_HOME/PyThermalCamera"
CONFIG=/boot/firmware/config.txt
[[ -f "$CONFIG" ]] || CONFIG=/boot/config.txt

if [[ ! -f "$CONFIG" ]]; then
  echo "ERROR: Raspberry Pi boot config not found." >&2
  exit 1
fi

MODEL="$(tr -d '\0' </proc/device-tree/model 2>/dev/null || true)"
if [[ "$MODEL" != *"Raspberry Pi"* ]]; then
  echo "WARNING: this does not appear to be a Raspberry Pi: $MODEL"
fi

echo "[1/7] Installing packages..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  git python3-opencv v4l-utils xserver-xorg xinit openbox x11-xserver-utils unclutter

echo "[2/7] Installing/updating upstream PyThermalCamera..."
if [[ -d "$UPSTREAM_DIR/.git" ]]; then
  sudo -u "$TARGET_USER" git -C "$UPSTREAM_DIR" pull --ff-only
else
  sudo -u "$TARGET_USER" git clone https://github.com/leswright1977/PyThermalCamera.git "$UPSTREAM_DIR"
fi

echo "[3/7] Building wearable goggles viewer..."
sudo -u "$TARGET_USER" python3 "$PROJECT_DIR/scripts/patch_tc001.py" "$UPSTREAM_DIR"

echo "[4/7] Configuring composite video..."
BACKUP="$CONFIG.tc001-thermal-goggles.backup"
if [[ ! -f "$BACKUP" ]]; then
  cp "$CONFIG" "$BACKUP"
fi

if grep -q '^dtoverlay=vc4-kms-v3d$' "$CONFIG"; then
  sed -i 's/^dtoverlay=vc4-kms-v3d$/dtoverlay=vc4-kms-v3d,composite/' "$CONFIG"
elif ! grep -q '^dtoverlay=vc4-kms-v3d,composite$' "$CONFIG"; then
  printf '\n# TC001 Thermal Goggles\ndtoverlay=vc4-kms-v3d,composite\n' >> "$CONFIG"
fi

grep -q '^enable_tvout=1$' "$CONFIG" || printf 'enable_tvout=1\n' >> "$CONFIG"

echo "[5/7] Installing fullscreen X session launcher..."
XINITRC="$TARGET_HOME/.xinitrc"
XINIT_BACKUP="$TARGET_HOME/.xinitrc.tc001-thermal-goggles.backup"
if [[ -f "$XINITRC" && ! -f "$XINIT_BACKUP" ]]; then
  cp "$XINITRC" "$XINIT_BACKUP"
  chown "$TARGET_USER:$TARGET_USER" "$XINIT_BACKUP"
fi

cat > "$XINITRC" <<XINIT
#!/bin/bash

xset s off
xset -dpms
xset s noblank

openbox-session &
unclutter -idle 0 -root &

sleep 2

while true; do
    if [ -e /dev/video0 ]; then
        python3 "$UPSTREAM_DIR/src/tc001-goggles.py" --device 0 >/dev/null 2>&1
    fi
    sleep 2
done
XINIT
chown "$TARGET_USER:$TARGET_USER" "$XINITRC"
chmod +x "$XINITRC"

echo "[6/7] Enabling local-console X autostart..."
PROFILE="$TARGET_HOME/.bash_profile"
touch "$PROFILE"
chown "$TARGET_USER:$TARGET_USER" "$PROFILE"

BEGIN='# >>> tc001-thermal-goggles >>>'
END='# <<< tc001-thermal-goggles <<<'
if grep -qF "$BEGIN" "$PROFILE"; then
  sed -i "/$BEGIN/,/$END/d" "$PROFILE"
fi
cat >> "$PROFILE" <<'PROFILE'

# >>> tc001-thermal-goggles >>>
# Start the dedicated thermal display only on the physical tty1 console.
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec startx
fi
# <<< tc001-thermal-goggles <<<
PROFILE
chown "$TARGET_USER:$TARGET_USER" "$PROFILE"

if command -v raspi-config >/dev/null 2>&1; then
  raspi-config nonint do_boot_behaviour B2
else
  echo "WARNING: raspi-config unavailable; configure console autologin manually."
fi

echo "[7/7] Checking TC001 visibility..."
if lsusb 2>/dev/null | grep -qi '0bda:5830'; then
  echo "TC001 detected (USB ID 0bda:5830)."
else
  echo "TC001 is not currently detected. Installation can still complete."
fi

echo
echo "Installation complete."
echo "Reboot with: sudo reboot"
echo "After reboot run: $PROJECT_DIR/scripts/verify.sh"
