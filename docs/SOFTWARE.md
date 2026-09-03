# Software

## Overview

The Pi does three things: grab frames from the TC001, process them for viewing through goggles, and push the result out the composite port fullscreen. Everything is arranged so that applying power is the only operator action required.

```text
TC001 (V4L2)
    ↓
Python / OpenCV processing
    ↓
fullscreen OpenCV window (X11 + Openbox)
    ↓
composite video → goggles
```

## Boot path

```text
power on
  ↓
console autologin on tty1
  ↓
~/.bash_profile   (only if tty is /dev/tty1 and $DISPLAY is unset)
  ↓
startx → ~/.xinitrc
  ↓
openbox-session, unclutter
  ↓
loop: python3 tc001-goggles.py --device 0
  ↓
fullscreen window on Composite-1 (NTSC 480i)
```

The `startx` hook checks `$(tty) = /dev/tty1`, so SSH logins get a normal shell. This is what keeps the Pi maintainable after composite mode has disabled HDMI.

## Upstream and the patcher

The installer clones [PyThermalCamera](https://github.com/leswright1977/PyThermalCamera) into `~/PyThermalCamera` and runs `scripts/patch_tc001.py` on that checkout. The patcher copies `src/tc001v4.2.py` to `src/tc001-goggles.py` and applies its edits to the copy; the upstream file is left untouched.

I chose this over maintaining a fork for a few reasons: the original file keeps its license header and attribution, upstream changes can be pulled with a `git pull`, and the diff between upstream and this project is exactly the contents of one readable script. The patcher fails loudly if any of the code it expects to find is missing, and compiles the result before declaring success.

### What the patches change

1. Fullscreen on startup (`dispFullscreen = True` plus `setWindowProperty` right after the window is created).
2. `thdata = thdata.astype(np.int32)` immediately after the frame is split into image and radiometric halves. Upstream does `thdata[...] * 256` on a `uint8` array, which newer NumPy rejects with `OverflowError`.
3. White-hot (colormap 11) and black-hot (colormap 12) modes. Both run CLAHE and a mild unsharp mask; black-hot inverts at the end. White-hot is the default.
4. HUD off, center temperature text removed, floating min/max markers suppressed by setting their threshold out of range. The crosshair is kept.
5. Colormap cycling extended from 11 to 13 so the `m` key still reaches every palette.
6. A short header comment in the generated file noting it was built by the patcher.

## Processing pipeline

```text
YUYV frame (256x384)
    ↓
split into image (top) and radiometric (bottom) halves
    ↓
radiometric half → int32
    ↓
YUYV → BGR
    ↓
resize to output scale
    ↓
BGR → grayscale
    ↓
CLAHE  (clipLimit 2.0, 8x8 tiles)
    ↓
Gaussian blur copy (sigma 0.8)
    ↓
unsharp mask  (1.3 × sharp − 0.3 × blurred)
    ↓
grayscale → BGR
    ↓
crosshair
    ↓
fullscreen display
```

CLAHE is doing most of the work. Thermal scenes often have large regions at nearly the same temperature, and a global stretch either leaves them flat or clips the warm parts. Local contrast brings back edges inside those regions. The unsharp mask is deliberately mild; pushing it further turns the image into noisy edge soup. Tuning notes are in [`TUNING.md`](TUNING.md).

## Mode switching

Switching between FPV video and thermal is done by the goggles, not the software. The Pi just keeps driving the AV input.

```text
Cyclops RX mode → onboard 5.8 GHz receiver
Cyclops AV mode → Raspberry Pi feed
```

A GPIO button could later drive software-side changes (palette, recording, sensor selection) without needing a keyboard.

## Auto-restart

`.xinitrc` wraps the viewer in a `while true` loop. If the process exits, or the camera isn't present yet, it waits two seconds and tries again. It's crude, but for a prototype it is transparent and easy to reason about. A `systemd` unit with proper health checks would be the next step.

## Logging

The launcher sends the viewer's output to `/dev/null` so the SD card isn't written to continuously. For debugging, change the redirect in `~/.xinitrc` to a file; see [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md).

## Where new processing goes

Anything new belongs between the enhanced frame and the display call:

```python
frame = acquire_frame()
frame = enhance(frame)          # CLAHE, unsharp

# new work goes here: detection, tracking, overlays, fusion

render(frame)
```

That slot is the reason the project is interesting beyond thermal viewing. See [`ARCHITECTURE.md`](ARCHITECTURE.md).
