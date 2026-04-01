#!/usr/bin/env python3
"""Create circular logo versions from the pixel art base images.

Run from the logo/ directory:
    nix-shell -p python3Packages.pillow --run "python3 make_round_logo.py"
"""
from PIL import Image
import math

IMG_DIR = "../src/Scratch/img"


def make_soft_circle_mask(size, fade_px=3):
    """Create a circular mask with progressive transparency on the outer edge."""
    mask = Image.new("L", (size, size), 0)
    cx, cy = size / 2, size / 2
    r = size / 2
    for y in range(size):
        for x in range(size):
            dist = math.sqrt((x - cx + 0.5) ** 2 + (y - cy + 0.5) ** 2)
            if dist <= r - fade_px:
                alpha = 255
            elif dist <= r:
                alpha = int(255 * (r - dist) / fade_px)
            else:
                alpha = 0
            mask.putpixel((x, y), alpha)
    return mask


# Round versions of the base images
for size_label, src_name, fade in [
    ("128", "yogsototh-eye-cosmic-128.png", 3),
    ("256", "yogsototh-eye-cosmic-256.png", 5),
]:
    img = Image.open(f"{IMG_DIR}/{src_name}").convert("RGBA")
    mask = make_soft_circle_mask(img.size[0], fade_px=fade)
    img.putalpha(mask)
    out_path = f"{IMG_DIR}/yogsototh-eye-cosmic-round-{size_label}.png"
    img.save(out_path)
    print(f"Saved {out_path}")

# Logo small: crop center eye from 128px, downscale to 32px, upscale to 512px
img = Image.open(f"{IMG_DIR}/yogsototh-eye-cosmic-128.png").convert("RGBA")
cx, cy = 64, 64
crop_r = 28
img = img.crop((cx - crop_r, cy - crop_r, cx + crop_r, cy + crop_r))
img = img.resize((32, 32), Image.NEAREST)
img = img.resize((512, 512), Image.NEAREST)
mask = make_soft_circle_mask(512, fade_px=10)
img.putalpha(mask)
img.save(f"{IMG_DIR}/yogsototh-logo.png")
print("Saved yogsototh-logo.png (eye-only crop, 32px base, chunky)")

# Logo HD: 128px base upscaled 4x to 512px
img = Image.open(f"{IMG_DIR}/yogsototh-eye-cosmic-128.png").convert("RGBA")
img = img.resize((512, 512), Image.NEAREST)
mask = make_soft_circle_mask(512, fade_px=10)
img.putalpha(mask)
img.save(f"{IMG_DIR}/yogsototh-logo-hd.png")
print("Saved yogsototh-logo-hd.png (128px base, detailed)")
