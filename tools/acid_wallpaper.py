#!/usr/bin/env python3
"""Generate smooth blacklight-poster wallpapers for the acid-trip theme.

No external images: the whole thing is a numpy kaleidoscopic plasma fractal,
coloured through the theme's own colors.toml so the palette stays in sync.

Usage:
  uv run --with numpy --with pillow python acid_wallpaper.py \
      --colors colors.toml --out backgrounds --width 2880 --height 1800
"""

from __future__ import annotations

import argparse
import math
import os
import random

import numpy as np
from PIL import Image, ImageFilter


def read_colors(path: str) -> dict[str, str]:
    colors: dict[str, str] = {}
    with open(path, "r", encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            value = value.strip()
            if " #" in value:  # trailing inline comment
                value = value.split(" #", 1)[0].rstrip()
            value = value.strip('"').strip("'")
            colors[key.strip()] = value
    return colors


def hex_rgb(value: str) -> np.ndarray:
    value = value.lstrip("#")
    return np.array([int(value[i : i + 2], 16) for i in (0, 2, 4)], dtype=np.float64)


def build_palette(colors: dict[str, str]) -> np.ndarray:
    # Most of the image sits in the deep violet-black end so the saturated
    # bands read as light rather than as flat colour.
    stops = [
        (0.00, colors["darker_background"]),
        (0.34, colors["background"]),
        (0.56, colors["selection"]),
        (0.70, colors["magenta"]),
        (0.82, colors["blue"]),
        (0.90, colors["cyan"]),
        (0.955, colors["green"]),
        (1.00, colors["yellow"]),
    ]
    positions = np.array([s[0] for s in stops], dtype=np.float64)
    rgb = np.stack([hex_rgb(s[1]) for s in stops]).astype(np.float64)
    lut_x = np.linspace(0.0, 1.0, 1024)
    lut = np.stack([np.interp(lut_x, positions, rgb[:, c]) for c in range(3)], axis=1)
    return lut


def fbm(x: np.ndarray, y: np.ndarray, rng: random.Random, octaves: int = 5) -> np.ndarray:
    total = np.zeros_like(x)
    amplitude = 1.0
    norm = 0.0
    for i in range(octaves):
        freq = 2.0**i
        angle = rng.uniform(0.0, math.tau)
        phase = rng.uniform(0.0, math.tau)
        ca, sa = math.cos(angle), math.sin(angle)
        total += amplitude * np.sin(freq * (x * ca + y * sa) + phase)
        norm += amplitude
        amplitude *= 0.55
    return total / norm


def kaleidoscope(dx: np.ndarray, dy: np.ndarray, segments: int, twist: float) -> tuple[np.ndarray, np.ndarray]:
    r = np.hypot(dx, dy)
    a = np.arctan2(dy, dx) + twist * r
    seg = math.tau / segments
    a = np.abs(np.mod(a, seg) - seg * 0.5)
    return r * np.cos(a), r * np.sin(a)


def render(width: int, height: int, colors: dict[str, str], seed: int, segments: int) -> Image.Image:
    rng = random.Random(seed)
    aspect = width / height
    yy, xx = np.mgrid[0:height, 0:width].astype(np.float64)
    # Normalise to a centred, aspect-correct plane.
    x = (xx / width - 0.5) * 2.0 * aspect
    y = (yy / height - 0.5) * 2.0

    kx, ky = kaleidoscope(x, y, segments, twist=rng.uniform(0.5, 1.4))

    warp = fbm(kx * 1.6, ky * 1.6, rng, octaves=4)
    field = fbm(kx * 2.2 + warp, ky * 2.2 - warp, rng, octaves=6)

    r = np.hypot(x, y)
    field += 0.35 * np.sin(r * rng.uniform(3.5, 6.5) - 1.7 * warp)
    field += 0.18 * fbm(x * 4.0 + 3.0, y * 4.0, rng, octaves=3)

    # Squash into 0..1 and push the midtones down so the canvas stays dark.
    t = (field - field.min()) / (field.max() - field.min() + 1e-9)
    t = np.clip(t, 0.0, 1.0) ** 1.45

    vignette = np.clip(1.15 - 0.55 * (r / r.max()) ** 1.6, 0.0, 1.0)
    t = np.clip(t * vignette, 0.0, 1.0)

    palette = build_palette(colors)
    idx = np.clip((t * (len(palette) - 1)).astype(np.int32), 0, len(palette) - 1)
    rgb = palette[idx]

    # A whisper of blur keeps every gradient continuous (no hard banding).
    img = Image.fromarray(rgb.astype(np.uint8), "RGB")
    img = img.filter(ImageFilter.GaussianBlur(1.2))
    return img


VARIANTS = [
    ("0-plasma-gate.jpg", 11, 7),
    ("1-liquid-eye.jpg", 29, 12),
    ("2-veil.jpg", 47, 5),
    ("3-acid-bloom.jpg", 83, 9),
]


def main() -> None:
    here = os.path.dirname(os.path.abspath(__file__))
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--colors", default=os.path.join(here, "..", "colors.toml"))
    parser.add_argument("--out", default=os.path.join(here, "..", "backgrounds"))
    parser.add_argument("--width", type=int, default=2880)
    parser.add_argument("--height", type=int, default=1800)
    args = parser.parse_args()

    colors = read_colors(args.colors)
    os.makedirs(args.out, exist_ok=True)
    for name, seed, segments in VARIANTS:
        img = render(args.width, args.height, colors, seed, segments)
        path = os.path.join(args.out, name)
        img.save(path, quality=92, optimize=True)
        print(f"wrote {path} ({args.width}x{args.height}, seed={seed}, segments={segments})")


if __name__ == "__main__":
    main()
