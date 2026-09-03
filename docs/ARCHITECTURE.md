# Architecture

## The idea

Most DIY thermal goggle builds wire a camera straight to a screen. This one puts a Raspberry Pi in between:

```text
sensor  →  Raspberry Pi  →  operator-selectable video path  →  goggles
```

The thermal camera is the first sensor on it, but the Pi is a general-purpose layer where processing, overlays, additional sensors, and networking can be added without changing the display side at all. That is the part of the project I think is worth building on.

## Operator modes

The finished headset has two usable paths, selected with the goggles' own input switch:

```text
                        ┌── onboard 5.8 GHz receiver ── FPV camera on a drone/robot
operator headset ◄──────┤
                        └── AV input ◄── Raspberry Pi (thermal, or whatever the Pi is producing)
```

Keeping the conventional path intact was deliberate. It means the headset stays useful as normal FPV goggles, and it means the Pi side can be broken, mid-rewrite, or rebooting without taking the operator's display down.

## What runs on the Pi today

- Linux, Python, OpenCV, NumPy, V4L2
- X11 with Openbox as a bare window manager
- TC001 frame capture and parsing
- white-hot grayscale with CLAHE and light sharpening
- fullscreen rendering with a center crosshair and nothing else on screen
- composite video out

## What could run on it

These are the directions I would take it, roughly in order of how much I'd want each one:

**Robustness**
- discover the camera by USB ID instead of assuming `/dev/video0`
- measure glass-to-glass latency and battery runtime with numbers, not impressions
- a `systemd` unit in place of the shell loop
- a proper 5 V / 4–5 A power stage and an enclosure with strain relief

**Controls**
- GPIO buttons for palette, black-hot/white-hot, and recording
- a mode indicator in the corner of the frame

**Perception**
- person and vehicle detection on the thermal frame
- motion detection and simple tracking
- a second RGB camera and thermal/RGB fusion
- image stabilization

**Overlays and data**
- heading, GPS, battery, link status, timestamp
- telemetry from a flight controller over UART
- event-triggered recording to the SD card

**Outputs**
- HDMI or a digital FPV system instead of composite
- network streaming to a ground station

## Use cases I had in mind

- night-time situational awareness on foot
- search and rescue (warm bodies against a cool background is the easy case for thermal)
- a payload on a drone or ground robot, using the existing FPV link for the operator view
- a cheap test bed for trying computer-vision models on real thermal imagery before committing to better hardware

The scope of this repository is sensing, image processing, and operator display.

## What the project actually involved

For anyone evaluating the work rather than the hardware, the problems solved were spread across the stack:

1. Building on PyThermalCamera's TC001 capture rather than redoing it. The usable V4L2 stream and the stacked image/radiometric frame layout are upstream work by Les Wright and LeoDJ; this project applies its changes to that code with `scripts/patch_tc001.py` instead of maintaining a fork.
2. Fixing the upstream viewer to run on current NumPy (widening the radiometric half to `int32` before the `* 256` math).
3. Rewriting the image path for human viewing instead of temperature inspection.
4. Getting a Pi to boot straight into a single fullscreen X application with no desktop.
5. Getting analog composite video out of the Pi and into a headset, including debugging the TRRS pinout.
6. Preserving SSH access once composite mode disabled HDMI.
7. Designing a battery power stage and understanding its margins.
8. Packaging all of it into an idempotent installer, an uninstaller, and a verification script.

## Why cheap hardware

A Pi and a consumer thermal camera are obviously not production-grade for any of the use cases above. They are, however, enough to prove the architecture, learn where the latency and power constraints are, and iterate on software with a real sensor in the loop. The goal is to have the pipeline and operator workflow worked out before spending money on a better sensor, a compute module, or a custom board.
