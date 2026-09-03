# Bill of Materials

Everything here is off-the-shelf. The point of the build was to get a working sensor-to-display pipeline cheaply and iterate on the software, not to design custom hardware.

## Core

| Component | Role | Notes |
|---|---|---|
| Raspberry Pi 4 | Compute, video processing, composite output | Runs Raspberry Pi OS (Debian Trixie), Python, OpenCV, V4L2, X11/Openbox |
| TOPDON TC001 | Thermal camera | 256x192 LWIR sensor, 25 Hz, USB-C, bus-powered |
| Quanum Cyclops Diversity DVR | Display and FPV receiver | Built-in 5.8 GHz diversity receiver plus external AV input |
| TRRS-to-RCA cable (Pi pinout) | Composite video | Must use the Raspberry Pi mapping; see [`HARDWARE.md`](HARDWARE.md) |
| microSD card | OS storage | 16 GB or larger |

## Portable power

| Component | Role | Notes |
|---|---|---|
| 2S LiPo battery | Power source | 7.4 V nominal, 8.4 V full |
| MP1584EN adjustable buck module | Battery to 5 V regulator | Set to ~5.1 V before connecting the Pi |
| XT60 connector, wire, heat shrink | Interconnect | Sized for the battery; insulate the converter board |

The buck module is the common MP1584EN adjustable step-down board, e.g. the one sold under Amazon ASIN [B01MQGMOKI](https://www.amazon.com/dp/B01MQGMOKI). The MP1584 IC is rated for 4.5–28 V input and roughly 3 A output. Adjustment procedure and the note on current margin are in [`HARDWARE.md`](HARDWARE.md#power).

## Also on the headset

The goggles keep their stock receiver, antennas (a patch antenna and a cloverleaf), and DVR. None of that was modified; the thermal path just uses the AV input that was already there.

## Related

- [`HARDWARE.md`](HARDWARE.md) for wiring, pinout, and power setup
- [`SOFTWARE.md`](SOFTWARE.md) for the software stack
- [`ARCHITECTURE.md`](ARCHITECTURE.md) for how the system is meant to grow
