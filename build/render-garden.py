#!/usr/bin/env python3
"""render-garden.py: Avalon's wallpaper, rendered as a small 3D scene the way a 1999 console
would have drawn it. Original scene, in the spirit of late-1990s PlayStation garden games:

  - a meadow plateau with a pond, its cut-away earth face towards the camera
  - forest walls of camera-facing billboard pines, distant hills
  - low-poly flat-shaded objects: a rock with Pasha on it, a crystal prism, floating beacons
  - perspective-correct ground with unfiltered (nearest) textures, distance fog,
    480x320, 15-bit colour with ordered dithering, scaled up 6x with hard pixels

    python3 build/render-garden.py        writes desktop/usr/share/avalon/garden-wallpaper.png
"""
import math
import random
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = Path(__file__).resolve().parent.parent
OUT = HERE / 'desktop/usr/share/avalon/garden-wallpaper.png'
PASHA = HERE / 'branding/pasha.png'
RW, RH = 480, 320          # the render
SCALE = 6                  # 2880x1920
rng = random.Random(1999)
nrng = np.random.default_rng(1999)

MIST = np.array([168, 166, 190], np.float32)
FOG_NEAR, FOG_FAR = 6.0, 78.0


# ---------------------------------------------------------------- camera
CAM = np.array([0.0, 2.0, 0.0])
PITCH = math.radians(-11)          # looking down a little
FOV = math.radians(62)
F = (RW / 2) / math.tan(FOV / 2)
CX, CY = RW / 2, RH / 2
# camera -> world: a rotation about x by PITCH (forward (0,0,1) goes to (0, sin P, cos P))
_c, _s = math.cos(PITCH), math.sin(PITCH)
R = np.array([[1, 0, 0], [0, _c, _s], [0, -_s, _c]], np.float64)
RT = R.T                           # world -> camera


def project(p):
    """world (x, y, z) -> screen (sx, sy, depth along the view)"""
    cx, cy, cz = RT @ (np.asarray(p, np.float64) - CAM)
    if cz <= 0.05:
        return None
    return (CX + F * cx / cz, CY - F * cy / cz, cz)


def fog_amount(depth):
    return float(np.clip((depth - FOG_NEAR) / (FOG_FAR - FOG_NEAR), 0, 1)) ** 0.9


def fogged(colour, depth):
    a = fog_amount(depth)
    return tuple(int(colour[i] * (1 - a) + MIST[i] * a) for i in range(3))


# --------------------------------------------------------------- textures
def tex(size, base, spread, seed, grain=1.0, levels=5):
    g = np.random.default_rng(seed)
    n = g.random((size, size)).astype(np.float32)
    im = Image.fromarray((n * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(grain))
    n = np.asarray(im).astype(np.float32) / 255
    n = (n - n.min()) / max(1e-6, n.max() - n.min())
    q = np.floor(n * levels) / (levels - 1)
    t = np.zeros((size, size, 3), np.float32)
    for i in range(3):
        t[:, :, i] = base[i] * (1 - spread / 2 + spread * q)
    return np.clip(t, 0, 255)


GRASS = tex(64, (84, 120, 66), 0.55, 1, grain=0.8, levels=6)
WATER = tex(32, (150, 152, 184), 0.18, 2, grain=1.6, levels=4)
SOIL = tex(64, (58, 44, 40), 0.7, 3, grain=1.2, levels=5)


# ------------------------------------------------------- ground and sky (per pixel)
def ground_and_sky():
    ys, xs = np.mgrid[0:RH, 0:RW].astype(np.float32)
    # camera-space ray directions
    dx = (xs - CX) / F
    dy = -(ys - CY) / F
    dz = np.ones_like(dx)
    wx = R[0, 0] * dx + R[0, 1] * dy + R[0, 2] * dz
    wy = R[1, 0] * dx + R[1, 1] * dy + R[1, 2] * dz
    wz = R[2, 0] * dx + R[2, 1] * dy + R[2, 2] * dz

    img = np.zeros((RH, RW, 3), np.float32)
    depth = np.full((RH, RW), 1e9, np.float32)

    # sky: violet-grey above, mist towards the horizon
    elev = np.clip(wy / np.sqrt(wx * wx + wy * wy + wz * wz), -1, 1)
    t = np.clip(elev / 0.45, 0, 1)[:, :, None]
    sky_top, sky_low = np.array([96, 94, 132], np.float32), MIST + np.array([6, 6, 10], np.float32)
    img[:] = sky_low * (1 - t) + sky_top * t

    # the plateau: ground plane y = 0, from the cut-away edge at z = EDGE onwards
    EDGE = 5.0
    with np.errstate(divide='ignore', invalid='ignore'):
        tg = np.where(wy < -1e-4, -CAM[1] / wy, np.inf)
    with np.errstate(invalid='ignore'):
        gx, gz = CAM[0] + wx * tg, CAM[2] + wz * tg
    gx = np.nan_to_num(gx, nan=0, posinf=0, neginf=0); gz = np.nan_to_num(gz, nan=0, posinf=0, neginf=0)
    on_ground = np.isfinite(tg) & (gz >= EDGE)
    # grass: nearest-sampled, tiled every 2 m; a little brighter further off (the mist's light)
    u = np.floor(gx * 32).astype(int) % 64
    v = np.floor(gz * 32).astype(int) % 64
    grass = GRASS[v, u]
    shade = np.clip(1.15 - 0.012 * gz, 0.75, 1.15)[:, :, None]
    # large soft patches of light and shadow across the meadow
    patch = (np.sin(gx * 0.31 + 1.3) * np.sin(gz * 0.23) * 0.12 + 1)[:, :, None]
    gcol = grass * shade * patch
    # the pond: an ellipse holding the sky
    pond = ((gx - 3.6) / 3.8) ** 2 + ((gz - 13.0) / 1.7) ** 2 < 1
    wu = np.floor(gx * 12).astype(int) % 32
    wv = np.floor(gz * 24).astype(int) % 32
    water = WATER[wv, wu] * 0.6 + (MIST * 0.4)
    rim = (((gx - 3.6) / 4.0) ** 2 + ((gz - 13.0) / 1.85) ** 2 < 1) & ~pond
    gcol = np.where(pond[:, :, None], water, gcol)
    gcol = np.where(rim[:, :, None], np.array([150, 160, 130], np.float32), gcol)
    img = np.where(on_ground[:, :, None], gcol, img)
    depth = np.where(on_ground, tg, depth)

    # the cut-away face: a vertical wall at z = EDGE, down to y = -6
    with np.errstate(divide='ignore', invalid='ignore'):
        tw = np.where(wz > 1e-4, (EDGE - CAM[2]) / wz, np.inf)
    with np.errstate(invalid='ignore'):
        wyy = np.nan_to_num(CAM[1] + wy * tw, nan=99, posinf=99, neginf=99)
        wxx = np.nan_to_num(CAM[0] + wx * tw, nan=0, posinf=0, neginf=0)
    on_wall = np.isfinite(tw) & (wyy <= 0) & (wyy >= -6) & ~on_ground
    su = np.floor(wxx * 24).astype(int) % 64
    sv = np.floor(-wyy * 24).astype(int) % 64
    soil = SOIL[sv, su] * np.clip(1 + wyy * 0.09, 0.4, 1)[:, :, None]
    # a lip of grass hanging over the top of the face
    # a ragged lip of grass hanging over the top of the face, with roots below it
    lip = wyy > -0.10 - 0.18 * np.abs(np.sin(wxx * 7.3) * np.sin(wxx * 3.1 + 1))
    lipcol = GRASS[sv % 64, su % 64] * 0.7
    soil = np.where(lip[:, :, None], lipcol, soil)
    img = np.where(on_wall[:, :, None], soil, img)
    depth = np.where(on_wall, tw, depth)
    below = ~on_ground & ~on_wall & (wy < 0)
    img = np.where(below[:, :, None], np.array([20, 16, 18], np.float32), img)

    # fog by depth over everything with a depth
    a = np.clip((depth - FOG_NEAR) / (FOG_FAR - FOG_NEAR), 0, 1) ** 0.9
    a = np.where(depth > 1e8, 0, a)[:, :, None]
    img = img * (1 - a) + MIST * a
    return img, depth


# ------------------------------------------------------------- billboards
def pine_sprite(h_px, seed, base):
    """a pine as a texture: ragged tiers filled with clustered needles; RGBA"""
    w_px = int(h_px * 0.55) + 2
    r = random.Random(seed)
    mask = Image.new('L', (w_px, h_px), 0)
    d = ImageDraw.Draw(mask)
    cx = w_px / 2
    d.line([(cx, h_px), (cx, h_px * 0.05)], fill=255, width=max(1, h_px // 40))
    tiers = 6 + h_px // 18
    for t in range(tiers):
        f = t / tiers
        ty = h_px * 0.02 + h_px * f * 0.9
        hw = w_px * (0.08 + 0.42 * f) * r.uniform(0.8, 1.1)
        drop = h_px * 0.13
        pts = [(cx, ty)] + [(cx + hw * (-1 + k / 2.5), ty + drop * (0.7 + 0.4 * r.random())) for k in range(6)]
        d.polygon(pts, fill=255)
    t = tex(max(w_px, h_px), base, 0.6, seed, grain=0.7, levels=5)[:h_px, :w_px]
    # light from the left: the left half a shade brighter
    t[:, : w_px // 2] *= 1.12
    rgba = np.dstack([np.clip(t, 0, 255).astype(np.uint8), np.asarray(mask)])
    return Image.fromarray(rgba, 'RGBA')


def draw_billboard(img, depthbuf, sprite, world_base, height_m):
    """a sprite standing at world_base, height_m tall, depth-tested per pixel, fogged"""
    p = project(world_base)
    if not p:
        return
    sx, sy, z = p
    hp = int(F * height_m / z)
    if hp < 2:
        return
    wp = max(1, int(hp * sprite.width / sprite.height))
    spr = sprite.resize((wp, hp), Image.NEAREST)
    a = np.asarray(spr).astype(np.float32)
    col = a[:, :, :3]
    fa = fog_amount(z)
    col = col * (1 - fa) + MIST * fa
    x0, y0 = int(sx - wp / 2), int(sy - hp)
    xa, ya = max(0, x0), max(0, y0)
    xb, yb = min(RW, x0 + wp), min(RH, y0 + hp)
    if xa >= xb or ya >= yb:
        return
    sub_a = a[ya - y0:yb - y0, xa - x0:xb - x0, 3] > 128
    sub_c = col[ya - y0:yb - y0, xa - x0:xb - x0]
    nearer = depthbuf[ya:yb, xa:xb] > z
    m = sub_a & nearer
    img[ya:yb, xa:xb][m] = sub_c[m]
    depthbuf[ya:yb, xa:xb][m] = z


# ------------------------------------------------------- low-poly objects
def draw_mesh(img, depthbuf, verts, faces, colour, light=(-0.6, 0.7, -0.4), alpha=1.0, edges=None, cull=True):
    """flat-shaded polygons, painter-sorted, fogged; optional glowing edge colour"""
    L = np.array(light) / np.linalg.norm(light)
    pv = [project(v) for v in verts]
    order = []
    for f in faces:
        if any(pv[i] is None for i in f):
            continue
        a, b, c = (np.array(verts[i]) for i in f[:3])
        n = np.cross(b - a, c - a)
        nn = np.linalg.norm(n)
        if nn == 0:
            continue
        n /= nn
        centre = np.mean([verts[i] for i in f], axis=0)
        to_cam = CAM - centre
        if np.dot(n, to_cam) <= 0:      # facing away
            if cull:
                continue
            n = -n
        z = np.mean([pv[i][2] for i in f])
        lum = 0.45 + 0.55 * max(0, float(np.dot(n, L)))
        order.append((z, f, lum))
    order.sort(key=lambda o: -o[0])
    layer = Image.new('RGBA', (RW, RH), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    zmin = 1e9
    for z, f, lum in order:
        c = fogged(tuple(min(255, int(ch * lum)) for ch in colour), z)
        pts = [(round(pv[i][0]), round(pv[i][1])) for i in f]   # snapped to whole pixels, as the console did
        d.polygon(pts, fill=c + (int(255 * alpha),))
        if edges:
            d.line(pts + [pts[0]], fill=edges + (255,), width=1)
        zmin = min(zmin, z)
    arr = np.asarray(layer).astype(np.float32)
    m = (arr[:, :, 3] > 0) & (depthbuf > zmin)
    a = (arr[:, :, 3:4] / 255)
    img[m] = (img * (1 - a) + arr[:, :, :3] * a)[m]
    depthbuf[m] = np.minimum(depthbuf[m], zmin)


def octahedron(c, r, h):
    x, y, z = c
    v = [(x, y + h, z), (x + r, y, z), (x, y, z + r), (x - r, y, z), (x, y, z - r), (x, y - h, z)]
    f = [(0, 2, 1), (0, 3, 2), (0, 4, 3), (0, 1, 4), (5, 1, 2), (5, 2, 3), (5, 3, 4), (5, 4, 1)]
    return v, f


def prism(c, r, h, sides=6):
    x, y, z = c
    v = []
    for k in range(sides):
        a = 2 * math.pi * k / sides
        v.append((x + r * math.cos(a), y, z + r * math.sin(a)))
    for k in range(sides):
        a = 2 * math.pi * k / sides
        v.append((x + r * math.cos(a), y + h, z + r * math.sin(a)))
    v.append((x, y + h + r * 1.1, z))
    f = [(k, (k + 1) % sides, sides + (k + 1) % sides, sides + k) for k in range(sides)]
    f += [(sides + k, sides + (k + 1) % sides, 2 * sides) for k in range(sides)]
    return v, f


def rock(c, s):
    x, y, z = c
    v = [(x - 1.0 * s, y, z - 0.7 * s), (x + 1.1 * s, y, z - 0.6 * s), (x + 1.2 * s, y, z + 0.8 * s), (x - 0.9 * s, y, z + 0.7 * s),
         (x - 0.6 * s, y + 0.55 * s, z - 0.3 * s), (x + 0.7 * s, y + 0.6 * s, z - 0.2 * s), (x + 0.6 * s, y + 0.5 * s, z + 0.5 * s), (x - 0.5 * s, y + 0.45 * s, z + 0.4 * s)]
    f = [(0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7), (4, 5, 6, 7)]
    return v, f


def sprite_pasha():
    p = Image.open(PASHA).convert('RGBA')
    bbox = p.getbbox()
    p = p.crop(bbox)
    small = p.resize((int(p.width * 96 / p.height), 96), Image.LANCZOS)
    rgb = small.convert('RGB').quantize(colors=12, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert('RGB')
    rgb = Image.fromarray((np.asarray(rgb).astype(np.float32) * np.array([0.86, 0.88, 0.97])).astype(np.uint8))
    a = small.split()[3].point(lambda v: 255 if v > 110 else 0)
    out = rgb.convert('RGBA')
    out.putalpha(a)
    return out


def frond_sprite():
    s = Image.new('RGBA', (40, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(s)
    d.line([(20, 48), (20, 16)], fill=(196, 188, 170, 255), width=2)
    for k in range(12):
        a = math.radians(-180 + k * 15)
        d.line([(20, 16), (20 + math.cos(a) * 18, 16 + math.sin(a) * 9)], fill=(150, 34, 32, 255), width=2)
        d.line([(20, 16), (20 + math.cos(a) * 12, 14 + math.sin(a) * 6)], fill=(200, 64, 48, 255), width=1)
    return s


def bubble_sprite():
    s = Image.new('RGBA', (40, 40), (0, 0, 0, 0))
    d = ImageDraw.Draw(s)
    d.ellipse([1, 1, 38, 38], fill=(178, 204, 240, 150), outline=(226, 238, 255, 255))
    d.ellipse([10, 9, 22, 21], fill=(238, 234, 250, 255))
    d.ellipse([13, 16, 30, 32], fill=(210, 202, 236, 255))
    d.polygon([(21, 18), (34, 8), (28, 24)], fill=(190, 230, 250, 255))
    d.ellipse([6, 5, 14, 11], fill=(255, 255, 255, 255))
    return s


# ----------------------------------------------------------------- scene
def render():
    img, depth = ground_and_sky()

    # distant hills: a band of billboards far off, nearly lost in the mist
    hill = Image.new('RGBA', (400, 60), (0, 0, 0, 0))
    hd = ImageDraw.Draw(hill)
    hd.polygon([(0, 60)] + [(x, 30 - 14 * math.sin(x / 40) - 8 * math.sin(x / 13)) for x in range(0, 404, 4)] + [(400, 60)], fill=(120, 120, 150, 255))
    for x in (-160, 0, 160):
        draw_billboard(img, depth, hill, (x, 0, 140), 26)

    # forest walls: rows of pines, the furthest first; a gap to the right where the meadow opens
    pines = [pine_sprite(160, s, (r, g, b)) for s, (r, g, b) in enumerate([(40, 62, 46), (48, 72, 52), (34, 56, 40), (56, 80, 58)])]
    trees = []
    for row, (zmin, zmax, count) in enumerate([(52, 62, 90), (40, 48, 70), (30, 35, 46)]):
        for _ in range(count):
            x = rng.uniform(-40, 40)
            z = rng.uniform(zmin, zmax)
            trees.append((z, x, rng.uniform(6.5, 10.5)))
    # a few nearer trees at the sides, framing the clearing
    for x, z, h in ((-10, 14, 9), (-13, 19, 10), (-8.5, 10, 7.5), (12, 17, 9.5), (14.5, 23, 10), (10, 12, 7.5)):
        trees.append((z, x, h))
    trees.sort(key=lambda t: -t[0])
    for z, x, h in trees:
        draw_billboard(img, depth, pines[rng.randrange(len(pines))], (x, 0, z), h)

    # light falling through the mist
    shafts = Image.new('RGBA', (RW, RH), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shafts)
    for x0, wd in ((70, 30), (150, 18), (300, 40), (370, 22)):
        sd.polygon([(x0, 0), (x0 + wd, 0), (x0 + wd * 2 - 60, RH * 0.6), (x0 + wd - 80, RH * 0.6)], fill=(232, 232, 248, 30))
    sh = np.asarray(shafts.filter(ImageFilter.GaussianBlur(6))).astype(np.float32)
    img = img * (1 - sh[:, :, 3:4] / 255) + sh[:, :, :3] * (sh[:, :, 3:4] / 255)

    # plants of the garden
    frond = frond_sprite()
    for x, z, h in ((-3.8, 7.2, 0.9), (6.4, 10.5, 1.0), (-5.6, 13, 1.1), (0.4, 16, 0.9)):
        draw_billboard(img, depth, frond, (x, 0, z), h)

    # the crystal prism, violet, on the meadow
    v, f = prism((-2.1, 0, 9.0), 0.36, 1.8)
    draw_mesh(img, depth, v, f, (176, 150, 232), alpha=0.82, edges=(236, 226, 255))

    # pixies asleep in bubbles
    bub = bubble_sprite()
    draw_billboard(img, depth, bub, (-0.5, 0.1, 8.0), 0.8)
    draw_billboard(img, depth, bub, (0.4, 0.0, 7.3), 0.5)

    # Pasha on his rock, beside the pond
    v, f = rock((1.9, 0, 8.6), 0.9)
    draw_mesh(img, depth, v, f, (150, 152, 168), cull=False)
    draw_billboard(img, depth, sprite_pasha(), (1.85, 0.40, 8.55), 1.55)

    # the beacons: dark octahedra with cyan edges, floating above the meadow
    for c, r in (((-3.8, 3.0, 11.5), 0.42), ((5.6, 2.8, 15.0), 0.38)):
        v, f = octahedron(c, r, r * 1.8)
        draw_mesh(img, depth, v, f, (26, 28, 44), edges=(140, 236, 255))
        p = project(c)
        if p:
            x, y, z = p
            d = ImageDraw.Draw(layer := Image.new('RGBA', (RW, RH), (0, 0, 0, 0)))
            s = F * r * 1.9 / z
            for sx in (-1, 1):
                d.line([(x + sx * s, y - s * 0.6), (x + sx * s * 1.3, y), (x + sx * s, y + s * 0.6)], fill=(95, 216, 240, 255))
            d.rectangle([x - 1, y - 1, x + 1, y + 1], fill=(255, 60, 80, 255))
            arr = np.asarray(layer).astype(np.float32)
            m = arr[:, :, 3] > 0
            img[m] = arr[:, :, :3][m]

    # sparks, and the red targeting line
    out = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8)).convert('RGBA')
    glow = Image.new('RGBA', (RW, RH), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for c in [(95, 216, 240), (255, 63, 164), (232, 196, 110), (120, 220, 120)] * 3:
        x, y = rng.uniform(40, RW - 40), rng.uniform(90, 210)
        gd.ellipse([x - 3, y - 3, x + 3, y + 3], fill=c + (70,))
        gd.rectangle([x - 1, y - 1, x, y], fill=c + (255,))
    out.alpha_composite(glow)
    b = project((-3.8, 3.0, 11.5))
    if b:
        ImageDraw.Draw(out).line([(60, RH), (b[0], b[1])], fill=(220, 36, 36, 255), width=1)

    # vignette, 15-bit colour, ordered dither, then the hard-pixel scale-up
    a = np.asarray(out.convert('RGB')).astype(np.float32)
    yy, xx = np.mgrid[0:RH, 0:RW]
    v = 1 - 0.38 * np.clip(((xx - RW / 2) / (RW * 0.62)) ** 2 + ((yy - RH * 0.45) / (RH * 0.72)) ** 2, 0, 1)
    a *= v[:, :, None]
    m = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]], np.float32) / 16 - 0.5
    tile = np.tile(m, (RH // 4 + 1, RW // 4 + 1))[:RH, :RW][:, :, None]
    step = 255 / 31
    a = np.clip(np.round(a / step + tile) * step, 0, 255).astype(np.uint8)
    return Image.fromarray(a).resize((RW * SCALE, RH * SCALE), Image.NEAREST)


if __name__ == '__main__':
    OUT.parent.mkdir(parents=True, exist_ok=True)
    render().save(OUT, optimize=True)
    print('written', OUT)
