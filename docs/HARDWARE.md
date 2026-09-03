# Hardware and Wiring

## What the build uses

- Raspberry Pi 4
- TOPDON TC001 thermal camera (USB-C)
- Quanum Cyclops Diversity DVR FPV goggles
- Raspberry Pi-compatible 3.5 mm TRRS-to-RCA composite cable
- 2S LiPo battery
- MP1584EN adjustable buck converter module
- NTSC composite video at 720x480i, 59.94 Hz

Parts and sourcing are in [`BOM.md`](BOM.md).

## Two video paths, one headset

The Cyclops goggles have a built-in 5.8 GHz diversity receiver and an external AV input. The Pi drives the AV input, so the headset's existing RX/AV control becomes a mode switch:

```text
Path A: normal FPV

  remote FPV camera ──RF──► Cyclops receiver ──► display

Path B: thermal

  TC001 ──USB──► Raspberry Pi 4 ──composite──► Cyclops AV IN ──► display
```

Nothing needs to be unplugged to go between them. This matters more than it sounds: the FPV path keeps working even while the Pi side is being modified or is broken, which makes development a lot less painful.

## Thermal video path

```text
TC001 --USB--> Pi 4 --3.5 mm TRRS--> yellow RCA --> Cyclops AV IN
```

Only the yellow (video) RCA is used. Red and white can stay disconnected.

## The TRRS pinout problem

The Pi 4's 3.5 mm jack is not wired like a camcorder or phone cable. Video is on the **sleeve**:

```text
Tip     = left audio
Ring 1  = right audio
Ring 2  = ground
Sleeve  = composite video
```

A cable with a different mapping gives a black screen even when `xrandr` shows the composite output is up and running. Either buy a cable sold specifically for the Raspberry Pi or check continuity with a multimeter before assuming the software is at fault.

## Composite mode

The installer adds `dtoverlay=vc4-kms-v3d,composite` and `enable_tvout=1` to `config.txt`. The mode that comes up is:

```text
720x480i @ 59.94 Hz (NTSC)
```

Check it from SSH with:

```bash
DISPLAY=:0 xrandr --query
```

Note that enabling composite on the Pi 4 disables HDMI. Plan to do everything over SSH after the first reboot.

## Camera USB device

The TC001 enumerates as a generic UVC camera:

```text
0bda:5830 Realtek Semiconductor Corp. USB Camera
```

It exposes two V4L2 nodes (typically `/dev/video0` and `/dev/video1`) and two formats. The one PyThermalCamera uses is `256x384 @ 25 fps` YUYV, which is actually two stacked 256x192 frames: the top half is the display image and the bottom half is radiometric data.

## Power

The Pi is powered from a 2S LiPo through a small adjustable MP1584EN buck module rather than any kind of USB power bank. The camera draws from the Pi's USB port, so the regulator carries both loads.

```text
2S LiPo (7.4 V nominal, 8.4 V full)
        │
        ▼
MP1584EN adjustable buck converter
        │
        ▼
~5.1 V regulated
        │
        ▼
Raspberry Pi 4 ──USB──► TC001
```

The MP1584 IC accepts 4.5–28 V in and is rated around 3 A out, so a 2S pack is comfortably inside its input range.

### Setting the output voltage

These modules ship at a random output voltage. **Do not connect one to the Pi before adjusting it.**

1. Connect the battery to the converter input with the Pi disconnected.
2. Put a multimeter on the converter output.
3. Turn the trim pot until it reads about 5.1 V.
4. Confirm polarity.
5. Only then connect the output to the Pi.

### Current headroom

The Pi 4 is specced for a 5.1 V / 3 A supply and the MP1584EN is a 3 A-class part, so there is not much margin if the Pi ever pulls its full rated current with the camera attached. The assembled build has run fine in its current configuration, but I treat this as a prototype power stage. The next revision should measure actual current draw under sustained processing and probably move to a physically larger 5 V / 4–5 A module.

## Interfaces left for expansion

The Pi leaves the usual set of interfaces free for future work:

- USB for additional cameras or sensors
- CSI camera connector
- GPIO for buttons and switches
- UART for telemetry
- I2C and SPI for sensors
- Ethernet and Wi-Fi

Obvious additions would be an RGB camera, a GPS/IMU module, a telemetry receiver, or a couple of GPIO buttons for mode control. See [`ARCHITECTURE.md`](ARCHITECTURE.md).
