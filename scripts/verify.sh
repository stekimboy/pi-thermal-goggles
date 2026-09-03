#!/usr/bin/env bash
set -u

fail=0

echo "TC001 Thermal Goggles verification"
echo "=================================="

if pgrep -af tc001-goggles; then
  echo "[OK] viewer process is running"
else
  echo "[FAIL] viewer process not found"
  fail=1
fi

echo
if [[ -e /dev/video0 ]]; then
  echo "[OK] /dev/video0 exists"
  if command -v fuser >/dev/null 2>&1; then
    fuser -v /dev/video0 2>&1 || true
  fi
else
  echo "[FAIL] /dev/video0 does not exist"
  fail=1
fi

echo
if [[ -n "${DISPLAY:-}" ]]; then
  DISPLAY_TO_CHECK="$DISPLAY"
else
  DISPLAY_TO_CHECK=:0
fi

if DISPLAY="$DISPLAY_TO_CHECK" xrandr --query 2>/dev/null | grep -q 'Composite-1'; then
  echo "[OK] Composite-1 is present"
  DISPLAY="$DISPLAY_TO_CHECK" xrandr --query | grep -A4 'Composite-1' || true
else
  echo "[FAIL] Composite-1 not found on $DISPLAY_TO_CHECK"
  fail=1
fi

echo
if pgrep -af unclutter >/dev/null; then
  echo "[OK] unclutter is running"
else
  echo "[WARN] unclutter is not running; the X mouse cursor may remain visible"
fi

echo
if lsusb 2>/dev/null | grep -qi '0bda:5830'; then
  echo "[OK] TC001 USB ID 0bda:5830 detected"
else
  echo "[WARN] TC001 USB ID 0bda:5830 not detected"
fi

exit "$fail"
