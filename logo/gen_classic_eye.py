#!/usr/bin/env python3
"""Generate the site logo: the classic Yog-Sothoth eye as a 16-bit style sprite.

The shapes and colors come from the original vector logo (logo/old-logo.svg):
a dark disc with a light rim, a red iris, an amber pupil and a white highlight.
They are redrawn on a 32x32 grid with hard staircase edges, plus a few 16-bit
touches: a rim lit from the top left, a shaded crescent inside the disc and the
iris, and a pupil that glows from its center.

Everything outside the disc stays transparent, so no circular mask is needed
downstream.

Run from the logo/ directory:
    nix-shell -p python3Packages.pillow --run "python3 gen_classic_eye.py"
"""
from PIL import Image
import math

OUTPUT_DIR = "../src/Scratch/img"

# Base grid. The original viewBox is 64x64, so every radius below is halved.
BASE_SIZE = 32

# Palette: the six colors of old-logo.svg, plus one lighter and one darker step
# per material for the 16-bit shading.
DISC = (46, 52, 64)  # #2E3440
DISC_DARK = (35, 40, 50)
DISC_LIGHT = (59, 66, 82)
RIM = (163, 174, 194)  # #a3aec2
RIM_DARK = (104, 114, 134)
IRIS = (204, 34, 0)  # #c20
IRIS_RIM = (136, 0, 0)  # #800
IRIS_LIGHT = (232, 66, 17)
PUPIL = (255, 170, 0)  # #fa0
PUPIL_RIM = (255, 102, 0)  # #f60
PUPIL_CORE = (255, 226, 130)
WHITE = (255, 255, 255)

BAYER4 = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def dither(x, y, t):
    """Ordered dither, used only in the narrow bands between two flat tones."""
    return t > (BAYER4[y % 4][x % 4] + 0.5) / 16.0


def make_eye(size=BASE_SIZE, shaded=True):
    """Draw the eye on a size x size grid. Radii follow the original 64x64 SVG.

    With shaded=False the eye keeps the flat tones of the original vector logo.
    Below ~24px the dithered bands turn into noise, so small icons want flat.
    """
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = img.load()
    s = size / 64.0
    c = size / 2.0

    r_disc = 30 * s
    rim_w = max(1.0, 1.2 * s)
    r_iris = 12 * s
    iris_rim_w = max(1.0, 1.0 * s)
    r_pupil = 5 * s
    pupil_rim_w = max(1.0, 0.9 * s)
    hl_cx, hl_cy, hl_rx, hl_ry = 32 * s, 14 * s, 14 * s, 8 * s

    for y in range(size):
        for x in range(size):
            dx, dy = x + 0.5 - c, y + 0.5 - c
            dist = math.hypot(dx, dy)
            if dist > r_disc:
                continue

            # Light direction, top left. Positive is lit, negative is shaded.
            lit = -(dx + dy * 1.15) / (r_disc * 1.6)

            if dist > r_disc - rim_w:
                px[x, y] = RIM_DARK if (shaded and lit < -0.28) else RIM
                continue

            px[x, y] = DISC
            if shaded:
                inner = (dist - (r_disc - rim_w * 4)) / (rim_w * 4)
                if inner > 0:
                    if lit < -0.3:
                        px[x, y] = DISC_DARK if dither(x, y, inner) else DISC
                    elif lit > 0.34:
                        px[x, y] = DISC_LIGHT if dither(x, y, inner) else DISC

            if dist <= r_iris:
                px[x, y] = IRIS
                if shaded:
                    lit_iris = -(dx + dy * 1.15) / (r_iris * 1.7)
                    if lit_iris > 0.34 and dist > r_pupil:
                        px[x, y] = IRIS_LIGHT
                if dist > r_iris - iris_rim_w:
                    px[x, y] = IRIS_RIM

            if dist <= r_pupil:
                px[x, y] = PUPIL
                if shaded and dist <= r_pupil * 0.45:
                    px[x, y] = PUPIL_CORE
                if dist > r_pupil - pupil_rim_w:
                    px[x, y] = PUPIL_RIM

            if ((x + 0.5 - hl_cx) / hl_rx) ** 2 + ((y + 0.5 - hl_cy) / hl_ry) ** 2 <= 1.0:
                px[x, y] = WHITE
    return img


def upscale_nearest(img, factor):
    return img.resize((img.size[0] * factor, img.size[1] * factor), Image.NEAREST)


def main():
    base = make_eye(BASE_SIZE)

    # The upscales keep whole pixel blocks, so any browser resampling error
    # stays small relative to a block.
    for factor in (1, 4, 8):
        img = base if factor == 1 else upscale_nearest(base, factor)
        path = f"{OUTPUT_DIR}/yogsototh-eye-{BASE_SIZE * factor}.png"
        img.save(path)
        print(f"  -> {path} ({'native' if factor == 1 else f'{factor}x upscale'})")


if __name__ == "__main__":
    print(f"Generating the classic eye on a {BASE_SIZE}x{BASE_SIZE} grid")
    main()
