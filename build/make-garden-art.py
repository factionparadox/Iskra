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


def plant(d, x, y, kind, k=1.0):
    """a plant of the garden, k times its full size"""
    if kind == 'frond':   # a red feathery bloom on a pale stalk
        top = y - 46 * k
        d.line([(x, y), (x + 1, top)], fill=(196, 188, 170, 255), width=max(1, int(3 * k)))
        for i in range(12):
            a = math.radians(-180 + i * 15)
            d.line([(x + 1, top), (x + 1 + math.cos(a) * 30 * k, top + math.sin(a) * 14 * k)], fill=(150, 34, 32, 255), width=max(1, int(2 * k)))
            d.line([(x + 1, top), (x + 1 + math.cos(a) * 20 * k, top - 3 * k + math.sin(a) * 9 * k)], fill=(196, 62, 46, 255), width=1)
    else:                 # an orange bulb in broad leaves
        for i in range(6):
            a = math.radians(-160 + i * 28)
            d.polygon([(x, y), (x + math.cos(a) * 34 * k, y + (math.sin(a) * 20 - 6) * k), (x + math.cos(a + 0.2) * 20 * k, y + math.sin(a) * 10 * k)], fill=(40, 84, 46, 255))
        d.ellipse([x - 16 * k, y - 40 * k, x + 16 * k, y - 10 * k], fill=(196, 112, 36, 255))
        d.ellipse([x - 10 * k, y - 36 * k, x + 2 * k, y - 24 * k], fill=(226, 160, 82, 255))
        for j in (-8, 0, 8):
            d.line([(x + j * k, y - 40 * k), (x + j * 0.6 * k, y - 12 * k)], fill=(168, 88, 28, 255), width=1)



JP = '/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc'
SANS = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'


def font(path, size):
    from PIL import ImageFont
    try:
        return ImageFont.truetype(path, size)
    except OSError:
        return ImageFont.load_default()


def chamfer(d, box, cut, fill, outline, width=1):
    x0, y0, x1, y1 = box
    pts = [(x0 + cut, y0), (x1, y0), (x1, y1 - cut), (x1 - cut, y1), (x0, y1), (x0, y0 + cut)]
    d.polygon(pts, fill=fill)
    d.line(pts + [pts[0]], fill=outline, width=width)


ELEMENTS = [(201, 163, 90), (74, 100, 200), (91, 200, 91), (224, 112, 90)]


def stat_plate(d, x, y, values):
    """four slanted bars in the element colours, each with its number: hovering over an object"""
    f = font(SANS, 10)
    for i, (col, v) in enumerate(zip(ELEMENTS, values)):
        yy = y + i * 13
        d.polygon([(x + 8, yy), (x + 92, yy), (x + 84, yy + 11), (x, yy + 11)], fill=(10, 14, 28, 230), outline=(70, 96, 140, 255))
        d.polygon([(x + 12, yy + 3), (x + 34, yy + 3), (x + 30, yy + 8), (x + 8, yy + 8)], fill=col + (255,))
        d.text((x + 80, yy - 1), str(v), font=f, fill=(238, 244, 251, 255), anchor='ra')


def bubble(img, cx, cy, r):
    """a pixie asleep in a glossy bubble"""
    layer = Image.new('RGBA', img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(170, 200, 240, 80), outline=(220, 236, 255, 200), width=2)
    # the curled figure inside: head, body, folded wings
    d.ellipse([cx - r * 0.35, cy - r * 0.45, cx + r * 0.05, cy - r * 0.05], fill=(240, 236, 250, 200))
    d.ellipse([cx - r * 0.25, cy - r * 0.15, cx + r * 0.4, cy + r * 0.45], fill=(214, 206, 236, 190))
    d.polygon([(cx + r * 0.05, cy - r * 0.1), (cx + r * 0.6, cy - r * 0.55), (cx + r * 0.35, cy + r * 0.1)], fill=(190, 230, 250, 150))
    d.ellipse([cx - r * 0.6, cy - r * 0.7, cx - r * 0.15, cy - r * 0.35], fill=(255, 255, 255, 170))   # the shine
    img.alpha_composite(layer)
    sh = Image.new('RGBA', img.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse([cx - r * 0.8, cy + r * 1.6, cx + r * 0.8, cy + r * 1.9], fill=(0, 0, 0, 90))
    img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(3)))


def feather(d, cx, cy, ln, ang):
    """a black feather-shaped flyer, edged in rainbow light"""
    a = math.radians(ang)
    ux, uy = math.cos(a), math.sin(a)
    px, py = -uy, ux
    tip, tail = (cx + ux * ln, cy + uy * ln), (cx - ux * ln, cy - uy * ln)
    left, right = (cx + px * ln * 0.28, cy + py * ln * 0.28), (cx - px * ln * 0.28, cy - py * ln * 0.28)
    d.polygon([tip, left, tail, right], fill=(18, 18, 30, 255))
    for k, col in enumerate([(255, 63, 90), (232, 196, 110), (91, 200, 91), (95, 216, 240), (154, 120, 255)]):
        t = 0.15 + k * 0.15
        d.line([(left[0] + (tip[0] - left[0]) * t, left[1] + (tip[1] - left[1]) * t),
                (left[0] + (tip[0] - left[0]) * (t + 0.15), left[1] + (tip[1] - left[1]) * (t + 0.15))], fill=col + (255,), width=2)
    d.line([tail, tip], fill=(60, 64, 90, 255), width=1)


def prism(img, cx, base, hgt, wid):
    """a violet crystal pillar with something faint caught inside"""
    layer = Image.new('RGBA', img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    top = base - hgt
    body = [(cx - wid, top + wid), (cx, top), (cx + wid, top + wid), (cx + wid, base - wid * 0.6), (cx, base), (cx - wid, base - wid * 0.6)]
    d.polygon(body, fill=(186, 160, 236, 170), outline=(236, 226, 255, 230))
    d.polygon([(cx - wid, top + wid), (cx, top), (cx, base), (cx - wid, base - wid * 0.6)], fill=(214, 196, 250, 120))
    d.line([(cx, top), (cx, base)], fill=(250, 246, 255, 200), width=1)
    d.ellipse([cx - wid * 0.4, top + hgt * 0.4, cx + wid * 0.5, top + hgt * 0.62], fill=(255, 220, 246, 110))
    glow = layer.filter(ImageFilter.GaussianBlur(8))
    img.alpha_composite(glow)
    img.alpha_composite(layer)


def hud(img):
    """the game-style HUD over the scene: day counter, planet panel, minimap, name plates"""
    d = ImageDraw.Draw(img)
    w, h = img.size
    big, small, jp, jps = font(SANS, 20), font(SANS, 10), font(JP, 16), font(JP, 12)

    # top right: the day counter with its 0-40 scale, and a song title between notes
    x0, y0 = w - 300, 34
    d.text((x0 + 10, y0), '01', font=big, fill=(238, 244, 251, 255))
    d.text((x0 + 40, y0 + 6), 'days in the garden', font=small, fill=(238, 244, 251, 255))
    chamfer(d, (x0, y0 + 30, x0 + 270, y0 + 58), 8, (10, 14, 28, 235), (90, 120, 170, 255))
    for i, v in enumerate((0, 10, 20, 30, 40)):
        xx = x0 + 18 + i * 58
        d.text((xx, y0 + 32), str(v), font=small, fill=(220, 230, 245, 255), anchor='ma')
    d.rectangle([x0 + 18, y0 + 46, x0 + 18 + 232, y0 + 49], fill=(60, 80, 120, 255))
    d.rectangle([x0 + 18, y0 + 46, x0 + 18 + 70, y0 + 49], fill=(224, 70, 70, 255))
    d.rectangle([x0 + 18, y0 + 51, x0 + 18 + 232, y0 + 53], fill=(40, 60, 90, 255))
    d.rectangle([x0 + 18, y0 + 51, x0 + 18 + 150, y0 + 53], fill=(91, 200, 91, 255))
    d.text((x0 + 20, y0 + 62), '♪', font=jps, fill=(238, 244, 251, 255))
    d.text((x0 + 135, y0 + 60), 'イスクラ', font=jp, fill=(238, 244, 251, 255), anchor='ma')
    d.text((x0 + 250, y0 + 62), '♪', font=jps, fill=(238, 244, 251, 255))

    # bottom left: the planet panel
    px, py = 40, h - 150
    d.polygon([(px, py), (px + 150, py), (px + 140, py + 18), (px, py + 18)], fill=(10, 14, 28, 240), outline=(120, 150, 200, 255))
    d.text((px + 8, py + 3), 'PLANET', font=small, fill=(238, 244, 251, 255))
    d.rectangle([px + 70, py + 6, px + 96, py + 11], fill=(224, 70, 70, 255))
    chamfer(d, (px, py + 22, px + 250, py + 112), 14, (12, 20, 44, 230), (120, 150, 200, 255), 2)
    d.text((px + 14, py + 26), 'AVALON', font=font(SANS, 14), fill=(238, 244, 251, 255))
    for k in range(6):
        d.line([(px + 12, py + 50 + k * 9), (px + 128, py + 50 + k * 9)], fill=(40, 60, 100, 255))
    d.ellipse([px + 40, py + 48, px + 98, py + 106], fill=(52, 120, 230, 255))
    d.ellipse([px + 48, py + 54, px + 74, py + 74], fill=(110, 170, 250, 255))
    d.arc([px + 20, py + 66, px + 118, py + 90], 160, 380, fill=(120, 220, 110, 255), width=4)
    for i, col in enumerate(ELEMENTS):
        d.rectangle([px + 160, py + 44 + i * 14, px + 222, py + 49 + i * 14], fill=col + (255,))

    # bottom right: the hexagonal minimap, the garden as seen from above
    mx, my, mw, mh = w - 320, h - 112, 280, 92
    hexa = [(mx + 24, my), (mx + mw - 24, my), (mx + mw, my + mh / 2), (mx + mw - 24, my + mh), (mx + 24, my + mh), (mx, my + mh / 2)]
    d.polygon(hexa, fill=(10, 18, 24, 215), outline=(70, 110, 90, 255))
    for _ in range(18):
        sx, sy, ss = rng.uniform(mx + 40, mx + mw - 60), rng.uniform(my + 12, my + mh - 30), rng.choice((8, 10, 14, 18))
        d.rectangle([sx, sy, sx + ss, sy + ss], outline=(98, 214, 110, 255), width=1)
    for col in ((70, 110, 255), (70, 110, 255), (70, 110, 255), (240, 80, 80), (240, 80, 80)):
        sx, sy = rng.uniform(mx + 50, mx + mw - 50), rng.uniform(my + 15, my + mh - 15)
        d.rectangle([sx, sy, sx + 4, sy + 4], fill=col + (255,))
    d.rectangle([mx + mw * 0.55, my + 6, mx + mw * 0.55 + 2, my + mh - 6], fill=(255, 40, 160, 255))


def texture(h, w, base, spread, seed, grain=1.2, levels=5):
    """a bitmap-like texture: clustered noise in a few tones of one colour, as the console's
    textured billboards and ground were"""
    g = np.random.default_rng(seed)
    n = g.random((h, w)).astype(np.float32)
    n = np.asarray(Image.fromarray((n * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(grain))).astype(np.float32) / 255
    n = (n - n.min()) / max(1e-6, n.max() - n.min())
    q = np.floor(n * levels) / (levels - 1)
    a = np.zeros((h, w, 3), np.float32)
    for i in range(3):
        a[:, :, i] = base[i] * (1 - spread / 2 + spread * q)
    return np.clip(a, 0, 255).astype(np.uint8)


def pine_mask(d, x, base, h):
    """a conifer silhouette, ragged at every tier, into a mask"""
    tiers = int(6 + h / 18)
    d.line([(x, base), (x, base - h * 0.95)], fill=255, width=max(1, int(h / 45)))
    for t in range(tiers):
        f = t / tiers
        ty = base - h + h * f * 0.94
        hw = h * (0.05 + 0.2 * f) * rng.uniform(0.75, 1.2)
        drop = h * 0.13
        pts = [(x, ty)]
        for k in range(6):   # a ragged lower edge to each tier
            fx = -1 + k / 2.5
            pts.append((x + hw * fx, ty + drop * (0.7 + 0.4 * rng.random())))
        d.polygon(pts, fill=255)


def wallpaper(pasha):
    # painted near the console's own resolution, scaled up four times with hard pixels
    w, h = 720, 480
    mist = (176, 174, 196)
    sky = gradient(w, h, [(0, (104, 102, 140)), (0.25, (138, 136, 168)), (0.5, mist), (1, mist)])
    img = Image.fromarray(sky.astype(np.uint8)).convert('RGBA')

    # cloud: soft streaks
    clouds = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    cd = ImageDraw.Draw(clouds)
    for _ in range(16):
        x, y = rng.uniform(-60, w), rng.uniform(20, 150)
        cd.ellipse([x, y, x + rng.uniform(120, 260), y + rng.uniform(10, 24)], fill=(190, 188, 210, 80))
    img.alpha_composite(clouds.filter(ImageFilter.GaussianBlur(8)))

    # distant hills
    d = ImageDraw.Draw(img)
    ridge = [(x, 196 - 22 * math.sin(x / 60) - 10 * math.sin(x / 19 + 1)) for x in range(0, w + 6, 6)]
    d.polygon([(0, 300)] + ridge + [(w, 300)], fill=(132, 132, 156, 255))
    img.alpha_composite(fog_band(w, h, 170, 260, mist, 0.65))

    # forest rows: silhouettes filled with clustered foliage texture, fog thickening behind
    rows = [(246, 50, (112, 124, 128), 12), (262, 84, (82, 100, 92), 16),
            (278, 124, (52, 76, 60), 22), (292, 170, (32, 52, 38), 32)]
    for i, (hz, ht, col, dens) in enumerate(rows):
        mask = Image.new('L', (w, h), 0)
        md = ImageDraw.Draw(mask)
        x = -10
        while x < w + 10:
            x += dens * rng.uniform(0.35, 1.0)
            pine_mask(md, x, hz + rng.uniform(-3, 4), ht * rng.uniform(0.65, 1.3))
        md.rectangle([0, hz, w, h], fill=255)
        tex = Image.fromarray(texture(h, w, col, 0.55, 10 + i, grain=0.9 + i * 0.25)).convert('RGBA')
        img.paste(tex, (0, 0), mask)
        img.alpha_composite(fog_band(w, h, hz - ht * 0.6, hz + 3, mist, 0.5 - i * 0.1))

    # light falling through
    lay = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    ld = ImageDraw.Draw(lay)
    for x0, wd in ((120, 50), (250, 30), (460, 70), (560, 36)):
        ld.polygon([(x0, 0), (x0 + wd, 0), (x0 + wd * 2.2 - 90, 320), (x0 + wd - 120, 320)], fill=(230, 230, 246, 34))
    img.alpha_composite(lay.filter(ImageFilter.GaussianBlur(10)))

    # the meadow: a grass texture, lighter and finer far off, coarser and darker near
    top, edge = 292, 404
    far = texture(edge - top, w, (86, 120, 70), 0.5, 21, grain=0.7, levels=6).astype(np.float32)
    shade = np.linspace(1.12, 0.62, edge - top)[:, None, None]
    meadow = np.clip(far * shade, 0, 255).astype(np.uint8)
    img.paste(Image.fromarray(meadow).convert('RGBA'), (0, top))
    d = ImageDraw.Draw(img)
    d.line([(0, top), (w, top)], fill=(128, 156, 104, 255), width=1)
    for _ in range(900):
        x, y = rng.uniform(0, w), rng.uniform(top + 3, edge)
        sh = (y - top) / (edge - top)
        g = lerp((118, 150, 96), (30, 56, 30), sh)
        d.line([(x, y), (x + rng.uniform(-1.5, 1.5), y - 1 - 6 * sh)], fill=g + (255,), width=1)

    # the pond, holding the grey sky
    pond = Image.new('L', (w, h), 0)
    ImageDraw.Draw(pond).ellipse([430, 318, 676, 352], fill=255)
    water = Image.fromarray(texture(h, w, (150, 150, 178), 0.18, 33, grain=2.5, levels=4)).convert('RGBA')
    img.paste(water, (0, 0), pond)
    d.arc([430, 318, 676, 352], 180, 360, fill=(196, 198, 214, 255), width=1)

    # the cut-away edge of the plateau: grass lip, then layered earth
    lip = [(x, edge + 4 * math.sin(x / 23) + rng.uniform(-2, 2)) for x in range(0, w + 4, 4)]
    earth = Image.new('L', (w, h), 0)
    ImageDraw.Draw(earth).polygon(lip + [(w, h), (0, h)], fill=255)
    soil = texture(h, w, (40, 30, 30), 0.6, 44, grain=1.5, levels=5).astype(np.float32)
    soil *= np.linspace(1.0, 0.55, h)[:, None, None]
    img.paste(Image.fromarray(np.clip(soil, 0, 255).astype(np.uint8)).convert('RGBA'), (0, 0), earth)
    d = ImageDraw.Draw(img)
    for x, y in lip[::2]:
        d.line([(x, y - 1), (x + rng.uniform(-1.5, 1.5), y + rng.uniform(3, 9))], fill=(48, 84, 42, 255), width=1)
    d.line(lip, fill=(76, 112, 58, 255), width=2)

    # the garden's odd life
    plant(d, 110, 360, 'frond', 0.6)
    plant(d, 640, 392, 'frond', 0.7)
    plant(d, 386, 384, 'bulb', 0.55)
    plant(d, 40, 330, 'frond', 0.4)
    prism(img, 250, 376, 92, 17)
    bubble(img, 318, 340, 16)
    bubble(img, 356, 362, 11)
    crystal(img, 176, 214, 12)
    crystal(img, 578, 238, 9)
    d = ImageDraw.Draw(img)
    feather(d, 90, 86, 20, 70)
    feather(d, 158, 66, 14, 55)
    feather(d, 650, 124, 15, 110)
    d.line([(112, 470), (176, 214)], fill=(220, 36, 36, 255), width=1)

    # the pixies' sparks
    glow = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for c in [(95, 216, 240), (255, 63, 164), (232, 196, 110), (120, 220, 120)] * 3:
        x, y, r = rng.uniform(60, w - 60), rng.uniform(160, 350), rng.uniform(1.5, 2.5)
        gd.ellipse([x - r * 3, y - r * 3, x + r * 3, y + r * 3], fill=c + (60,))
        gd.ellipse([x - r, y - r, x + r, y + r], fill=c + (255,))
    img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(0.8)))

    # Pasha as a sprite: small, a muted palette of a few colours, on his rock by the pond
    d = ImageDraw.Draw(img)
    rock = [(410, 384), (428, 366), (466, 360), (500, 368), (512, 386), (498, 394), (424, 396)]
    d.polygon(rock, fill=(84, 86, 98, 255))
    d.polygon([(428, 366), (466, 360), (500, 368), (470, 372), (436, 374)], fill=(124, 126, 142, 255))
    sprite = pasha.resize((92, 92), Image.LANCZOS)
    rgb = sprite.convert('RGB').quantize(colors=10, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert('RGB')
    rgb = Image.fromarray((np.asarray(rgb).astype(np.float32) * np.array([0.86, 0.88, 0.96])).astype(np.uint8))
    a = sprite.split()[3].point(lambda v: 255 if v > 110 else 0)
    sprite = rgb.convert('RGBA'); sprite.putalpha(a)
    halo = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    halo.paste(Image.new('RGBA', sprite.size, (110, 220, 250, 150)), (412, 280), a.filter(ImageFilter.MaxFilter(5)))
    img.alpha_composite(halo.filter(ImageFilter.GaussianBlur(3)))
    img.alpha_composite(sprite, (412, 280))

    # vignette, then the console's colour depth and dithering
    yy, xx = np.mgrid[0:h, 0:w]
    v = 1 - 0.42 * np.clip(((xx - w / 2) / (w * 0.62)) ** 2 + ((yy - h * 0.45) / (h * 0.7)) ** 2, 0, 1)
    rgb = np.asarray(img.convert('RGB')).astype(np.float32) * v[:, :, None]
    img = bayer_dither(Image.fromarray(rgb.astype(np.uint8)), levels=32)
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
