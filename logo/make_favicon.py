#!/usr/bin/env python3
"""Generate favicon.ico from the pixel art logo with multiple sizes.

Run from the logo/ directory:
    nix-shell -p python3Packages.pillow --run "python3 make_favicon.py"
"""
from PIL import Image

IMG_DIR = "../src/Scratch/img"

src = Image.open(f"{IMG_DIR}/yogsototh-eye-cosmic-round-128.png").convert("RGBA")

sizes = [16, 32, 48, 64]
icons = [src.resize((sz, sz), Image.NEAREST) for sz in sizes]

for path in [f"../src/favicon.ico", f"{IMG_DIR}/favicon.ico"]:
    icons[0].save(
        path,
        format="ICO",
        sizes=[(sz, sz) for sz in sizes],
        append_images=icons[1:],
    )
    print(f"Saved {path}")
