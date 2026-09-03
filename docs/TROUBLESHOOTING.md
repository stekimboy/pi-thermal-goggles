# Troubleshooting

Work through these over SSH. Once composite is enabled there is no HDMI, so the Pi's console *is* the goggles.

## No image in the goggles

Check the Pi side first:

```bash
pgrep -af tc001-goggles
sudo fuser -v /dev/video0
DISPLAY=:0 xrandr --query
```

You want a running viewer process, `/dev/video0` held open by Python, and:

```text
Composite-1 ... 720x480
   720x480i      59.94*+
```

If all three look right and the goggles are still black, it is almost certainly one of:

- the goggles are in RX mode rather than AV mode, or
- the TRRS cable has the wrong pinout (see [`HARDWARE.md`](HARDWARE.md#the-trrs-pinout-problem)).

## `qt.qpa.xcb: could not connect to display`

You launched the viewer by hand from an SSH session. SSH doesn't own the local display. Either prefix with `DISPLAY=:0` or just check on the instance that auto-started:

```bash
pgrep -af tc001-goggles
```

## `OverflowError: Python integer 256 out of bounds for uint8`

The NumPy compatibility patch isn't applied, usually because upstream was updated by hand. Re-run the installer to regenerate the viewer:

```bash
sudo ./install.sh
sudo reboot
```

## Camera not detected

```bash
lsusb
v4l2-ctl --list-devices
```

The TC001 should show up as:

```text
0bda:5830 Realtek Semiconductor Corp. USB Camera
```

with formats including `YUYV 256x192 @ 25 fps` and `YUYV 256x384 @ 25 fps`. If it isn't there, try a different cable; some USB-C cables are charge-only.

## Mouse cursor visible

`unclutter` should be running:

```bash
pgrep -af unclutter
```

If it isn't, check `~/.xinitrc` still has the `unclutter -idle 0 -root &` line.

## Viewer keeps restarting

By default the viewer's output goes to `/dev/null`. To see why it's dying, edit `~/.xinitrc` and change

```bash
>/dev/null 2>&1
```

to

```bash
>>/home/$USER/thermal-goggles.log 2>&1
```

restart X (or reboot), then:

```bash
tail -100 ~/thermal-goggles.log
```

Put the redirect back afterwards so the log doesn't grow forever.

## Image too flat

See [`TUNING.md`](TUNING.md). Raise CLAHE `clipLimit` a little at a time.

## Warm objects are solid white

Global `alpha` has been raised above 1.0. Put it back and use CLAHE for contrast instead.
