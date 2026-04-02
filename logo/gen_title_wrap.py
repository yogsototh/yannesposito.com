#!/usr/bin/env python3
"""Generate logo + bottom tentacles images for the title-wrapping effect.

Produces:
- yogsototh-logo-wide.png: the eye with tentacles going up and sideways (wider canvas)
- yogsototh-tentacles-bottom.png: tentacles reaching up from below
"""

from PIL import Image
import math
import random
import os
import sys

# Import drawing functions from main generator
sys.path.insert(0, os.path.dirname(__file__))
from gen_pixel_art import (
    set_pixel, draw_line_pixels, draw_circle_pixels,
    draw_dithered_circle, MULTI_SPHERE_COLORS,
)

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), '..', 'src', 'Scratch', 'img')

PAL = {
    "bg": (12, 10, 22),
    "dark": (25, 20, 40),
    "mid_dark": (45, 35, 65),
    "mid": (70, 55, 100),
    "mid_light": (100, 80, 130),
    "light": (140, 120, 170),
    "highlight": (190, 175, 215),
    "bright": (236, 232, 244),
    "iris_bright": (220, 60, 20),
    "iris_mid": (204, 34, 0),
    "iris_dark": (136, 0, 0),
    "sclera_light": (210, 220, 195),
    "sclera_mid": (170, 185, 155),
    "pupil_bright": (255, 170, 0),
    "pupil_mid": (255, 102, 0),
    "pupil_dark": (180, 70, 0),
    "pupil_core": (60, 20, 5),
    "tentacle_bright": (140, 155, 70),
    "tentacle_mid": (100, 115, 48),
    "tentacle_dark": (60, 72, 28),
    "sucker": (180, 170, 50),
}


def draw_tentacle(img, start_x, start_y, angle, length, wobble_freq, wobble_amp,
                  idx, s, pal):
    """Draw a single tentacle, return tip position."""
    segments = 35
    prev_x, prev_y = start_x, start_y
    final_x, final_y = start_x, start_y
    for seg in range(segments):
        t = seg / segments
        r = length * t
        wobble = math.sin(t * wobble_freq + idx * 1.3) * (wobble_amp * s * t)
        nx = start_x + int(r * math.cos(angle) + wobble * math.cos(angle + math.pi / 2))
        ny = start_y + int(r * math.sin(angle) + wobble * math.sin(angle + math.pi / 2))
        thickness = max(1, int((1 - t) * 7.5 * s))
        if t < 0.3:
            c = pal["tentacle_bright"]
        elif t < 0.6:
            c = pal["tentacle_mid"] if seg % 2 == 0 else pal["tentacle_bright"]
        else:
            c = pal["tentacle_dark"] if seg % 2 == 0 else pal["tentacle_mid"]
        draw_line_pixels(img, prev_x, prev_y, nx, ny, c)
        perp_angle = angle + math.pi / 2
        for tt in range(1, thickness):
            ox = int(tt * 0.7 * math.cos(perp_angle))
            oy = int(tt * 0.7 * math.sin(perp_angle))
            draw_line_pixels(img, prev_x + ox, prev_y + oy, nx + ox, ny + oy, c)
            draw_line_pixels(img, prev_x - ox, prev_y - oy, nx - ox, ny - oy, c)
        prev_x, prev_y = nx, ny
        final_x, final_y = nx, ny
    return final_x, final_y


def draw_sphere(img, sx, sy, sr, idx, pal):
    """Draw a colored sphere at position."""
    mc = MULTI_SPHERE_COLORS[idx % len(MULTI_SPHERE_COLORS)]
    sb, sm, sd = mc
    if sr >= 5:
        draw_dithered_circle(img, sx, sy, sr, [sb, sm, sd])
        hx, hy = sx - sr // 3, sy - sr // 3
        set_pixel(img, hx, hy, pal["bright"])
        if sr > 6:
            set_pixel(img, hx + 1, hy, pal["highlight"])
            set_pixel(img, hx, hy + 1, pal["highlight"])
    elif sr >= 3:
        draw_dithered_circle(img, sx, sy, sr, [sb, sm, sd])
        set_pixel(img, sx - sr // 3, sy - sr // 3, pal["bright"])
    else:
        draw_circle_pixels(img, sx, sy, sr, sb, sm)


def generate_bottom_tentacles(width=256, height=48):
    """Generate tentacles reaching upward from the bottom edge."""
    s = width / 256.0
    img = Image.new("RGBA", (width, height), (0, 0, 0, 0))

    rng = random.Random(99)
    num_tentacles = 8
    for i in range(num_tentacles):
        # Spread across the width, start from bottom
        start_x = int(width * (i + 0.5) / num_tentacles + rng.uniform(-10, 10) * s)
        start_y = height  # start from bottom edge
        # Angle pointing upward with some spread
        angle = -math.pi / 2 + rng.uniform(-0.6, 0.6)
        length = rng.uniform(25, 45) * s
        wobble_freq = rng.uniform(4, 8)
        wobble_amp = rng.uniform(4, 8)
        sphere_r = rng.choice([3, 4, 5, 5, 6]) * s

        tip_x, tip_y = draw_tentacle(img, start_x, start_y, angle, length,
                                      wobble_freq, wobble_amp, i + 20, s, PAL)
        draw_sphere(img, tip_x, tip_y, max(2, int(sphere_r)), i + 20, PAL)

    return img


def main():
    # Generate bottom tentacles at 128-wide (matches logo width scale)
    # and a 2x version for the 256 display
    for scale_name, w, h in [("128", 192, 48), ("256", 384, 96)]:
        img = generate_bottom_tentacles(w, h)
        path = os.path.join(OUTPUT_DIR, f"yogsototh-tentacles-bottom-{scale_name}.png")
        img.save(path)
        size = os.path.getsize(path)
        print(f"  -> {path} ({size:,} bytes, {size/1024:.1f} KB)")


if __name__ == "__main__":
    main()
