#!/usr/bin/env python3
"""Generate favicon.ico matching the small logo appearance (eye crop + staircase circle).

The favicon uses the same eye-only crop as yogsototh-logo.png with a pixelated
circle mask (staircase edges), not a smooth one.

Run from the logo/ directory:
    nix-shell -p python3Packages.pillow --run "python3 make_favicon.py"
"""
from PIL import Image
import math

IMG_DIR = "../src/Scratch/img"


def make_pixelated_circle_mask(size):
    """Create a circle mask with hard pixel edges (no anti-aliasing)."""
    mask = Image.new("L", (size, size), 0)
    cx, cy = size / 2, size / 2
    r = size / 2 - 0.5
    for y in range(size):
        for x in range(size):
            dist = math.sqrt((x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2)
            mask.putpixel((x, y), 255 if dist <= r else 0)
    return mask


# Use the same source and crop as make_round_logo.py for the small logo
src = Image.open(f"{IMG_DIR}/yogsototh-eye-cosmic-128.png").convert("RGBA")
cx, cy = 64, 64
crop_r = 28
src = src.crop((cx - crop_r, cy - crop_r, cx + crop_r, cy + crop_r))

sizes = [16, 32, 48, 64]
icons = []
for sz in sizes:
    img = src.resize((sz, sz), Image.NEAREST)
    mask = make_pixelated_circle_mask(sz)
    img.putalpha(mask)
    icons.append(img)

for path in ["../src/favicon.ico", f"{IMG_DIR}/favicon.ico"]:
    icons[0].save(
        path,
        format="ICO",
        sizes=[(sz, sz) for sz in sizes],
        append_images=icons[1:],
    )
    print(f"Saved {path}")
