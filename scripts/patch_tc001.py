#!/usr/bin/env python3
"""Build the dedicated wearable TC001 viewer from upstream PyThermalCamera.

The generated file remains in the upstream checkout so upstream attribution and
license text stay with the original implementation. This script applies only
the integration/display changes used by this project.
"""

from pathlib import Path
import py_compile
import shutil
import sys


def replace_once(text: str, old: str, new: str, description: str) -> str:
    if old not in text:
        raise RuntimeError(f"expected upstream code not found while patching {description}")
    return text.replace(old, new, 1)


def main() -> int:
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} /path/to/PyThermalCamera", file=sys.stderr)
        return 2

    repo = Path(sys.argv[1]).expanduser().resolve()
    source = repo / "src" / "tc001v4.2.py"
    target = repo / "src" / "tc001-goggles.py"

    if not source.exists():
        print(f"ERROR: upstream source not found: {source}", file=sys.stderr)
        return 1

    shutil.copy2(source, target)
    text = target.read_text()

    try:
        # Dedicated wearable defaults.
        text = replace_once(text, "colormap = 0", "colormap = 11", "default colormap")
        text = replace_once(text, "dispFullscreen = False", "dispFullscreen = True", "fullscreen default")
        text = replace_once(text, "threshold = 2", "threshold = 999", "floating-label suppression")
        text = replace_once(text, "hud = True", "hud = False", "HUD default")

        # Start the OpenCV window fullscreen immediately.
        resize = "cv2.resizeWindow('Thermal', newWidth,newHeight)"
        fullscreen = (
            resize
            + "\ncv2.setWindowProperty('Thermal', cv2.WND_PROP_FULLSCREEN, "
              "cv2.WINDOW_FULLSCREEN)"
        )
        text = replace_once(text, resize, fullscreen, "fullscreen window setup")

        # Modern NumPy rejects uint8 * 256. Widen the radiometric half once
        # immediately after the frame split.
        split = "\t\timdata,thdata = np.array_split(frame, 2)"
        text = replace_once(
            text,
            split,
            split + "\n\t\tthdata = thdata.astype(np.int32)",
            "NumPy compatibility",
        )

        # Add white-hot and black-hot modes. White hot uses CLAHE to recover
        # local definition and a mild unsharp mask for edge/detail visibility.
        marker = "\t\t#print(heatmap.shape)"
        extra_maps = """\t\tif colormap == 11:\n\t\t\tgray = cv2.cvtColor(bgr, cv2.COLOR_BGR2GRAY)\n\n\t\t\t# Local contrast enhancement for wearable thermal viewing\n\t\t\tclahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8,8))\n\t\t\tgray = clahe.apply(gray)\n\n\t\t\t# Mild unsharp mask for better edges and facial/object definition\n\t\t\tblurred = cv2.GaussianBlur(gray, (0,0), 0.8)\n\t\t\tgray = cv2.addWeighted(gray, 1.3, blurred, -0.3, 0)\n\n\t\t\theatmap = cv2.cvtColor(gray, cv2.COLOR_GRAY2BGR)\n\t\t\tcmapText = 'White Hot'\n\n\t\tif colormap == 12:\n\t\t\tgray = cv2.cvtColor(bgr, cv2.COLOR_BGR2GRAY)\n\t\t\tclahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8,8))\n\t\t\tgray = clahe.apply(gray)\n\t\t\tblurred = cv2.GaussianBlur(gray, (0,0), 0.8)\n\t\t\tgray = cv2.addWeighted(gray, 1.3, blurred, -0.3, 0)\n\t\t\tgray = cv2.bitwise_not(gray)\n\t\t\theatmap = cv2.cvtColor(gray, cv2.COLOR_GRAY2BGR)\n\t\t\tcmapText = 'Black Hot'\n\n"""
        text = replace_once(text, marker, extra_maps + marker, "white/black-hot modes")

        # Keep the crosshair, remove the center temperature text entirely.
        center_start = text.find("\t\t#show temp")
        center_end = text.find("\n\t\tif hud==True:", center_start)
        if center_start == -1 or center_end == -1:
            raise RuntimeError("expected center-temperature block not found")
        text = (
            text[:center_start]
            + "\t\t# Center temperature text intentionally hidden for goggles use\n"
            + text[center_end + 1 :]
        )

        # Expand upstream keyboard colormap cycling to include modes 11 and 12.
        text = replace_once(
            text,
            "\t\t\tif colormap == 11:\n\t\t\t\tcolormap = 0",
            "\t\t\tif colormap == 13:\n\t\t\t\tcolormap = 0",
            "colormap cycling",
        )

        # Note at the top of the file that it was built by this script; upstream credit stays intact.
        shebang = "#!/usr/bin/env python3\n"
        notice = (
            shebang
            + "# Built by pi-thermal-goggles/scripts/patch_tc001.py from upstream tc001v4.2.py.\n"
            + "# Wearable display modifications are applied on top of upstream PyThermalCamera.\n"
        )
        text = replace_once(text, shebang, notice, "header notice")

    except RuntimeError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    target.write_text(text)

    try:
        py_compile.compile(str(target), doraise=True)
    except py_compile.PyCompileError as exc:
        print(f"ERROR: generated viewer failed compile check: {exc}", file=sys.stderr)
        return 1

    print(f"Created patched goggles viewer: {target}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
