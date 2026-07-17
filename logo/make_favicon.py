#!/usr/bin/env python3
"""Generate favicon.ico from the classic eye, on the same pixel grid as the logo.

The 32px icon is the logo's own base grid and the 64px one is that grid doubled,
so the favicon and the header logo show the same pixels. The 16px icon is drawn
flat: at that size the dithered shading would only read as noise.

The eye is already transparent outside its disc, so no circular mask is applied.

Run from the logo/ directory:
    nix-shell -p python3Packages.pillow --run "python3 make_favicon.py"
"""
from gen_classic_eye import make_eye, upscale_nearest

IMG_DIR = "../src/Scratch/img"

# Pillow drops any requested size larger than the image it saves, and only
# reuses an appended image when its size matches exactly. So the largest icon
# has to be the one saved, with the smaller ones appended.
icons = [
    make_eye(16, shaded=False),
    make_eye(32),
    upscale_nearest(make_eye(32), 2),
]
largest = icons[-1]
others = icons[:-1]

for path in ["../src/favicon.ico", f"{IMG_DIR}/favicon.ico"]:
    largest.save(
        path,
        format="ICO",
        sizes=[img.size for img in icons],
        append_images=others,
    )
    print(f"Saved {path} ({', '.join(f'{i.size[0]}px' for i in icons)})")
