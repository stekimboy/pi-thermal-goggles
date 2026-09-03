# Display Tuning

The defaults are chosen for looking *through* goggles, where you want edges and shapes, not for reading temperatures off a screen.

## Default pipeline

```text
TC001 image
   ↓
grayscale
   ↓
CLAHE local contrast
   ↓
mild unsharp mask
   ↓
white-hot
   ↓
crosshair
```

Values in the generated viewer:

```python
alpha = 1.0                 # global gain, left at the upstream default; the patcher does not touch it
clipLimit = 2.0             # CLAHE
tileGridSize = (8, 8)       # CLAHE
gaussian_sigma = 0.8        # blur for the unsharp mask
unsharp = 1.3 / -0.3        # addWeighted(gray, 1.3, blurred, -0.3)
```

## If the image looks flat

Raise `clipLimit` in `tc001-goggles.py` from `2.0` toward `3.0`. Go in small steps; past about 3 the noise floor starts to look like texture.

## If the image looks harsh or noisy

Lower `clipLimit` toward `1.5`, or reduce the unsharp weights (for example `1.2 / -0.2`).

## Why global gain stays at 1.0

Raising `alpha` pushes every warm pixel toward 255, and once a face or a hand is all 255 there is no detail left to see. CLAHE increases contrast inside local tiles, so a warm region keeps its internal structure instead of becoming a white blob.

## Colormaps

The upstream palettes are all still there. This project adds:

```text
11 = White Hot   (default)
12 = Black Hot
```

With a keyboard attached, `m` cycles through all of them. A GPIO button wired to the same `colormap` variable would do the job without a keyboard.
