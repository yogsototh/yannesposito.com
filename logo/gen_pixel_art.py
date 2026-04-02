#!/usr/bin/env python3
"""
Generate pixel art versions of Yog-Sothoth logo.
Multiple variations: cosmic spheres, eldritch eye, tentacled gate, minimalist glyph.
All use limited palettes and deliberate pixel placement.
"""

from PIL import Image, ImageDraw
import math
import random

OUTPUT_DIR = "../src/Scratch/img"

# === Palettes (curated, limited, retro feel) ===

PALETTE_COSMIC = {
    "bg": (10, 8, 20),
    "dark": (25, 15, 50),
    "mid_dark": (50, 30, 90),
    "mid": (80, 50, 140),
    "mid_light": (120, 80, 180),
    "light": (170, 130, 220),
    "highlight": (220, 200, 255),
    "bright": (255, 240, 255),
    "accent1": (100, 200, 180),  # teal glow
    "accent2": (180, 100, 200),  # purple
    "accent3": (60, 180, 140),   # green
    "warm": (200, 150, 100),     # warm accent
}

PALETTE_ELDRITCH = {
    "bg": (5, 10, 5),
    "dark": (10, 30, 15),
    "mid_dark": (20, 55, 30),
    "mid": (30, 85, 45),
    "mid_light": (50, 120, 65),
    "light": (80, 160, 90),
    "highlight": (140, 210, 150),
    "bright": (200, 255, 210),
    "accent1": (180, 180, 50),   # yellow eye
    "accent2": (220, 220, 80),   # bright yellow
    "accent3": (100, 50, 120),   # purple shadow
    "warm": (150, 100, 60),
}

PALETTE_VOID = {
    "bg": (2, 2, 8),
    "dark": (15, 10, 30),
    "mid_dark": (35, 20, 60),
    "mid": (60, 35, 100),
    "mid_light": (90, 55, 140),
    "light": (130, 90, 180),
    "highlight": (180, 150, 220),
    "bright": (230, 220, 255),
    "accent1": (200, 60, 80),    # blood red
    "accent2": (255, 100, 120),  # bright red
    "accent3": (40, 100, 160),   # deep blue
    "warm": (200, 180, 100),
}

PALETTE_MONO = {
    "bg": (0, 0, 0),
    "dark": (20, 20, 20),
    "mid_dark": (50, 50, 50),
    "mid": (85, 85, 85),
    "mid_light": (120, 120, 120),
    "light": (165, 165, 165),
    "highlight": (210, 210, 210),
    "bright": (245, 245, 245),
    "accent1": (140, 140, 140),
    "accent2": (180, 180, 180),
    "accent3": (60, 60, 60),
    "warm": (100, 100, 100),
}


def set_pixel(img, x, y, color):
    """Safe pixel set with bounds check."""
    w, h = img.size
    if 0 <= x < w and 0 <= y < h:
        img.putpixel((x, y), color)


def draw_circle_pixels(img, cx, cy, r, color, fill_color=None):
    """Draw a circle using midpoint algorithm with optional fill."""
    if fill_color:
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                if dx * dx + dy * dy <= r * r:
                    set_pixel(img, cx + dx, cy + dy, fill_color)
    # Border
    x, y = r, 0
    d = 1 - r
    while x >= y:
        for px, py in [
            (cx + x, cy + y), (cx - x, cy + y),
            (cx + x, cy - y), (cx - x, cy - y),
            (cx + y, cy + x), (cx - y, cy + x),
            (cx + y, cy - x), (cx - y, cy - x),
        ]:
            set_pixel(img, px, py, color)
        y += 1
        if d < 0:
            d += 2 * y + 1
        else:
            x -= 1
            d += 2 * (y - x) + 1


def draw_dithered_circle(img, cx, cy, r, colors, density=0.5):
    """Draw a dithered filled circle for texture."""
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            dist_sq = dx * dx + dy * dy
            if dist_sq <= r * r:
                dist = math.sqrt(dist_sq) / max(r, 1)
                # Checkerboard dithering based on distance
                checker = (dx + dy) % 2 == 0
                if dist < 0.3:
                    c = colors[0]
                elif dist < 0.6:
                    c = colors[0] if checker else colors[1]
                elif dist < 0.85:
                    c = colors[1] if checker else colors[2]
                else:
                    c = colors[2]
                set_pixel(img, cx + dx, cy + dy, c)


def draw_line_pixels(img, x0, y0, x1, y1, color):
    """Bresenham's line algorithm."""
    dx = abs(x1 - x0)
    dy = abs(y1 - y0)
    sx = 1 if x0 < x1 else -1
    sy = 1 if y0 < y1 else -1
    err = dx - dy
    while True:
        set_pixel(img, x0, y0, color)
        if x0 == x1 and y0 == y1:
            break
        e2 = 2 * err
        if e2 > -dy:
            err -= dy
            x0 += sx
        if e2 < dx:
            err += dx
            y0 += sy


def add_stars(img, count, color, seed=42):
    """Add star/particle background."""
    rng = random.Random(seed)
    w, h = img.size
    for _ in range(count):
        x = rng.randint(0, w - 1)
        y = rng.randint(0, h - 1)
        if img.getpixel((x, y))[:3] == img.getpixel((0, 0))[:3]:
            brightness = rng.choice([0.3, 0.5, 0.7, 1.0])
            c = tuple(int(v * brightness) for v in color)
            set_pixel(img, x, y, c)


def ordered_dither_2x2(val):
    """Return 2x2 ordered dither pattern for a value 0-4."""
    # Bayer 2x2 threshold matrix: [[0,2],[3,1]]
    thresholds = [[0, 2], [3, 1]]
    pattern = [[False, False], [False, False]]
    for dy in range(2):
        for dx in range(2):
            pattern[dy][dx] = val > thresholds[dy][dx]
    return pattern


# =============================================================
# Variation 1: Cosmic Spheres (Yog-Sothoth as interconnected orbs)
# =============================================================
def generate_cosmic_spheres(size=128):
    pal = PALETTE_COSMIC
    img = Image.new("RGBA", (size, size), pal["bg"] + (255,))
    cx, cy = size // 2, size // 2

    add_stars(img, size * 2, pal["highlight"], seed=1)
    add_stars(img, size, pal["accent1"], seed=2)

    # Interconnecting tendrils between spheres
    spheres_128 = [
        (64, 64, 18),   # central large sphere
        (64, 30, 10),   # top
        (64, 98, 10),   # bottom
        (34, 47, 9),    # upper left
        (94, 47, 9),    # upper right
        (34, 81, 9),    # lower left
        (94, 81, 9),    # lower right
        (44, 28, 5),    # small orbiters
        (84, 28, 5),
        (25, 64, 6),
        (103, 64, 6),
        (44, 100, 5),
        (84, 100, 5),
        (64, 15, 4),
        (64, 113, 4),
        (15, 50, 3),
        (113, 50, 3),
        (15, 78, 3),
        (113, 78, 3),
    ]

    scale = size / 128.0
    spheres = [(int(x * scale), int(y * scale), max(2, int(r * scale)))
               for x, y, r in spheres_128]

    # Draw connections between nearby spheres
    for i, (x1, y1, r1) in enumerate(spheres):
        for j, (x2, y2, r2) in enumerate(spheres):
            if i >= j:
                continue
            dist = math.sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2)
            if dist < 50 * scale:
                draw_line_pixels(img, x1, y1, x2, y2, pal["mid_dark"])

    # Draw spheres with shading
    for sx, sy, sr in spheres:
        if sr >= 8:
            colors = [pal["bright"], pal["light"], pal["mid"], pal["mid_dark"]]
            draw_dithered_circle(img, sx, sy, sr, colors[:3])
            # Specular highlight
            hx, hy = sx - sr // 3, sy - sr // 3
            if sr > 12:
                set_pixel(img, hx, hy, pal["bright"])
                set_pixel(img, hx + 1, hy, pal["highlight"])
                set_pixel(img, hx, hy + 1, pal["highlight"])
            else:
                set_pixel(img, hx, hy, pal["bright"])
        elif sr >= 4:
            draw_dithered_circle(img, sx, sy, sr,
                                 [pal["highlight"], pal["mid_light"], pal["mid"]])
            set_pixel(img, sx - sr // 3, sy - sr // 3, pal["bright"])
        else:
            draw_circle_pixels(img, sx, sy, sr, pal["light"], pal["mid_light"])

    # Central sphere glow effect (larger dithered halo)
    csx, csy, csr = spheres[0]
    for dy in range(-csr - 6, csr + 7):
        for dx in range(-csr - 6, csr + 7):
            dist = math.sqrt(dx * dx + dy * dy)
            if csr < dist < csr + 6:
                px, py = csx + dx, csy + dy
                if 0 <= px < size and 0 <= py < size:
                    cur = img.getpixel((px, py))
                    if cur[:3] == pal["bg"] or cur[:3] == pal["dark"]:
                        fade = (dist - csr) / 6
                        if (dx + dy) % 3 == 0 and fade < 0.5:
                            set_pixel(img, px, py, pal["mid_dark"])
                        elif (dx + dy) % 5 == 0 and fade < 0.3:
                            set_pixel(img, px, py, pal["accent1"])

    return img


# =============================================================
# Variation 2: The Gate (Yog-Sothoth as "The Key and the Gate")
# =============================================================
def generate_gate(size=128):
    pal = PALETTE_VOID
    img = Image.new("RGBA", (size, size), pal["bg"] + (255,))
    s = size / 128.0
    cx, cy = size // 2, size // 2

    add_stars(img, size * 3, pal["mid"], seed=7)
    add_stars(img, size, pal["accent3"], seed=8)

    # Outer gate frame (arch shape)
    gate_w = int(40 * s)
    gate_h = int(55 * s)
    gate_top = int(18 * s)

    # Draw pillars
    for dx in [-gate_w, gate_w - int(4 * s)]:
        for y in range(gate_top + int(20 * s), gate_top + gate_h):
            for t in range(int(4 * s)):
                px = cx + dx + t
                # Dithered shading on pillars
                if t < int(1 * s):
                    c = pal["mid_dark"]
                elif t < int(3 * s):
                    c = pal["mid"] if (y + t) % 2 == 0 else pal["mid_light"]
                else:
                    c = pal["mid_dark"]
                set_pixel(img, px, y, c)

    # Draw arch (semicircle at top)
    for angle_deg in range(0, 181, 1):
        angle = math.radians(angle_deg)
        for r in range(int(gate_w - 2 * s), int(gate_w + 2 * s)):
            px = cx + int(r * math.cos(angle))
            py = gate_top + int(20 * s) - int(r * math.sin(angle)) + gate_w
            dist_from_mid = abs(r - gate_w)
            if dist_from_mid < 1 * s:
                c = pal["mid_light"]
            else:
                c = pal["mid"] if (px + py) % 2 == 0 else pal["mid_dark"]
            set_pixel(img, px, py, c)

    # Glowing void inside the gate
    for dy in range(-int(30 * s), int(30 * s)):
        for dx in range(-int(35 * s), int(35 * s)):
            px, py = cx + dx, cy + dy - int(5 * s)
            # Check if inside gate area
            in_rect = abs(dx) < gate_w - int(5 * s) and dy > -int(15 * s) and dy < int(30 * s)
            in_arch = (dx * dx + (dy + int(15 * s)) ** 2) < (gate_w - int(5 * s)) ** 2 and dy <= -int(15 * s)
            if in_rect or in_arch:
                dist = math.sqrt(dx * dx + dy * dy) / (35 * s)
                if dist < 0.2:
                    c = pal["bright"]
                elif dist < 0.4:
                    c = pal["highlight"] if (px + py) % 2 == 0 else pal["light"]
                elif dist < 0.6:
                    c = pal["mid_light"] if (px + py) % 2 == 0 else pal["mid"]
                elif dist < 0.8:
                    c = pal["mid"] if (px + py) % 3 == 0 else pal["mid_dark"]
                else:
                    c = pal["mid_dark"] if (px + py) % 2 == 0 else pal["dark"]
                set_pixel(img, px, py, c)

    # Floating spheres inside the gate (Yog-Sothoth peering through)
    inner_spheres = [
        (cx, cy - int(8 * s), int(7 * s)),
        (cx - int(10 * s), cy + int(5 * s), int(5 * s)),
        (cx + int(10 * s), cy + int(5 * s), int(5 * s)),
        (cx, cy + int(15 * s), int(4 * s)),
        (cx - int(5 * s), cy - int(16 * s), int(3 * s)),
        (cx + int(5 * s), cy - int(16 * s), int(3 * s)),
    ]
    for sx, sy, sr in inner_spheres:
        draw_dithered_circle(img, sx, sy, sr,
                             [pal["bright"], pal["accent2"], pal["accent1"]])

    # Runes on pillars
    rng = random.Random(99)
    for side in [-1, 1]:
        px_base = cx + side * gate_w + (0 if side > 0 else int(-4 * s))
        for i in range(5):
            ry = gate_top + int(25 * s) + i * int(9 * s)
            rx = px_base + int(1 * s)
            # Simple rune: small pattern
            pattern = rng.choice([
                [(0, 0), (1, 0), (0, 1), (1, 1), (0, 2)],
                [(0, 0), (1, 1), (0, 2), (1, 0), (1, 2)],
                [(0, 0), (0, 1), (0, 2), (1, 0), (1, 2)],
                [(0, 0), (1, 0), (0, 1), (0, 2), (1, 2)],
            ])
            for pdx, pdy in pattern:
                c = pal["accent1"] if (i + pdx) % 2 == 0 else pal["accent2"]
                set_pixel(img, rx + pdx, ry + pdy, c)

    return img


# =============================================================
# Variation 3: Eldritch Eye (single great eye with tentacles)
# =============================================================
def generate_eldritch_eye(size=128):
    pal = PALETTE_ELDRITCH
    img = Image.new("RGBA", (size, size), pal["bg"] + (255,))
    s = size / 128.0
    cx, cy = size // 2, size // 2

    add_stars(img, size, pal["mid_dark"], seed=20)

    # Tentacles radiating outward
    rng = random.Random(42)
    num_tentacles = 12
    for i in range(num_tentacles):
        angle = (2 * math.pi * i / num_tentacles) + rng.uniform(-0.2, 0.2)
        length = int(rng.uniform(40, 58) * s)
        segments = 30
        prev_x, prev_y = cx, cy
        for seg in range(segments):
            t = seg / segments
            r = length * t
            wobble = math.sin(t * 6 + i * 1.5) * (8 * s * t)
            nx = cx + int(r * math.cos(angle) + wobble * math.cos(angle + math.pi / 2))
            ny = cy + int(r * math.sin(angle) + wobble * math.sin(angle + math.pi / 2))
            # Thickness decreases
            thickness = max(1, int((1 - t) * 3 * s))
            if t < 0.3:
                c = pal["mid"]
            elif t < 0.6:
                c = pal["mid_dark"] if (seg % 2 == 0) else pal["mid"]
            else:
                c = pal["dark"] if (seg % 2 == 0) else pal["mid_dark"]
            draw_line_pixels(img, prev_x, prev_y, nx, ny, c)
            # Add thickness
            for tt in range(1, thickness):
                draw_line_pixels(img, prev_x, prev_y + tt, nx, ny + tt, c)
            prev_x, prev_y = nx, ny
            # Tip dots/suckers
            if seg > segments - 4:
                set_pixel(img, nx, ny, pal["accent1"])

    # Eye socket (dark ellipse)
    eye_rx = int(22 * s)
    eye_ry = int(16 * s)
    for dy in range(-eye_ry - 3, eye_ry + 4):
        for dx in range(-eye_rx - 3, eye_rx + 4):
            nx = (dx / (eye_rx + 3)) ** 2 + (dy / (eye_ry + 3)) ** 2
            if nx <= 1.0:
                set_pixel(img, cx + dx, cy + dy, pal["dark"])

    # Eye shape (almond)
    for dy in range(-eye_ry, eye_ry + 1):
        for dx in range(-eye_rx, eye_rx + 1):
            ex = dx / eye_rx
            ey = dy / eye_ry
            # Almond: circle squeezed at corners
            almond = ex * ex + ey * ey
            if almond <= 1.0:
                # Iris
                iris_r = 10 * s
                dist_center = math.sqrt(dx * dx + dy * dy)
                if dist_center < 4 * s:
                    # Pupil
                    if dist_center < 2 * s:
                        c = pal["bg"]
                    else:
                        c = pal["dark"] if (dx + dy) % 2 == 0 else pal["bg"]
                elif dist_center < iris_r:
                    # Iris with dithered color
                    t = dist_center / iris_r
                    if t < 0.5:
                        c = pal["accent2"] if (dx + dy) % 2 == 0 else pal["accent1"]
                    else:
                        c = pal["accent1"] if (dx + dy) % 2 == 0 else pal["mid"]
                else:
                    # Sclera
                    c = pal["highlight"] if (dx + dy) % 3 != 0 else pal["light"]
                set_pixel(img, cx + dx, cy + dy, c)

    # Eye outline
    for angle_deg in range(360):
        angle = math.radians(angle_deg)
        ex = int(eye_rx * math.cos(angle))
        ey = int(eye_ry * math.sin(angle))
        set_pixel(img, cx + ex, cy + ey, pal["mid_light"])

    # Specular highlight on eye
    hx = cx - int(3 * s)
    hy = cy - int(4 * s)
    set_pixel(img, hx, hy, pal["bright"])
    set_pixel(img, hx + 1, hy, pal["bright"])
    set_pixel(img, hx, hy + 1, pal["highlight"])

    return img


# =============================================================
# Variation 4: Minimalist Glyph (symbol/sigil style)
# =============================================================
def generate_glyph(size=128):
    pal = PALETTE_MONO
    img = Image.new("RGBA", (size, size), pal["bg"] + (255,))
    s = size / 128.0
    cx, cy = size // 2, size // 2

    # Outer circle
    draw_circle_pixels(img, cx, cy, int(50 * s), pal["mid"])
    draw_circle_pixels(img, cx, cy, int(48 * s), pal["mid_dark"])

    # Inner circles (concentric, representing spheres)
    for r in [35, 25, 15]:
        draw_circle_pixels(img, cx, cy, int(r * s), pal["mid"])

    # Central dot cluster (like original logo but organic)
    dots_128 = [
        (64, 64, 5),
        (64, 44, 3), (64, 84, 3),
        (44, 54, 3), (84, 54, 3),
        (44, 74, 3), (84, 74, 3),
        (54, 38, 2), (74, 38, 2),
        (54, 90, 2), (74, 90, 2),
        (34, 64, 2), (94, 64, 2),
        (50, 50, 2), (78, 50, 2),
        (50, 78, 2), (78, 78, 2),
    ]
    dots = [(int(x * s), int(y * s), max(1, int(r * s))) for x, y, r in dots_128]

    # Connect dots with thin lines
    for i, (x1, y1, r1) in enumerate(dots):
        for j, (x2, y2, r2) in enumerate(dots):
            if i >= j:
                continue
            dist = math.sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2)
            if dist < 30 * s:
                # Dithered line
                steps = int(dist)
                for step in range(steps):
                    t = step / max(steps, 1)
                    px = int(x1 + (x2 - x1) * t)
                    py = int(y1 + (y2 - y1) * t)
                    if (px + py) % 3 == 0:
                        set_pixel(img, px, py, pal["mid_dark"])

    # Draw dots
    for dx, dy, dr in dots:
        draw_circle_pixels(img, dx, dy, dr, pal["light"], pal["mid_light"])

    # Radiating lines from center to outer ring
    for i in range(8):
        angle = math.pi * 2 * i / 8
        x1 = cx + int(52 * s * math.cos(angle))
        y1 = cy + int(52 * s * math.sin(angle))
        x2 = cx + int(58 * s * math.cos(angle))
        y2 = cy + int(58 * s * math.sin(angle))
        draw_line_pixels(img, x1, y1, x2, y2, pal["mid"])

    # Small ticks around outer circle
    for i in range(24):
        angle = math.pi * 2 * i / 24
        x1 = cx + int(50 * s * math.cos(angle))
        y1 = cy + int(50 * s * math.sin(angle))
        set_pixel(img, x1, y1, pal["light"])

    return img


# =============================================================
# Variation 5: Writhing Mass (organic, Lovecraftian horror)
# =============================================================
def generate_writhing_mass(size=128):
    pal = PALETTE_COSMIC
    img = Image.new("RGBA", (size, size), pal["bg"] + (255,))
    s = size / 128.0
    cx, cy = size // 2, size // 2

    add_stars(img, size * 2, pal["mid_dark"], seed=55)

    rng = random.Random(77)

    # Organic mass of interconnected bubbles
    bubbles = []
    # Generate clustered bubbles
    for _ in range(40):
        angle = rng.uniform(0, 2 * math.pi)
        dist = rng.gauss(0, 20 * s)
        bx = cx + int(dist * math.cos(angle))
        by = cy + int(dist * math.sin(angle))
        br = max(2, int(rng.gauss(6, 3) * s))
        bubbles.append((bx, by, br))

    # Sort by size (draw big ones first)
    bubbles.sort(key=lambda b: -b[2])

    # Draw organic connections
    for i, (x1, y1, r1) in enumerate(bubbles):
        for j, (x2, y2, r2) in enumerate(bubbles):
            if i >= j:
                continue
            dist = math.sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2)
            if dist < (r1 + r2) * 2:
                draw_line_pixels(img, x1, y1, x2, y2, pal["mid_dark"])

    # Draw bubbles with iridescent shading
    for bx, by, br in bubbles:
        if br >= 5:
            colors = [pal["highlight"], pal["accent1"], pal["mid"]]
            draw_dithered_circle(img, bx, by, br, colors)
            # Membrane effect on edge
            for angle_deg in range(0, 360, 3):
                angle = math.radians(angle_deg)
                ex = bx + int(br * math.cos(angle))
                ey = by + int(br * math.sin(angle))
                set_pixel(img, ex, ey, pal["light"])
            # Specular
            set_pixel(img, bx - br // 3, by - br // 3, pal["bright"])
        else:
            draw_circle_pixels(img, bx, by, br, pal["mid_light"], pal["mid"])

    # Central glow
    for dy in range(-int(8 * s), int(9 * s)):
        for dx in range(-int(8 * s), int(9 * s)):
            dist = math.sqrt(dx * dx + dy * dy)
            if dist < 8 * s:
                px, py = cx + dx, cy + dy
                if 0 <= px < size and 0 <= py < size:
                    cur = img.getpixel((px, py))
                    # Brighten existing pixels slightly
                    new_c = tuple(min(255, c + int(30 * (1 - dist / (8 * s)))) for c in cur[:3])
                    set_pixel(img, px, py, new_c + (255,))

    return img


# =============================================================
# Variation 6: Eldritch Eye + Cosmic Spheres background
# =============================================================
def generate_eye_with_spheres(size=128):
    """Hybrid: cosmic spheres as background, eldritch eye in foreground."""
    # Unified palette: deep cosmic purples with green/yellow eye
    pal = {
        "bg": (8, 5, 18),
        "dark": (18, 12, 40),
        "mid_dark": (40, 25, 75),
        "mid": (65, 40, 120),
        "mid_light": (100, 70, 160),
        "light": (150, 115, 200),
        "highlight": (200, 180, 235),
        "bright": (240, 230, 255),
        # Sphere accents (cool)
        "sphere_bright": (180, 160, 230),
        "sphere_mid": (120, 90, 180),
        "sphere_dim": (70, 50, 130),
        "sphere_glow": (80, 180, 160),     # teal glow on spheres
        # Eye accents (warm/alien contrast)
        "iris_bright": (230, 220, 60),      # bright yellow
        "iris_mid": (180, 190, 40),         # yellow-green
        "iris_dark": (100, 140, 30),        # dark green
        "sclera_light": (210, 230, 200),    # pale green-white
        "sclera_mid": (170, 200, 165),
        "pupil": (5, 5, 5),
        "tentacle_bright": (110, 200, 130),
        "tentacle_mid": (70, 150, 90),
        "tentacle_dark": (40, 100, 60),
        "sucker": (220, 240, 80),           # yellow dots on tentacle tips
    }

    img = Image.new("RGBA", (size, size), pal["bg"] + (255,))
    s = size / 128.0
    cx, cy = size // 2, size // 2

    # --- Background: stars ---
    add_stars(img, size * 3, pal["highlight"], seed=1)
    add_stars(img, size, pal["sphere_glow"], seed=2)

    # --- Background: cosmic spheres ring (arranged around the eye) ---
    # Spheres are pushed outward to frame the eye, not overlap it
    ring_spheres_128 = [
        # Outer ring
        (64, 10, 8),    # top
        (64, 118, 8),   # bottom
        (10, 64, 8),    # left
        (118, 64, 8),   # right
        (22, 22, 7),    # top-left
        (106, 22, 7),   # top-right
        (22, 106, 7),   # bottom-left
        (106, 106, 7),  # bottom-right
        # Mid ring
        (40, 14, 5),
        (88, 14, 5),
        (14, 40, 5),
        (114, 40, 5),
        (14, 88, 5),
        (114, 88, 5),
        (40, 114, 5),
        (88, 114, 5),
        # Small outer orbiters
        (64, 3, 3),
        (64, 125, 3),
        (3, 64, 3),
        (125, 64, 3),
        (10, 10, 3),
        (118, 10, 3),
        (10, 118, 3),
        (118, 118, 3),
        # Extra tiny sparkles
        (30, 6, 2),
        (98, 6, 2),
        (6, 30, 2),
        (122, 30, 2),
        (6, 98, 2),
        (122, 98, 2),
        (30, 122, 2),
        (98, 122, 2),
    ]

    spheres = [(int(x * s), int(y * s), max(1, int(r * s)))
               for x, y, r in ring_spheres_128]

    # Draw connections between nearby spheres
    for i, (x1, y1, r1) in enumerate(spheres):
        for j, (x2, y2, r2) in enumerate(spheres):
            if i >= j:
                continue
            dist = math.sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2)
            if dist < 55 * s:
                # Thin dithered connection line
                steps = int(dist)
                for step in range(steps):
                    t = step / max(steps, 1)
                    px = int(x1 + (x2 - x1) * t)
                    py = int(y1 + (y2 - y1) * t)
                    if (px + py) % 3 == 0:
                        set_pixel(img, px, py, pal["mid_dark"])

    # Draw spheres with shading
    for sx, sy, sr in spheres:
        if sr >= 5:
            draw_dithered_circle(img, sx, sy, sr,
                                 [pal["sphere_bright"], pal["sphere_mid"], pal["sphere_dim"]])
            # Specular highlight
            hx, hy = sx - sr // 3, sy - sr // 3
            set_pixel(img, hx, hy, pal["bright"])
            if sr > 6:
                set_pixel(img, hx + 1, hy, pal["highlight"])
                set_pixel(img, hx, hy + 1, pal["highlight"])
            # Glow ring
            for angle_deg in range(0, 360, 4):
                angle = math.radians(angle_deg)
                gx = sx + int((sr + 1) * math.cos(angle))
                gy = sy + int((sr + 1) * math.sin(angle))
                if 0 <= gx < size and 0 <= gy < size:
                    cur = img.getpixel((gx, gy))
                    if cur[:3] == pal["bg"]:
                        set_pixel(img, gx, gy, pal["mid_dark"])
        elif sr >= 3:
            draw_dithered_circle(img, sx, sy, sr,
                                 [pal["highlight"], pal["sphere_mid"], pal["mid"]])
            set_pixel(img, sx - sr // 3, sy - sr // 3, pal["bright"])
        else:
            draw_circle_pixels(img, sx, sy, sr, pal["light"], pal["sphere_mid"])

    # --- Foreground: tentacles radiating from center ---
    rng = random.Random(42)
    num_tentacles = 14
    for i in range(num_tentacles):
        angle = (2 * math.pi * i / num_tentacles) + rng.uniform(-0.15, 0.15)
        length = int(rng.uniform(35, 52) * s)
        segments = 35
        prev_x, prev_y = cx, cy
        for seg in range(segments):
            t = seg / segments
            r = length * t
            wobble = math.sin(t * 7 + i * 1.3) * (7 * s * t)
            nx = cx + int(r * math.cos(angle) + wobble * math.cos(angle + math.pi / 2))
            ny = cy + int(r * math.sin(angle) + wobble * math.sin(angle + math.pi / 2))
            thickness = max(1, int((1 - t) * 5.5 * s))  # thicker tentacles
            if t < 0.25:
                c = pal["tentacle_bright"]
            elif t < 0.55:
                c = pal["tentacle_mid"] if seg % 2 == 0 else pal["tentacle_bright"]
            else:
                c = pal["tentacle_dark"] if seg % 2 == 0 else pal["tentacle_mid"]
            draw_line_pixels(img, prev_x, prev_y, nx, ny, c)
            # Draw thickness in both directions (perpendicular to line)
            perp_angle = angle + math.pi / 2
            for tt in range(1, thickness):
                ox = int(tt * 0.7 * math.cos(perp_angle))
                oy = int(tt * 0.7 * math.sin(perp_angle))
                draw_line_pixels(img, prev_x + ox, prev_y + oy, nx + ox, ny + oy, c)
                draw_line_pixels(img, prev_x - ox, prev_y - oy, nx - ox, ny - oy, c)
            prev_x, prev_y = nx, ny
            # Suckers near tips
            if seg > segments - 5 and seg % 2 == 0:
                set_pixel(img, nx, ny, pal["sucker"])
                set_pixel(img, nx + 1, ny, pal["sucker"])
                set_pixel(img, nx, ny + 1, pal["sucker"])

    # --- Foreground: the eye ---
    # Lighter socket behind the eye (more visible halo)
    eye_rx = int(26 * s)   # wider
    eye_ry = int(11 * s)   # flatter / more stretched
    socket_pad = int(14 * s)  # large glow area around eye
    for dy in range(-eye_ry - socket_pad, eye_ry + socket_pad + 1):
        for dx in range(-eye_rx - socket_pad, eye_rx + socket_pad + 1):
            norm = (dx / (eye_rx + socket_pad)) ** 2 + (dy / (eye_ry + socket_pad)) ** 2
            if norm <= 1.0:
                fade = norm
                if fade < 0.2:
                    c = pal["light"]  # bright glowing core
                elif fade < 0.35:
                    c = pal["light"] if (dx + dy) % 2 == 0 else pal["mid_light"]
                elif fade < 0.5:
                    c = pal["mid_light"] if (dx + dy) % 2 == 0 else pal["mid"]
                elif fade < 0.65:
                    c = pal["mid"] if (dx + dy) % 2 == 0 else pal["mid_dark"]
                elif fade < 0.8:
                    c = pal["mid_dark"] if (dx + dy) % 2 == 0 else pal["dark"]
                else:
                    c = pal["dark"] if (dx + dy) % 3 == 0 else pal["bg"]
                set_pixel(img, cx + dx, cy + dy, c)

    # Eye shape (almond)
    for dy in range(-eye_ry, eye_ry + 1):
        for dx in range(-eye_rx, eye_rx + 1):
            ex = dx / eye_rx
            ey = dy / eye_ry
            almond = ex * ex + ey * ey
            if almond <= 1.0:
                iris_r = 9 * s
                dist_center = math.sqrt(dx * dx + (dy * 1.8) ** 2)  # scale dy for horizontal iris
                raw_dist = math.sqrt(dx * dx + dy * dy)
                if raw_dist < 5.5 * s:
                    # Pupil - taller vertical slit
                    pupil_h = 5.5 * s
                    slit_width = 1.5 * s * max(0, 1 - (dy / pupil_h) ** 2)
                    if abs(dx) < max(1, slit_width):
                        c = pal["pupil"]
                    else:
                        c = pal["iris_dark"] if (dx + dy) % 2 == 0 else pal["pupil"]
                elif raw_dist < iris_r:
                    # Iris with radial dithered pattern
                    t = raw_dist / iris_r
                    angle_from_center = math.atan2(dy, dx)
                    radial_pat = math.sin(angle_from_center * 8) > 0
                    if t < 0.45:
                        c = pal["iris_bright"] if radial_pat else pal["iris_mid"]
                    elif t < 0.7:
                        c = pal["iris_mid"] if (dx + dy) % 2 == 0 else pal["iris_dark"]
                    else:
                        c = pal["iris_dark"] if radial_pat else pal["tentacle_bright"]
                else:
                    # Sclera
                    edge_t = (raw_dist - iris_r) / (max(eye_rx, eye_ry) - iris_r + 1)
                    if edge_t < 0.4:
                        c = pal["sclera_light"] if (dx + dy) % 3 != 0 else pal["sclera_mid"]
                    else:
                        c = pal["sclera_mid"] if (dx + dy) % 2 == 0 else pal["light"]
                set_pixel(img, cx + dx, cy + dy, c)

    # Eye outline with slight glow
    for angle_deg in range(360):
        angle = math.radians(angle_deg)
        ex = int(eye_rx * math.cos(angle))
        ey = int(eye_ry * math.sin(angle))
        set_pixel(img, cx + ex, cy + ey, pal["tentacle_bright"])
        # Outer glow
        ex2 = int((eye_rx + 1) * math.cos(angle))
        ey2 = int((eye_ry + 1) * math.sin(angle))
        if 0 <= cx + ex2 < size and 0 <= cy + ey2 < size:
            cur = img.getpixel((cx + ex2, cy + ey2))
            if cur[:3] == pal["dark"]:
                set_pixel(img, cx + ex2, cy + ey2, pal["tentacle_dark"])

    # Specular highlights on eye
    hx = cx - int(4 * s)
    hy = cy - int(3 * s)
    set_pixel(img, hx, hy, pal["bright"])
    set_pixel(img, hx + 1, hy, pal["bright"])
    set_pixel(img, hx, hy + 1, pal["highlight"])
    set_pixel(img, hx + 2, hy, pal["highlight"])
    # Second smaller highlight
    set_pixel(img, cx + int(3 * s), cy + int(2 * s), pal["highlight"])

    return img


# =============================================================
# Variation 7: Classic Eye (recalls the old SVG logo colors/structure)
# =============================================================

# Sphere color themes matching the CSS palette (oklch converted to sRGB approx.)
SPHERE_THEMES = {
    "violet": {
        # --v oklch(0.5 0.25 305) and --b oklch(0.5 0.25 265)
        "sphere_bright": (170, 100, 210),
        "sphere_mid": (100, 50, 150),
        "sphere_dim": (55, 25, 90),
        "sphere_glow": (130, 70, 180),
        "star_accent": (140, 80, 200),
    },
    "multi": {
        # Use per-sphere coloring; these are defaults for connections etc.
        "sphere_bright": (170, 100, 210),
        "sphere_mid": (100, 50, 150),
        "sphere_dim": (55, 25, 90),
        "sphere_glow": (100, 160, 160),
        "star_accent": (140, 80, 200),
    },
    "teal": {
        # --c oklch(0.5 0.25 185) and --g oklch(0.5 0.25 155)
        "sphere_bright": (0, 150, 160),
        "sphere_mid": (0, 100, 110),
        "sphere_dim": (0, 55, 65),
        "sphere_glow": (40, 140, 120),
        "star_accent": (60, 170, 150),
    },
}

# Per-sphere color sets for the "multi" theme
# Cycling through: red, orange, violet, teal, blue, magenta, green
MULTI_SPHERE_COLORS = [
    # (bright, mid, dim) tuples matching CSS --r, --o, --v, --c, --b, --m, --g
    ((210, 60, 50), (150, 30, 30), (80, 15, 15)),       # red --r
    ((210, 130, 30), (160, 90, 10), (90, 50, 5)),       # orange --o
    ((170, 100, 210), (100, 50, 150), (55, 25, 90)),    # violet --v
    ((0, 150, 160), (0, 100, 110), (0, 55, 65)),        # teal --c
    ((60, 80, 200), (35, 50, 140), (18, 25, 80)),       # blue --b
    ((180, 60, 140), (120, 30, 90), (65, 15, 50)),      # magenta --m
    ((50, 160, 80), (28, 100, 45), (14, 55, 25)),       # green --g
    ((200, 170, 40), (140, 115, 15), (75, 60, 8)),      # yellow --y
]


def generate_classic_eye(size=128, sphere_theme="violet"):
    """Pixel art eye recalling the old SVG logo: dark background, red iris,
    orange pupil, white highlight ellipse. Colorful cosmic spheres."""
    sph = SPHERE_THEMES[sphere_theme]

    pal = {
        "bg": (12, 10, 22),            # deep purple-black (matches dark mode bg hsl(270,20%,6%))
        "dark": (25, 20, 40),
        "mid_dark": (45, 35, 65),
        "mid": (70, 55, 100),
        "mid_light": (100, 80, 130),
        "light": (140, 120, 170),
        "highlight": (190, 175, 215),
        "bright": (236, 232, 244),
        # Spheres (from theme)
        "sphere_bright": sph["sphere_bright"],
        "sphere_mid": sph["sphere_mid"],
        "sphere_dim": sph["sphere_dim"],
        "sphere_glow": sph["sphere_glow"],
        # Eye: red iris (from old #c20)
        "iris_bright": (220, 60, 20),
        "iris_mid": (204, 34, 0),       # #cc2200 = old #c20
        "iris_dark": (136, 0, 0),       # #880000 = old stroke #800
        # Pupil: orange/amber (from old #fa0)
        "sclera_light": (210, 220, 195),
        "sclera_mid": (170, 185, 155),
        "pupil_bright": (255, 170, 0),  # #ffaa00 = old #fa0
        "pupil_mid": (255, 102, 0),     # #ff6600 = old stroke #f60
        "pupil_dark": (180, 70, 0),
        "pupil_core": (60, 20, 5),
        # Tentacles: hazel brown-green
        "tentacle_bright": (140, 155, 70),
        "tentacle_mid": (100, 115, 48),
        "tentacle_dark": (60, 72, 28),
        "sucker": (180, 170, 50),
    }

    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    s = size / 128.0
    cx, cy = size // 2, size // 2

    # --- Tentacles with spheres at their tips ---
    rng = random.Random(42)
    num_tentacles = 18
    # Pre-generate tentacle parameters for variety
    tentacle_params = []
    for i in range(num_tentacles):
        base_angle = 2 * math.pi * i / num_tentacles
        angle = base_angle + rng.uniform(-0.25, 0.25)
        length = rng.uniform(38, 58) * s
        sphere_r = rng.choice([3, 4, 5, 5, 6, 7, 7, 8]) * s
        wobble_freq = rng.uniform(5, 9)
        wobble_amp = rng.uniform(5, 10)
        tentacle_params.append((angle, length, sphere_r, wobble_freq, wobble_amp))

    # Draw tentacles first, then spheres on top
    tip_positions = []
    for i, (angle, length, sphere_r, wobble_freq, wobble_amp) in enumerate(tentacle_params):
        segments = 35
        prev_x, prev_y = cx, cy
        final_x, final_y = cx, cy
        for seg in range(segments):
            t = seg / segments
            r = length * t
            wobble = math.sin(t * wobble_freq + i * 1.3) * (wobble_amp * s * t)
            nx = cx + int(r * math.cos(angle) + wobble * math.cos(angle + math.pi / 2))
            ny = cy + int(r * math.sin(angle) + wobble * math.sin(angle + math.pi / 2))
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
        tip_positions.append((final_x, final_y, max(2, int(sphere_r))))

    # Draw spheres at tentacle tips
    for idx, (sx, sy, sr) in enumerate(tip_positions):
        if sphere_theme == "multi":
            mc = MULTI_SPHERE_COLORS[idx % len(MULTI_SPHERE_COLORS)]
            sb, sm, sd = mc
        else:
            sb = pal["sphere_bright"]
            sm = pal["sphere_mid"]
            sd = pal["sphere_dim"]

        if sr >= 5:
            draw_dithered_circle(img, sx, sy, sr, [sb, sm, sd])
            hx, hy = sx - sr // 3, sy - sr // 3
            set_pixel(img, hx, hy, pal["bright"])
            if sr > 6:
                set_pixel(img, hx + 1, hy, pal["highlight"])
                set_pixel(img, hx, hy + 1, pal["highlight"])
            for angle_deg in range(0, 360, 4):
                a = math.radians(angle_deg)
                gx = sx + int((sr + 1) * math.cos(a))
                gy = sy + int((sr + 1) * math.sin(a))
                if 0 <= gx < size and 0 <= gy < size:
                    cur = img.getpixel((gx, gy))
                    if cur[:3] == pal["bg"]:
                        set_pixel(img, gx, gy, pal["mid_dark"])
        elif sr >= 3:
            draw_dithered_circle(img, sx, sy, sr, [sb, sm, sd])
            set_pixel(img, sx - sr // 3, sy - sr // 3, pal["bright"])
        else:
            draw_circle_pixels(img, sx, sy, sr, sb, sm)

    # --- Eye socket glow ---
    eye_hw = int(26 * s)   # half-width of the eye (tip to center)
    eye_hh = int(11 * s)   # half-height at the widest point
    # Arc radius for the leaf/vesica shape: two circular arcs
    # Each arc center is offset vertically; the arcs cross at the left and right tips.
    # R and d are chosen so the arcs meet at (+-eye_hw, 0) with max height eye_hh.
    # For a symmetric lens: R = (eye_hw^2 + eye_hh^2) / (2*eye_hh)
    arc_R = (eye_hw * eye_hw + eye_hh * eye_hh) / (2.0 * eye_hh)
    arc_d = arc_R - eye_hh  # vertical offset of arc centers from cy

    def in_eye_shape(dx, dy):
        """Check if point (dx, dy) relative to center is inside the leaf shape.
        The shape is the intersection of two circles:
        - upper arc: center at (0, +arc_d), radius arc_R (curves downward)
        - lower arc: center at (0, -arc_d), radius arc_R (curves upward)
        """
        d1_sq = dx * dx + (dy - arc_d) ** 2
        d2_sq = dx * dx + (dy + arc_d) ** 2
        return d1_sq <= arc_R * arc_R and d2_sq <= arc_R * arc_R

    def eye_shape_dist(dx, dy):
        """Approximate normalized distance from center to edge of the leaf shape.
        0 at center, 1 at the boundary."""
        d1 = math.sqrt(dx * dx + (dy - arc_d) ** 2)
        d2 = math.sqrt(dx * dx + (dy + arc_d) ** 2)
        # The closer we are to either arc boundary, the closer to the edge
        margin1 = arc_R - d1
        margin2 = arc_R - d2
        min_margin = min(margin1, margin2)
        # Normalize: at center the margin is arc_R - arc_d = eye_hh
        return 1.0 - min_margin / eye_hh if eye_hh > 0 else 0

    socket_pad = int(10 * s)
    socket_scale = (eye_hw + socket_pad) / max(eye_hw, 1)
    for dy in range(-eye_hh - socket_pad, eye_hh + socket_pad + 1):
        for dx in range(-eye_hw - socket_pad, eye_hw + socket_pad + 1):
            sdx = dx / socket_scale
            sdy = dy / socket_scale
            if in_eye_shape(sdx, sdy):
                fade = eye_shape_dist(sdx, sdy)
                fade = max(0.0, min(1.0, fade))
                # Fade from light center to tentacle flesh at edges
                if fade < 0.2:
                    c = pal["light"]
                elif fade < 0.35:
                    c = pal["light"] if (dx + dy) % 2 == 0 else pal["mid_light"]
                elif fade < 0.5:
                    c = pal["mid_light"] if (dx + dy) % 2 == 0 else pal["mid"]
                elif fade < 0.65:
                    c = pal["tentacle_bright"] if (dx + dy) % 2 == 0 else pal["mid"]
                elif fade < 0.8:
                    c = pal["tentacle_mid"] if (dx + dy) % 2 == 0 else pal["tentacle_bright"]
                else:
                    c = pal["tentacle_dark"] if (dx + dy) % 3 == 0 else pal["tentacle_mid"]
                set_pixel(img, cx + dx, cy + dy, c)

    # --- Eye shape (leaf / vesica piscis) with RED iris and ORANGE pupil ---
    for dy in range(-eye_hh, eye_hh + 1):
        for dx in range(-eye_hw, eye_hw + 1):
            if not in_eye_shape(dx, dy):
                continue
            iris_r = 9 * s
            raw_dist = math.sqrt(dx * dx + dy * dy)
            if raw_dist < 5.5 * s:
                # Pupil: orange/amber core like old logo #fa0
                pupil_h = 5.5 * s
                slit_width = 1.5 * s * max(0, 1 - (dy / pupil_h) ** 2)
                if abs(dx) < max(1, slit_width):
                    core_dist = math.sqrt(dx * dx + dy * dy) / (3 * s)
                    if core_dist < 0.3:
                        c = pal["pupil_core"]
                    elif core_dist < 0.6:
                        c = pal["pupil_mid"] if (dx + dy) % 2 == 0 else pal["pupil_dark"]
                    else:
                        c = pal["pupil_bright"] if (dx + dy) % 2 == 0 else pal["pupil_mid"]
                else:
                    c = pal["iris_dark"] if (dx + dy) % 2 == 0 else pal["pupil_dark"]
            elif raw_dist < iris_r:
                # Iris: red/crimson like old logo #c20
                t = raw_dist / iris_r
                angle_from_center = math.atan2(dy, dx)
                radial_pat = math.sin(angle_from_center * 8) > 0
                if t < 0.45:
                    c = pal["iris_bright"] if radial_pat else pal["iris_mid"]
                elif t < 0.7:
                    c = pal["iris_mid"] if (dx + dy) % 2 == 0 else pal["iris_dark"]
                else:
                    c = pal["iris_dark"] if radial_pat else pal["tentacle_bright"]
            else:
                # Sclera
                edge_t = (raw_dist - iris_r) / (max(eye_hw, eye_hh) - iris_r + 1)
                if edge_t < 0.4:
                    c = pal["sclera_light"] if (dx + dy) % 3 != 0 else pal["sclera_mid"]
                else:
                    c = pal["sclera_mid"] if (dx + dy) % 2 == 0 else pal["light"]
            set_pixel(img, cx + dx, cy + dy, c)

    # Eye outline: trace the boundary of the leaf shape
    for dy in range(-eye_hh - 1, eye_hh + 2):
        for dx in range(-eye_hw - 1, eye_hw + 2):
            if in_eye_shape(dx, dy):
                # Check if any neighbor is outside
                is_border = False
                for ndx, ndy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                    if not in_eye_shape(dx + ndx, dy + ndy):
                        is_border = True
                        break
                if is_border:
                    set_pixel(img, cx + dx, cy + dy, pal["iris_dark"])

    # --- White highlight ellipse at top (like old SVG logo) ---
    hl_cx = cx
    hl_cy = cy - int(4 * s)
    hl_rx = int(5 * s)
    hl_ry = int(2.5 * s)
    for dy in range(-hl_ry - 1, hl_ry + 2):
        for dx in range(-hl_rx - 1, hl_rx + 2):
            norm = (dx / max(hl_rx, 1)) ** 2 + (dy / max(hl_ry, 1)) ** 2
            if norm <= 1.0:
                if norm < 0.3:
                    c = pal["bright"]
                elif norm < 0.7:
                    c = pal["bright"] if (dx + dy) % 2 == 0 else pal["highlight"]
                else:
                    c = pal["highlight"] if (dx + dy) % 2 == 0 else pal["sclera_light"]
                set_pixel(img, hl_cx + dx, hl_cy + dy, c)

    # Small secondary specular
    set_pixel(img, cx + int(3 * s), cy + int(2 * s), pal["highlight"])

    return img


def upscale_nearest(img, factor):
    """Upscale with nearest neighbor to preserve pixels."""
    w, h = img.size
    return img.resize((w * factor, h * factor), Image.NEAREST)


def main():
    generators = [
        ("eye-cosmic", lambda size: generate_classic_eye(size, "multi"),
         "Classic eye with multicolor spheres"),
    ]

    for name, gen_fn, desc in generators:
        print(f"Generating {name}: {desc}")

        # 32x32 version (chunky pixel art for logo use)
        img_32 = gen_fn(32)
        path_32 = f"{OUTPUT_DIR}/yogsototh-{name}-32.png"
        img_32.save(path_32)
        print(f"  -> {path_32}")

        # 128x128 version
        img_128 = gen_fn(128)
        path_128 = f"{OUTPUT_DIR}/yogsototh-{name}-128.png"
        img_128.save(path_128)
        print(f"  -> {path_128}")

        # 256x256 version (2x upscale of 128 for consistent pixel look)
        img_256 = upscale_nearest(img_128, 2)
        path_256 = f"{OUTPUT_DIR}/yogsototh-{name}-256.png"
        img_256.save(path_256)
        print(f"  -> {path_256} (2x upscale of 128)")

        # 512x512 version (4x upscale of 128 for crisp preview)
        img_512 = upscale_nearest(img_128, 4)
        path_512 = f"{OUTPUT_DIR}/yogsototh-{name}-128x4.png"
        img_512.save(path_512)
        print(f"  -> {path_512} (4x upscale of 128)")

    print("\nDone! Generated 5 variations x 3 sizes = 15 images.")


if __name__ == "__main__":
    main()
