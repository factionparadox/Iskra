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


def shaded_pine(d, x, base, h, colour, light):
    """a conifer with a lit side: ragged tiers in the base colour, dithered highlights on the left"""
    tiers = int(5 + h / 30)
    d.line([(x, base), (x, base - h * 0.95)], fill=tuple(int(c * 0.7) for c in colour) + (255,), width=max(1, int(h / 70)))
    for t in range(tiers):
        f = t / tiers
        ty = base - h + h * f * 0.93
        hw = h * (0.05 + 0.19 * f) * rng.uniform(0.8, 1.15)
        drop = h * 0.15
        pts = [(x, ty), (x - hw, ty + drop), (x - hw * 0.4, ty + drop * 0.8),
               (x + hw * 0.4, ty + drop * 0.85), (x + hw, ty + drop)]
        d.polygon(pts, fill=colour + (255,))
        # the lit side: a thinner wedge on the left, lighter
        d.polygon([(x, ty + 1), (x - hw * 0.85, ty + drop * 0.95), (x - hw * 0.3, ty + drop * 0.75)], fill=light + (255,))


def forest_row(w, h, horizon, height, colour, light, density, skip=None):
    layer = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    x = -20
    while x < w + 20:
        x += density * rng.uniform(0.35, 1.0)
        if skip and skip[0] < x < skip[1]:
            continue
        th = height * rng.uniform(0.6, 1.3)
        jit = rng.uniform(-6, 6)
        col = tuple(min(255, max(0, c + int(rng.uniform(-8, 8)))) for c in colour)
        shaded_pine(d, x, horizon + jit, th, col, light)
    d.rectangle([0, horizon, w, h], fill=colour + (255,))
    return layer


def shafts(w, h):
    """pale light falling through the mist"""
    layer = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for x0, wd in ((180, 70), (330, 40), (610, 90), (760, 50)):
        d.polygon([(x0, 0), (x0 + wd, 0), (x0 + wd * 2.4 - 120, 430), (x0 + wd * 1.2 - 160, 430)], fill=(236, 236, 250, 40))
    return layer.filter(ImageFilter.GaussianBlur(14))


def crystal(img, cx, cy, size):
    """a floating crystal beacon: a dark diamond with glowing cyan edges, and its glow"""
    glow = Image.new('RGBA', img.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([cx - size * 2.2, cy - size * 2.4, cx + size * 2.2, cy + size * 2.4], fill=(95, 216, 240, 70))
    img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(size)))
    d = ImageDraw.Draw(img)
    top, bot, l, r = (cx, cy - size * 1.6), (cx, cy + size * 1.6), (cx - size, cy), (cx + size, cy)
    d.polygon([top, r, bot, l], fill=(20, 22, 34, 255))
    d.polygon([top, (cx + size * 0.35, cy), (cx, cy + size * 0.5), (cx - size * 0.35, cy)], fill=(44, 48, 70, 255))
    for a, b in ((top, r), (r, bot), (bot, l), (l, top)):
        d.line([a, b], fill=(140, 236, 255, 255), width=2)
    # outer brackets, like a target marker
    for sx in (-1, 1):
        d.line([(cx + sx * size * 1.5, cy - size * 0.9), (cx + sx * size * 1.9, cy), (cx + sx * size * 1.5, cy + size * 0.9)], fill=(95, 216, 240, 255), width=2)
    d.rectangle([cx - 2, cy - 2, cx + 2, cy + 2], fill=(255, 63, 90, 255))


def plant(d, x, y, kind):
    if kind == 'frond':   # a red feathery bloom on a pale stalk
        d.line([(x, y), (x + 2, y - 46)], fill=(214, 206, 186, 255), width=3)
        for k in range(12):
            a = math.radians(-180 + k * 15)
            d.line([(x + 2, y - 46), (x + 2 + math.cos(a) * 30, y - 46 + math.sin(a) * 14)], fill=(176, 40, 36, 255), width=3)
            d.line([(x + 2, y - 46), (x + 2 + math.cos(a) * 22, y - 50 + math.sin(a) * 10)], fill=(214, 70, 52, 255), width=2)
    else:                 # an orange bulb in broad leaves
        for k in range(6):
            a = math.radians(-160 + k * 28)
            d.polygon([(x, y), (x + math.cos(a) * 34, y + math.sin(a) * 20 - 6), (x + math.cos(a + 0.2) * 20, y + math.sin(a) * 10)], fill=(46, 96, 52, 255))
        d.ellipse([x - 16, y - 40, x + 16, y - 10], fill=(222, 128, 40, 255))
        d.ellipse([x - 10, y - 36, x + 2, y - 24], fill=(244, 176, 90, 255))
        for k in (-8, 0, 8):
            d.line([(x + k, y - 40), (x + k * 0.6, y - 12)], fill=(190, 98, 30, 255), width=1)


def wallpaper(pasha):
    # painted at the console's sort of resolution, then scaled up with hard pixels
    w, h = 960, 640
    mist = (200, 198, 218)
    sky = gradient(w, h, [(0, (120, 116, 166)), (0.22, (156, 152, 192)), (0.48, mist), (1, mist)])
    img = Image.fromarray(sky.astype(np.uint8)).convert('RGBA')
    d = ImageDraw.Draw(img)
    # soft cloud banks
    clouds = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    cd = ImageDraw.Draw(clouds)
    for _ in range(18):
        x, y = rng.uniform(-60, w), rng.uniform(40, 200)
        cd.ellipse([x, y, x + rng.uniform(140, 300), y + rng.uniform(18, 40)], fill=(214, 212, 232, 90))
    img.alpha_composite(clouds.filter(ImageFilter.GaussianBlur(10)))
    # far mountains
    d = ImageDraw.Draw(img)
    ridge = [(x, 250 - 30 * math.sin(x / 80) - 16 * math.sin(x / 27 + 1)) for x in range(0, w + 8, 8)]
    d.polygon([(0, 380)] + ridge + [(w, 380)], fill=(150, 146, 182, 255))
    img.alpha_composite(fog_band(w, h, 220, 340, mist, 0.6))

    # forest rows with lit sides, mist pooling at each foot; a clearing in the middle rows
    rows = [(330, 60, (126, 134, 150), (150, 156, 170), 14, None),
            (348, 100, (94, 112, 112), (120, 136, 132), 20, None),
            (366, 150, (60, 86, 74), (88, 116, 96), 28, None),
            (384, 210, (36, 60, 46), (62, 92, 66), 40, None)]
    for i, (hz, ht, col, lit, dens, skip) in enumerate(rows):
        img.alpha_composite(forest_row(w, h, hz, ht, col, lit, dens, skip))
        img.alpha_composite(fog_band(w, h, hz - ht * 0.55, hz + 4, mist, 0.46 - i * 0.09))
    img.alpha_composite(shafts(w, h))

    # the meadow on its plateau
    top = 384
    meadow = gradient(w, 540 - top, [(0, (112, 148, 96)), (0.2, (78, 116, 64)), (1, (40, 74, 40))])
    noise = np.random.default_rng(5).normal(0, 6, meadow.shape[:2])[:, :, None]
    blotch = np.asarray(Image.fromarray((np.random.default_rng(6).random((14, 30)) * 255).astype(np.uint8))
                        .resize((w, 540 - top), Image.BICUBIC)).astype(np.float32)[:, :, None]
    meadow = np.clip(meadow + noise + (blotch - 128) * 0.16, 0, 255).astype(np.uint8)
    img.paste(Image.fromarray(meadow).convert('RGBA'), (0, top))
    d = ImageDraw.Draw(img)
    d.line([(0, top), (w, top)], fill=(146, 176, 118, 255), width=2)

    # the pond, holding the sky, with a lighter rim
    d.ellipse([590, 420, 900, 470], fill=(170, 170, 204, 255), outline=(220, 222, 238, 255), width=2)
    d.ellipse([630, 432, 860, 448], fill=(190, 190, 218, 255))

    # grass, thicker towards the edge (not on the pond)
    for _ in range(1500):
        x, y = rng.uniform(0, w), rng.uniform(top + 4, 540)
        if 580 < x < 910 and 414 < y < 476:
            continue
        sh = (y - top) / (540 - top)
        g = lerp((124, 160, 104), (34, 64, 34), sh)
        d.line([(x, y), (x + rng.uniform(-2, 2), y - 2 - 8 * sh)], fill=g + (255,), width=1)

    # the cut-away edge of the plateau: a ragged grassy lip over dark layered earth
    lip = [(x, 540 + 6 * math.sin(x / 31) + rng.uniform(-3, 3)) for x in range(0, w + 6, 6)]
    d.polygon(lip + [(w, h), (0, h)], fill=(32, 24, 26, 255))
    for k, col in enumerate([(46, 36, 34), (38, 30, 30), (28, 22, 24)]):
        y0 = 560 + k * 26
        d.polygon([(x, y0 + 5 * math.sin(x / 47 + k)) for x in range(0, w + 8, 8)] + [(w, h), (0, h)], fill=col + (255,))
    for x, y in lip[::2]:
        d.line([(x, y - 2), (x + rng.uniform(-2, 2), y + rng.uniform(4, 12))], fill=(58, 100, 50, 255), width=2)
    d.line(lip, fill=(84, 126, 66, 255), width=3)
    # roots and stones in the earth
    for _ in range(40):
        x, y = rng.uniform(0, w), rng.uniform(560, h)
        d.ellipse([x, y, x + rng.uniform(3, 9), y + rng.uniform(2, 5)], fill=(62, 52, 50, 255))

    # plants of the garden
    plant(d, 150, 470, 'frond')
    plant(d, 520, 500, 'bulb')
    plant(d, 860, 520, 'frond')

    # the crystal beacons, floating above the meadow
    crystal(img, 240, 300, 16)
    crystal(img, 770, 330, 12)

    # the pixies' sparks
    glow = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for c in [(95, 216, 240), (255, 63, 164), (232, 196, 110), (120, 220, 120), (191, 234, 247)] * 3:
        x, y, r = rng.uniform(80, w - 80), rng.uniform(220, 470), rng.uniform(2, 3.5)
        gd.ellipse([x - r * 3, y - r * 3, x + r * 3, y + r * 3], fill=c + (60,))
        gd.ellipse([x - r, y - r, x + r, y + r], fill=c + (255,))
    img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(1)))

    # Pasha on a rock in the right third, rimmed in cyan light: the keeper
    d = ImageDraw.Draw(img)
    rock = [(560, 512), (585, 486), (640, 478), (690, 488), (708, 514), (690, 526), (590, 528)]
    d.polygon(rock, fill=(96, 98, 112, 255))
    d.polygon([(585, 486), (640, 478), (690, 488), (650, 494), (600, 496)], fill=(140, 142, 160, 255))
    p = pasha.resize((170, 170), Image.LANCZOS)
    rim = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    alpha = p.split()[3].filter(ImageFilter.MaxFilter(7))
    rim.paste(Image.new('RGBA', p.size, (120, 230, 255, 200)), (552, 348), alpha)
    img.alpha_composite(rim.filter(ImageFilter.GaussianBlur(4)))
    img.alpha_composite(p, (552, 348))

    # vignette
    yy, xx = np.mgrid[0:h, 0:w]
    v = 1 - 0.45 * np.clip(((xx - w / 2) / (w * 0.62)) ** 2 + ((yy - h * 0.45) / (h * 0.7)) ** 2, 0, 1)
    a = np.asarray(img.convert('RGB')).astype(np.float32) * v[:, :, None]
    img = Image.fromarray(a.astype(np.uint8))

    img = bayer_dither(img, levels=48)
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
