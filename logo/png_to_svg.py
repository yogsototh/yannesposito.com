#!/usr/bin/env python3
"""Convert pixel art PNG to optimized SVG using path-based encoding.

Each color becomes a single <path> using M (move) and h/v (line) commands,
which is far more compact than individual <rect> elements.
"""

from PIL import Image
from collections import defaultdict
import os


def png_to_svg(input_path, output_path, round_mask=True):
    img = Image.open(input_path).convert("RGBA")
    w, h = img.size
    pixels = img.load()

    # Step 1: horizontal runs per color
    color_runs = defaultdict(list)  # color -> [(x, y, width)]
    for y in range(h):
        x = 0
        while x < w:
            r, g, b, a = pixels[x, y]
            if a < 32:
                x += 1
                continue
            color = (r, g, b)
            run_len = 1
            while x + run_len < w:
                nr, ng, nb, na = pixels[x + run_len, y]
                if na >= 32 and (nr, ng, nb) == color:
                    run_len += 1
                else:
                    break
            color_runs[color].append((x, y, run_len))
            x += run_len

    # Step 2: Merge vertically adjacent runs
    merged_runs = defaultdict(list)  # color -> [(x, y, width, height)]
    for color, runs in color_runs.items():
        idx = defaultdict(list)
        for x, y, width in runs:
            idx[(x, width)].append(y)
        for (x, width), ys in idx.items():
            ys.sort()
            sy = ys[0]
            sh = 1
            for i in range(1, len(ys)):
                if ys[i] == sy + sh:
                    sh += 1
                else:
                    merged_runs[color].append((x, sy, width, sh))
                    sy = ys[i]
                    sh = 1
            merged_runs[color].append((x, sy, width, sh))

    # Step 3: Encode each color as a single <path>
    # Each rect (x,y,w,h) becomes: M x y h w v h h -w z
    def rects_to_path(rects):
        parts = []
        for x, y, width, height in rects:
            parts.append(f"M{x},{y}h{width}v{height}h-{width}z")
        return "".join(parts)

    # Step 4: Build SVG
    lines = []
    lines.append(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" shape-rendering="crispEdges">')

    if round_mask:
        cx, cy = w / 2, h / 2
        r = w * 30 / 64
        lines.append(f'<defs><clipPath id="c"><circle cx="{cx}" cy="{cy}" r="{r}"/></clipPath></defs>')
        lines.append('<g clip-path="url(#c)">')

    # Sort by number of rects descending (background first)
    for color, rects in sorted(merged_runs.items(), key=lambda x: -len(x[1])):
        hex_color = f"#{color[0]:02x}{color[1]:02x}{color[2]:02x}"
        path_d = rects_to_path(rects)
        lines.append(f'<path fill="{hex_color}" d="{path_d}"/>')

    if round_mask:
        lines.append('</g>')
    lines.append('</svg>')

    svg_content = '\n'.join(lines)
    with open(output_path, 'w') as f:
        f.write(svg_content)
    return len(svg_content)


if __name__ == "__main__":
    base = os.path.join(os.path.dirname(__file__), '..', 'src', 'Scratch', 'img')
    input_png = os.path.join(base, 'yogsototh-eye-cosmic-128.png')
    output_svg = os.path.join(base, 'yogsototh-logo.svg')

    size = png_to_svg(input_png, output_svg, round_mask=True)

    png_size = os.path.getsize(os.path.join(base, 'yogsototh-logo-hd.png'))
    png128_size = os.path.getsize(input_png)
    print(f"SVG:       {size:,} bytes ({size/1024:.1f} KB)")
    print(f"PNG 128:   {png128_size:,} bytes ({png128_size/1024:.1f} KB)")
    print(f"PNG HD:    {png_size:,} bytes ({png_size/1024:.1f} KB)")

    # Also check gzipped size
    import gzip
    with open(output_svg, 'rb') as f:
        raw = f.read()
    gz = gzip.compress(raw, compresslevel=9)
    svgz_path = output_svg.replace('.svg', '.svgz')
    with open(svgz_path, 'wb') as f:
        f.write(gz)
    print(f"SVGZ:      {len(gz):,} bytes ({len(gz)/1024:.1f} KB)")
