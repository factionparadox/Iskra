"""Iskra's night sky: a Siberian aurora over mountains, taiga and a still lake, painted from
noise (no source image), at any size. Used by make-branding.py (wallpaper) and
make-grub-theme.py (boot screen).   sky(2880, 1920) -> PIL RGB image;  ground_y(w, h) -> y
"""
import numpy as np
from PIL import Image, ImageFilter


def _noise1d(n, scale, rnd, octaves=5):
    """Smooth 1-D fractal noise of length n, roughly in -1..1."""
    out = np.zeros(n)
    amp, total = 1.0, 0.0
    for o in range(octaves):
        k = max(2, int(n / scale * 2 ** o) + 2)
        pts = rnd.uniform(-1, 1, k)
        out += amp * np.interp(np.linspace(0, k - 1, n), np.arange(k), pts)
        total += amp
        amp *= 0.5
    return out / total


def _blur(a, r):
    img = Image.fromarray(np.clip(a * 255, 0, 255).astype('uint8'))
    return np.asarray(img.filter(ImageFilter.GaussianBlur(r))).astype(float) / 255


def horizon(h):
    return int(h * 0.74)


def ground_y(w, h):
    """Where the meadow is, for standing things on."""
    return int(h * 0.90)


def sky(w=2880, h=1920, seed=1999):
    rnd = np.random.default_rng(seed)
    hz = horizon(h)
    y = np.linspace(0, 1, h)[:, None]
    x = np.linspace(0, 1, w)[None, :]

    # the sky: deep night blue at the top, violet low down
    top, mid, low = np.array([6, 8, 24]), np.array([22, 18, 58]), np.array([70, 40, 110])
    t = np.clip(y / (hz / h), 0, 1)
    col = top * (1 - t) ** 2 + mid * 2 * t * (1 - t) + low * t ** 2
    img = np.broadcast_to(col[:, None, :] if col.ndim == 2 else col, (h, w, 3)).astype(float).copy()
    img = img.reshape(h, w, 3) if img.shape != (h, w, 3) else img

    # stars, a few bright ones with a soft glow
    stars = np.zeros((h, w))
    n = int(w * h / 1400)
    sx, sy = rnd.integers(0, w, n), rnd.integers(0, hz, n)
    stars[sy, sx] = rnd.uniform(0.25, 1.0, n) ** 2
    big = rnd.choice(n, n // 40, replace=False)
    glow = np.zeros((h, w)); glow[sy[big], sx[big]] = 1.0
    stars = np.clip(stars + _blur(glow, 3) * 6, 0, 1) * (1 - y * 0.6)
    img += stars[..., None] * np.array([235, 235, 255])

    # the aurora: a great curtain sweeping down from the top across to the right, a fainter one
    # low on the left; bright green at its lower edge, fading to violet at the top, in fine rays
    aur_g, aur_p = np.zeros((h, w)), np.zeros((h, w))
    xs = np.arange(w)
    rows = np.arange(h)[:, None]
    for (x0, y0, x1, y1, height, bright, sc) in ((0.18, -0.05, 1.05, 0.60, 0.42, 1.25, 1.0),
                                                 (-0.05, 0.50, 0.40, 0.36, 0.20, 0.55, 0.6)):
        u = np.clip((xs / w - x0) / (x1 - x0), 0, 1)
        edge = (y0 + (y1 - y0) * (u ** 0.8)) * h                # the lower edge, a falling diagonal
        edge += (0.035 * np.sin(u * 19 + sc) + 0.02 * _noise1d(w, w / 6, rnd)) * h   # folds
        inside = ((xs / w) > x0) & ((xs / w) < x1)
        taper = np.sin(np.clip(u, 0, 1) * np.pi) ** 0.5 * inside
        rays = np.clip(0.5 + 0.9 * _noise1d(w, w / 160, rnd, 3), 0, 1) ** 1.5
        rays = 0.35 + 0.65 * rays
        d = (edge[None, :] - rows) / (height * h)               # 0 at the edge, 1 at the top
        under = np.exp(-np.clip(-d, 0, None) * 30)
        curtain = np.where(d >= 0, np.exp(-d * 1.6), under) * (rays * taper * bright)[None, :]
        aur_g += curtain * np.exp(-np.clip(d, 0, None) * 2.6)
        aur_p += curtain * np.clip(d * 1.6, 0, 1) * np.exp(-np.clip(d - 0.5, 0, None) * 1.6)
    g = np.clip(aur_g, 0, 1.4)
    aur_g = _blur(g / 1.4, 1.5) * 1.4 * 0.9 + _blur(g / 1.4, 30) * 1.4 * 0.22
    aur_p = _blur(np.clip(aur_p, 0, 1), 3) * 0.75 + _blur(np.clip(aur_p, 0, 1), 60) * 0.3
    core = np.clip(aur_g - 0.75, 0, None)                         # the hottest edge goes pale
    sky_mask = (np.arange(h) < hz)[:, None]
    img += sky_mask[..., None] * (aur_g[..., None] * np.array([30, 235, 150])
                                  + core[..., None] * np.array([120, 160, 120])
                                  + aur_p[..., None] * np.array([150, 50, 210]))
    # a pink glow along the horizon
    img += sky_mask[..., None] * (np.exp(-((rows - hz) / (0.07 * h)) ** 2)[..., None]
                                  * np.array([60, 20, 60]))

    # the lake: the sky above, flipped, darker and rippled
    lake_top, lake_bot = hz, int(h * 0.84)
    rows = np.arange(lake_top, lake_bot)
    src = np.clip(hz - 1 - (rows - hz) * 3, 0, hz - 1)       # a long, foreshortened reflection
    ripple = (np.sin(rows[:, None] * 1.7 + _noise1d(w, w / 40, rnd)[None, :] * 6) * 3).astype(int)
    srcx = np.clip(xs[None, :] + ripple, 0, w - 1)
    img[lake_top:lake_bot] = img[src[:, None], srcx] * 0.7 + np.array([4, 12, 22])

    # mountains: a far range of sharp peaks, hazy violet, and a nearer, darker one
    def ridge(level, rough, sc):
        r = 1 - np.abs(_noise1d(w, w / sc, rnd, 6))            # ridged noise: sharp peaks
        return (level - rough * r ** 2.5) * h
    for level, rough, sc, c, a in ((0.735, 0.13, 2.2, (44, 34, 84), 0.80), (0.74, 0.07, 3.5, (18, 18, 38), 0.92)):
        r = ridge(level, rough, sc)
        m = (np.arange(h)[:, None] > r[None, :]) & (np.arange(h)[:, None] < hz + 4)
        img[m] = img[m] * (1 - a) + np.array(c) * a

    # the taiga: a band of spruce along the far shore and on the near bank
    def spruces(base_y, hmin, hmax, count, c):
        nonlocal img
        layer = np.zeros((h, w))
        for _ in range(count):
            cx = rnd.uniform(0, w); th = rnd.uniform(hmin, hmax) * h; tw = th * 0.28
            by = base_y + rnd.uniform(-0.004, 0.004) * h
            y0, y1 = int(by - th), int(by)
            if y1 <= 0: continue
            yy = np.arange(max(0, y0), min(h, y1 + 1))
            half = (yy - y0) / th * tw / 2
            for row, hw in zip(yy, half):
                layer[row, max(0, int(cx - hw)):min(w, int(cx + hw) + 1)] = 1
        layer = _blur(layer, 0.7)
        img = img * (1 - layer[..., None]) + np.array(c) * layer[..., None]
    spruces(hz + 2, 0.010, 0.030, 900, (8, 12, 18))

    # the near meadow: dark green, lit faintly by the aurora, rising gently to the left
    gy = ground_y(w, h)
    bank = (0.845 - 0.05 * (1 - x[0]) ** 2 + 0.006 * _noise1d(w, w / 8, rnd)) * h
    m = np.arange(h)[:, None] > bank[None, :]
    shade = np.clip((np.arange(h)[:, None] - bank[None, :]) / (h * 0.16), 0, 1)
    meadow = np.array([18, 52, 40]) * (1 - shade[..., None]) + np.array([5, 14, 12]) * shade[..., None]
    img[m] = meadow[m]

    # grass: fine blades, catching a little green light along the top of the bank
    blades = rnd.uniform(0, 1, (h, w)) ** 6
    blades = _blur(blades, 0.6)
    tex = np.asarray(Image.fromarray(np.clip(blades * 255, 0, 255).astype('uint8'))
                     .resize((w, h // 3)).resize((w, h))).astype(float) / 255
    rim = np.exp(-np.clip(np.arange(h)[:, None] - bank[None, :], 0, None) / (0.012 * h)) * m
    img += (m * tex * 40)[..., None] * np.array([0.3, 1.0, 0.6]) + rim[..., None] * np.array([10, 45, 30])

    # a soft vignette
    v = 1 - 0.35 * (((x - 0.5) * 1.6) ** 2 + ((y - 0.45) * 1.4) ** 2)
    img *= np.clip(v, 0.55, 1)[..., None]
    return Image.fromarray(np.clip(img, 0, 255).astype('uint8'), 'RGB')


if __name__ == '__main__':
    sky(1440, 960).save('/tmp/iskra-sky.png')
