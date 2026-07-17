#!/usr/bin/env python3
"""Generate the logo assets git.esy.fun serves, from the site's own eye.

Forgejo serves five images; the sizes here mirror the ones it ships, so nothing
downstream has to change shape. The SVG is emitted as one rect per run of
identical pixels: a browser upscaling a PNG is at the mercy of its resampler,
while rects stay exact at any size.

Run from logo/forge/:
    nix-shell -p python3Packages.pillow --run "python3 gen_forge_assets.py"

Then deploy (see the org note for the full procedure):
    scp logo.svg favicon.svg logo.png favicon.png apple-touch-icon.png \
        root@esy.fun:/usr/local/share/forgejo/custom/public/assets/img/
"""
import sys
import os

from PIL import Image

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from gen_classic_eye import make_eye, upscale_nearest  # noqa: E402

OUT_DIR = os.path.dirname(os.path.abspath(__file__))


def to_svg(img):
    """One rect per horizontal run of identical pixels."""
    w, h = img.size
    px = img.load()
    rects = []
    for y in range(h):
        x = 0
        while x < w:
            r, g, b, a = px[x, y]
            if a == 0:
                x += 1
                continue
            run = 1
            while x + run < w and px[x + run, y] == (r, g, b, a):
                run += 1
            rects.append(
                f'<rect x="{x}" y="{y}" width="{run}" height="1" fill="#{r:02x}{g:02x}{b:02x}"/>'
            )
            x += run
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" '
        f'shape-rendering="crispEdges" role="img" aria-label="Yog-Sothoth eye">'
        f'{"".join(rects)}</svg>'
    )


def main():
    svg = to_svg(make_eye(32))
    for name in ("logo.svg", "favicon.svg"):
        with open(os.path.join(OUT_DIR, name), "w") as f:
            f.write(svg)
        print(f"  -> {name} ({len(svg)} bytes, {svg.count('<rect')} rects)")

    base = upscale_nearest(make_eye(32), 16)  # 512x512, whole pixel blocks
    base.save(os.path.join(OUT_DIR, "logo.png"))
    print("  -> logo.png (512x512)")

    # 180 is not a multiple of 32, so blocks land on 5 or 6 px. Invisible at
    # icon size, and Forgejo serves these two at exactly 180.
    icon = base.resize((180, 180), Image.NEAREST)
    for name in ("favicon.png", "apple-touch-icon.png"):
        icon.save(os.path.join(OUT_DIR, name))
        print(f"  -> {name} (180x180)")


if __name__ == "__main__":
    print("Generating the Forgejo logo assets")
    main()
