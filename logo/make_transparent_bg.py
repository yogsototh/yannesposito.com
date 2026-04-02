#!/usr/bin/env python3
"""Remove the starry background from the logo, making it transparent.

Strategy: flood-fill from corners with tolerance to catch the dark background
and scattered star pixels, preserving the eye/tentacles/spheres.
"""

from PIL import Image
import os
from collections import deque


def flood_fill_transparent(img, start_x, start_y, tolerance=60):
    """Flood fill from a starting point, making similar-colored pixels transparent."""
    pixels = img.load()
    w, h = img.size
    start_color = pixels[start_x, start_y][:3]
    visited = set()
    queue = deque([(start_x, start_y)])

    def color_distance(c1, c2):
        return sum((a - b) ** 2 for a, b in zip(c1, c2)) ** 0.5

    while queue:
        x, y = queue.popleft()
        if (x, y) in visited:
            continue
        if x < 0 or x >= w or y < 0 or y >= h:
            continue
        visited.add((x, y))

        r, g, b, a = pixels[x, y]
        if a == 0:
            continue
        if color_distance((r, g, b), start_color) <= tolerance:
            pixels[x, y] = (0, 0, 0, 0)
            for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                nx, ny = x + dx, y + dy
                if (nx, ny) not in visited:
                    queue.append((nx, ny))


def main():
    base = os.path.join(os.path.dirname(__file__), '..', 'src', 'Scratch', 'img')
    input_path = os.path.join(base, 'yogsototh-eye-cosmic-128.png')
    output_path = os.path.join(base, 'yogsototh-logo-transparent.png')

    img = Image.open(input_path).convert("RGBA")
    w, h = img.size

    # Flood fill from all four corners to catch the background
    for sx, sy in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]:
        flood_fill_transparent(img, sx, sy, tolerance=60)

    img.save(output_path, "PNG")

    orig_size = os.path.getsize(input_path)
    new_size = os.path.getsize(output_path)
    print(f"Original:    {orig_size:,} bytes ({orig_size/1024:.1f} KB)")
    print(f"Transparent: {new_size:,} bytes ({new_size/1024:.1f} KB)")
    print(f"Saved to: {output_path}")


if __name__ == "__main__":
    main()
