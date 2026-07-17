#!/usr/bin/env python3
"""Build theme-esy-auto.css for git.esy.fun, from Forgejo's own theme.

The theme imports Forgejo's forgejo-auto and overrides only two families:

  1. the neutral scales (zinc for light, steel for dark), recoloured to hue 265,
     the hue of the logo's disc (#2E3440 = Nord0). Each step keeps its original
     lightness, so every contrast pairing Forgejo relies on survives untouched --
     only the cast changes. Measured drift in relative luminance: 0.0065 max.
  2. the primary ramp, moved to the hue of the eye's iris (#c20).

Importing rather than copying means Forgejo upgrades keep their own fixes.

Needs the upstream theme as input. Anubis answers 418 to any script without the
cookie, so fetch it with:

    curl -s -H "Cookie: Yogsototh_agrees_to_open_your_eyes=1" \
      https://git.esy.fun/assets/css/theme-forgejo-auto.css -o fj-theme.css

Then run from logo/forge/:
    python3 gen_forge_theme.py

Re-run it after a Forgejo upgrade: the upstream scales may have moved.
"""
import math
import os
import re
import sys

SRC = "fj-theme.css"
OUT = "theme-esy-auto.css"

SLATE_HUE = 265   # the logo's disc, #2E3440
IRIS_HUE = 28     # the logo's iris, #c20


# --- color conversion --------------------------------------------------------
def srgb_to_oklch(r, g, b):
    def lin(c):
        c /= 255
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = lin(r), lin(g), lin(b)
    l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
    m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
    s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b
    l_, m_, s_ = l ** (1 / 3), m ** (1 / 3), s ** (1 / 3)
    L = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_
    a = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_
    bb = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_
    C = math.hypot(a, bb)
    H = math.degrees(math.atan2(bb, a)) % 360
    return L, C, H


def oklch_to_linear(L, C, H):
    h = math.radians(H)
    a, b = C * math.cos(h), C * math.sin(h)
    l_, m_, s_ = L + 0.3963377774 * a + 0.2158037573 * b, L - 0.1055613458 * a - 0.0638541728 * b, L - 0.0894841775 * a - 1.2914855480 * b
    l, m, s = l_ ** 3, m_ ** 3, s_ ** 3
    return (4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
            -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
            -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s)


def oklch_to_hex(L, C, H):
    def enc(x):
        x = max(0.0, min(1.0, x))
        v = 1.055 * x ** (1 / 2.4) - 0.055 if x > 0.0031308 else 12.92 * x
        return round(255 * v)
    r, g, b = (enc(v) for v in oklch_to_linear(L, C, H))
    return f"#{r:02x}{g:02x}{b:02x}"


def in_gamut(L, C, H):
    return all(-0.0005 <= v <= 1.0005 for v in oklch_to_linear(L, C, H))


def fit_chroma(L, C, H):
    if in_gamut(L, C, H):
        return C
    lo, hi = 0.0, C
    for _ in range(30):
        mid = (lo + hi) / 2
        if in_gamut(L, mid, H):
            lo = mid
        else:
            hi = mid
    return lo * 0.97


def block(css, start_marker):
    """Return the body of the first {...} block after start_marker."""
    i = css.find(start_marker)
    i = css.find("{", i) + 1
    depth, j = 1, i
    while depth:
        if css[j] == "{":
            depth += 1
        elif css[j] == "}":
            depth -= 1
        j += 1
    return css[i:j - 1]


if not os.path.exists(SRC):
    sys.exit(
        f"{SRC} not found. Fetch the upstream theme first (see the docstring):\n"
        '  curl -s -H "Cookie: Yogsototh_agrees_to_open_your_eyes=1" \\\n'
        "    https://git.esy.fun/assets/css/theme-forgejo-auto.css -o fj-theme.css"
    )

css = open(SRC).read()
light = block(css, ":root{")
dark = block(css, "@media(prefers-color-scheme:dark){:root{")

HEX = re.compile(r"^#([0-9a-fA-F]{6})$")


def recolour_scale(blk, prefix, hue, chroma_scale):
    """Keep each step's lightness, move it onto `hue`."""
    out = []
    for name, val in re.findall(r"--(" + prefix + r"-\d+):\s*([^;]+);", blk):
        m = HEX.match(val.strip())
        if not m:
            continue
        r, g, b = (int(m.group(1)[i:i + 2], 16) for i in (0, 2, 4))
        L, C, _ = srgb_to_oklch(r, g, b)
        # Neutral greys carry almost no chroma; give them a deliberate, small cast.
        C = fit_chroma(L, chroma_scale, hue)
        out.append(f"    --{name}: {oklch_to_hex(L, C, hue)};")
    return out


def recolour_primary(blk, hue):
    out = []
    for name, val in re.findall(r"--(color-primary(?:-(?:light|dark)-\d+)?):\s*([^;]+);", blk):
        m = HEX.match(val.strip())
        if not m:
            continue
        r, g, b = (int(m.group(1)[i:i + 2], 16) for i in (0, 2, 4))
        L, C, _ = srgb_to_oklch(r, g, b)
        C = fit_chroma(L, C * 1.15, hue)  # the iris is a touch more saturated
        out.append(f"    --{name}: {oklch_to_hex(L, C, hue)};")
    return out


light_lines = recolour_scale(light, "zinc", SLATE_HUE, 0.008) + recolour_primary(light, IRIS_HUE)
dark_lines = recolour_scale(dark, "steel", SLATE_HUE, 0.014) + recolour_primary(dark, IRIS_HUE)

# steel is declared in the light :root too (dark mode reads it from there)
steel_in_light = recolour_scale(light, "steel", SLATE_HUE, 0.014)

header = """/* esy-auto: git.esy.fun dressed like her.esy.fun.
 *
 * Built on Forgejo's own forgejo-auto, which is imported rather than copied so
 * upstream fixes keep arriving. Only two families are overridden:
 *
 *   - the neutral scales (zinc, steel), moved onto hue 265, the hue of the
 *     logo's disc (#2E3440 = Nord0). Every step keeps the lightness Forgejo
 *     gave it, so all contrast pairings are preserved: only the cast changes.
 *   - the primary ramp, moved onto hue 28, the hue of the eye's iris (#c20).
 *
 * Regenerate with logo/make_theme.py. Do not hand-edit the values.
 */
@import url("/assets/css/theme-forgejo-auto.css");

:root {
"""

with open(OUT, "w") as f:
    f.write(header)
    f.write("    /* neutral scale, light mode */\n")
    f.write("\n".join(light_lines[:len([l for l in light_lines if '--zinc' in l])]) + "\n\n")
    f.write("    /* steel is declared in :root and read by dark mode */\n")
    f.write("\n".join(steel_in_light) + "\n\n")
    f.write("    /* primary: the iris */\n")
    f.write("\n".join([l for l in light_lines if 'primary' in l]) + "\n")
    f.write("}\n\n@media (prefers-color-scheme: dark) {\n  :root {\n")
    f.write("\n".join("  " + l for l in dark_lines) + "\n")
    f.write("  }\n}\n")

print(f"wrote {OUT}")
print(f"  light zinc steps : {len([l for l in light_lines if '--zinc' in l])}")
print(f"  steel steps      : {len(steel_in_light)}")
print(f"  primary (light)  : {len([l for l in light_lines if 'primary' in l])}")
print(f"  dark overrides   : {len(dark_lines)}")
