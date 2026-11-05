#!/usr/bin/env python3
"""make-garden-art.py: Avalon's Garden System artwork, drawn from scratch (an original scene in
the spirit of late-1990s PlayStation games: misty lavender sky, layered pine forest, a grassy
plateau, a still pond, ordered dithering), with Pasha, the Garden's keeper, from branding/pasha.png.

    python3 build/make-garden-art.py            writes into desktop/usr/share/avalon/

  garden-wallpaper.png   2880x1920, the desktop, lock screen and login background
  pasha-portrait.png     512x512, Pasha in a cyan glow (launcher, lock, login, Neredy)
  pasha-fastfetch.png    Pasha for fastfetch's picture logo
"""
import math
import random
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = Path(__file__).resolve().parent.parent
OUT = HERE / 'desktop/usr/share/avalon'
PASHA = HERE / 'branding/pasha.png'
W, H = 2880, 1920
rng = random.Random(1999)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))


def gradient(w, h, stops):
    """vertical gradient through (position, colour) stops"""
    a = np.zeros((h, w, 3), np.float32)
    ys = np.linspace(0, 1, h)
    for i in range(3):
        a[:, :, i] = np.interp(ys, [p for p, _ in stops], [c[i] for _, c in stops])[:, None]
    return a


def jagged_pine(d, x, base, h, colour):
    """a conifer as the PlayStation drew them: a ragged stack of tiers on a thin trunk"""
    tiers = int(5 + h / 40)
    d.line([(x, base), (x, base - h * 0.95)], fill=colour, width=max(1, int(h / 60)))
    for t in range(tiers):
        f = t / tiers
        ty = base - h + h * f * 0.92
        hw = h * (0.05 + 0.20 * f) * rng.uniform(0.8, 1.15)
        drop = h * 0.16
        d.polygon([(x, ty), (x - hw, ty + drop), (x - hw * 0.35, ty + drop * 0.82),
                   (x + hw * 0.35, ty + drop * 0.86), (x + hw, ty + drop)], fill=colour)


def forest_layer(w, h, horizon, height, colour, density):
    """one row of forest on a transparent layer"""
    layer = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    x = -20
    while x < w + 20:
        x += density * rng.uniform(0.35, 1.0)
        th = height * rng.uniform(0.6, 1.25)
        jagged_pine(d, x, horizon + rng.uniform(-4, 6), th, colour + (255,))
    d.rectangle([0, horizon, w, h], fill=colour + (255,))
    return layer


def fog_band(w, h, y0, y1, colour, strength):
    """mist thickening towards y1 (the foot of a forest row)"""
    a = np.zeros((h, w, 4), np.uint8)
    a[:, :, :3] = colour
    ys = np.arange(h)
    alpha = np.clip((ys - y0) / max(1, (y1 - y0)), 0, 1) * strength
    alpha[ys > y1] = strength
    a[:, :, 3] = (alpha * 255).astype(np.uint8)[:, None]
    return Image.fromarray(a, 'RGBA')


def bayer_dither(img, levels=40):
    """4x4 ordered dither and colour banding: the PlayStation's 15-bit look"""
    a = np.asarray(img).astype(np.float32)
    m = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]], np.float32) / 16 - 0.5
    h, w = a.shape[:2]
    tile = np.tile(m, (h // 4 + 1, w // 4 + 1))[:h, :w][:, :, None]
    step = 255 / (levels - 1)
    a = np.round(a / step + tile) * step
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))


def wallpaper(pasha):
    # painted at the console's sort of resolution, then scaled up with hard pixels
    w, h = 960, 640
    mist = (198, 196, 216)
    sky = gradient(w, h, [(0, (138, 134, 178)), (0.30, (176, 172, 202)), (0.52, mist), (1, mist)])
    img = Image.fromarray(sky.astype(np.uint8)).convert('RGBA')

    # far mountains, pale violet behind the mist
    d = ImageDraw.Draw(img)
    ridge = [(x, 300 - 26 * math.sin(x / 70) - 14 * math.sin(x / 23 + 1)) for x in range(0, w + 8, 8)]
    d.polygon([(0, 400)] + ridge + [(w, 400)], fill=(160, 156, 188, 255))
    img.alpha_composite(fog_band(w, h, 250, 360, mist, 0.55))

    # four rows of forest, each nearer one darker and taller, mist pooling at their feet
    rows = [(352, 70, (128, 138, 150), 14), (370, 110, (96, 116, 112), 20),
            (390, 160, (64, 90, 76), 30), (410, 230, (38, 62, 48), 44)]
    for i, (hz, ht, col, dens) in enumerate(rows):
        img.alpha_composite(forest_layer(w, h, hz, ht, col, dens))
        img.alpha_composite(fog_band(w, h, hz - ht * 0.5, hz + 4, mist, 0.42 - i * 0.08))

    # the meadow: lighter where it meets the mist, darker towards us, with patchy texture
    meadow = gradient(w, h - 404, [(0, (104, 140, 92)), (0.18, (72, 110, 62)), (1, (30, 58, 32))])
    noise = np.random.default_rng(5).normal(0, 7, meadow.shape[:2])[:, :, None]
    blotch = np.asarray(Image.fromarray((np.random.default_rng(6).random((24, 40)) * 255).astype(np.uint8))
                        .resize((w, h - 404), Image.BICUBIC)).astype(np.float32)[:, :, None]
    meadow = np.clip(meadow + noise + (blotch - 128) * 0.12, 0, 255).astype(np.uint8)
    img.paste(Image.fromarray(meadow).convert('RGBA'), (0, 404))
    d = ImageDraw.Draw(img)
    d.line([(0, 404), (w, 404)], fill=(136, 166, 112, 255), width=2)

    # a still pond holding the sky
    d.ellipse([560, 440, 900, 492], fill=(168, 168, 200, 255), outline=(214, 216, 232, 255), width=2)
    d.ellipse([600, 452, 860, 470], fill=(186, 186, 214, 255))

    # grass tufts, thicker towards us (not on the pond)
    for _ in range(1600):
        x, y = rng.uniform(0, w), rng.uniform(410, h)
        if 550 < x < 910 and 434 < y < 498:
            continue
        s = (y - 404) / (h - 404)
        g = lerp((112, 150, 96), (26, 52, 28), s)
        d.line([(x, y), (x + rng.uniform(-2, 2), y - 2 - 9 * s)], fill=g + (255,), width=1)

    # ferns in the near corners, dark against the meadow
    for cx, side in ((40, 1), (w - 40, -1)):
        for k in range(14):
            ang = math.radians(-90 + side * rng.uniform(5, 70))
            ln = rng.uniform(60, 130)
            x2, y2 = cx + math.cos(ang) * ln, h + math.sin(ang) * ln
            d.line([(cx, h), (x2, y2)], fill=(18, 36, 22, 255), width=3)

    # the pixies' sparks drifting over the meadow
    glow = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for c in [(95, 216, 240), (255, 63, 164), (232, 196, 110), (120, 220, 120), (191, 234, 247)] * 3:
        x, y, r = rng.uniform(80, w - 80), rng.uniform(250, 470), rng.uniform(2, 4)
        gd.ellipse([x - r * 2.5, y - r * 2.5, x + r * 2.5, y + r * 2.5], fill=c + (70,))
        gd.ellipse([x - r, y - r, x + r, y + r], fill=c + (255,))
    img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(1)))

    # Pasha on the meadow's near edge, left of the pond, keeping watch
    p = pasha.resize((190, 190), Image.LANCZOS)
    sh = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse([300, 538, 420, 556], fill=(0, 0, 0, 120))
    img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(3)))
    img.alpha_composite(p, (262, 370))

    img = bayer_dither(img.convert('RGB'), levels=48)
    return img.resize((W, H), Image.NEAREST)


def portrait(pasha):
    """Pasha on a transparent ground, a cyan glow behind him"""
    s = 512
    img = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    glow = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([60, 60, s - 60, s - 60], fill=(95, 216, 240, 120))
    img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(50)))
    img.alpha_composite(pasha.resize((460, 460), Image.LANCZOS), (26, 30))
    return img


if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    pasha = Image.open(PASHA).convert('RGBA')
    wallpaper(pasha).save(OUT / 'garden-wallpaper.png', optimize=True)
    portrait(pasha).save(OUT / 'pasha-portrait.png', optimize=True)
    pasha.resize((512, 512), Image.LANCZOS).save(OUT / 'pasha-fastfetch.png', optimize=True)
    print('written to', OUT)
