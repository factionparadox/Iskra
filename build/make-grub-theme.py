#!/usr/bin/env python3
"""Make Avalon's GRUB theme (run after changing the design below):
  desktop/usr/share/avalon/grub-theme/   background.png, theme.txt, the menu's band pieces, fonts
The disc uses it for its own boot menu (build/make-iso); the installer copies it to
/boot/grub/themes/avalon.

The screen is laid out like Pixygarden's planet-select screen: Pasha stands in a blue spotlight
on the left, as the ship's AI does; in the middle, a framed window onto the garden (from the 3D
wallpaper) with its elements plate; top right, the PLANET panel; the ok / edit hex buttons; and
along the bottom the navy dialogue box, which holds the boot menu. The chosen entry is the
violet chevron bar from the game's Pixy list.
Everything but the menu and the countdown is painted into background.png. Drawn for the 13 Pro's
3:2 panel (2880 x 1920); GRUB crops it to other shapes.
Needs Pillow, NumPy and grub-mkfont:  python3 build/make-grub-theme.py
"""
import random
import subprocess
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'desktop/usr/share/avalon/grub-theme'
W, H = 2880, 1920
CYAN, MINT, WHITE = (95, 216, 240), (191, 227, 214), (238, 244, 251)
VIOLET, NAVY = (88, 86, 222), (24, 26, 104)
ELEMENTS = (('土', (201, 163, 90)), ('水', (74, 100, 200)), ('風', (91, 200, 91)), ('火', (224, 112, 90)))
SANS = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
BOLD = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
CJK = '/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc'

# the dialogue box (the menu lives in it): GRUB's boot_menu is placed over it in THEME below
BOX = (1000, 1200, 2760, 1700)


def font(path, size):
    return ImageFont.truetype(path, size)


def vgrad(w, h, top, bottom):
    t = np.linspace(0, 1, h)[:, None, None]
    a = np.array(top, np.float32)[None, None, :]
    b = np.array(bottom, np.float32)[None, None, :]
    return Image.fromarray(np.repeat((a + (b - a) * t).astype(np.uint8), w, axis=1))


def chamfer(d, box, cut, fill, outline=None, width=3):
    x0, y0, x1, y1 = box
    pts = [(x0 + cut, y0), (x1, y0), (x1, y1 - cut), (x1 - cut, y1), (x0, y1), (x0, y0 + cut)]
    d.polygon(pts, fill=fill)
    if outline:
        d.line(pts + [pts[0]], fill=outline, width=width)


def plate(d, x, y, w, h, text, f, fill=MINT, ink=(16, 22, 40)):
    """the game's slanted name plate: a pale bar with pointed ends"""
    k = h // 2
    d.polygon([(x + k, y), (x + w - k, y), (x + w, y + k), (x + w - k, y + h), (x + k, y + h), (x, y + k)], fill=fill)
    d.text((x + w // 2, y + h // 2), text, font=f, fill=ink, anchor='mm')


def hexbutton(img, x, y, label, mark):
    """the pale ok / cancel button with its hex badge: ○ orange ring or × blue"""
    d = ImageDraw.Draw(img)
    w, h = 400, 120
    d.polygon([(x + 50, y), (x + w - 50, y), (x + w, y + h // 2), (x + w - 50, y + h), (x + 50, y + h), (x, y + h // 2)],
              fill=(214, 226, 222))
    d.text((x + 170, y + h // 2), label, font=font(BOLD, 64), fill=(28, 34, 52), anchor='mm')
    cx, cy, r = x + w + 30, y + h // 2 + 30, 92
    hexpts = [(cx + r * np.cos(np.pi / 3 * i), cy + r * np.sin(np.pi / 3 * i)) for i in range(6)]
    d.polygon(hexpts, fill=(214, 226, 222))
    d.ellipse((cx - 62, cy - 62, cx + 62, cy + 62), fill=(36, 40, 58))
    if mark == 'o':
        d.ellipse((cx - 40, cy - 40, cx + 40, cy + 40), outline=(240, 96, 40), width=12)
    else:
        for s in (1, -1):
            d.line([(cx - 34, cy - 34 * s), (cx + 34, cy + 34 * s)], fill=(90, 150, 255), width=12)


def pasha_sprite(height):
    """Pasha as the 3D scene draws him: few colours, hard edges, PlayStation-sized then enlarged"""
    p = Image.open(ROOT / 'branding/pasha.png').convert('RGBA')
    p = p.crop(p.getbbox())
    small = p.resize((int(p.width * 150 / p.height), 150), Image.LANCZOS)
    rgb = small.convert('RGB').quantize(colors=14, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert('RGB')
    rgb = Image.fromarray((np.asarray(rgb).astype(np.float32) * np.array([0.88, 0.92, 1.0])).astype(np.uint8))
    a = small.split()[3].point(lambda v: 255 if v > 110 else 0)
    out = rgb.convert('RGBA')
    out.putalpha(a)
    k = height / out.height
    return out.resize((int(out.width * k), height), Image.NEAREST)


def background():
    img = vgrad(W, H, (8, 12, 40), (0, 0, 6)).convert('RGBA')
    rnd = random.Random(7)
    d = ImageDraw.Draw(img)
    for _ in range(260):   # a few faint stars
        x, y, v = rnd.randrange(W), rnd.randrange(H), rnd.randrange(50, 150)
        d.rectangle((x, y, x + 2, y + 2), fill=(v, v, v + 40))

    # the spotlight: a blue beam from above, a pool of light on the floor, Pasha in it
    beam = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    bd = ImageDraw.Draw(beam)
    for i in range(40):
        bd.rectangle((330 - i * 5, 0, 830 + i * 5, 1720), fill=(30, 70, 220, 5))
    bd.rectangle((350, 0, 810, 1720), fill=(50, 110, 240, 110))
    bd.rectangle((420, 0, 740, 1720), fill=(80, 150, 255, 50))
    img.alpha_composite(beam.filter(ImageFilter.GaussianBlur(30)))
    pool = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(pool).ellipse((240, 1600, 920, 1800), fill=(70, 200, 255, 230))
    img.alpha_composite(pool.filter(ImageFilter.GaussianBlur(26)))
    ImageDraw.Draw(img).ellipse((330, 1640, 830, 1760), fill=(150, 235, 255, 120))
    p = pasha_sprite(700)
    img.alpha_composite(p, (580 - p.width // 2, 1700 - p.height))
    d = ImageDraw.Draw(img)
    plate(d, 300, 150, 560, 96, 'パシャ  PASHA', font(CJK, 50))

    # the window onto the garden, with the blue wings at its sides
    wings = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    wd = ImageDraw.Draw(wings)
    for i in range(24):
        c = (70 + i * 3, 66 + i * 3, 170 + i * 3, 255)
        wd.ellipse((1110 + i * 4, 250 + i * 6, 1450 - i * 2, 860 - i * 6), fill=c)
        wd.ellipse((1950 + i * 2, 250 + i * 6, 2290 - i * 4, 860 - i * 6), fill=c)
    img.alpha_composite(wings)
    wall = Image.open(ROOT / 'desktop/usr/share/avalon/garden-wallpaper.png').convert('RGB')
    view = wall.crop((0, 120, 1500, 1050)).resize((900, 558), Image.NEAREST)
    d = ImageDraw.Draw(img)
    d.rectangle((1240, 170, 2160, 748), fill=(20, 22, 48))
    img.paste(view, (1250, 180))
    d.rectangle((1250, 180, 2150, 738), outline=(150, 156, 220), width=4)

    # its plate: the name, then the four elements (these numbers say CRUX 3.8, Linux 7.3)
    chamfer(d, (1380, 700, 2160, 1060), 40, (18, 64, 104, 240), (40, 120, 170), 4)
    d.text((1430, 720), 'Avalon  Garden', font=font(BOLD, 64), fill=WHITE)
    vals = (3, 8, 7, 3)
    for i, ((g, col), v) in enumerate(zip(ELEMENTS, vals)):
        x = 1430 + (i % 2) * 330
        y = 810 + (i // 2) * 68
        d.text((x, y), g, font=font(CJK, 54), fill=(200, 210, 230))
        d.text((x + 230, y + 4), str(v), font=font(BOLD, 56), fill=WHITE, anchor='ra')
    d.rectangle((1430, 960, 2110, 1040), fill=(4, 8, 18))
    for i, (_, col) in enumerate(ELEMENTS):
        d.rectangle((1820 - i * 40, 970 + i * 17, 1880 + i * 30, 980 + i * 17), fill=col)

    # the PLANET panel, top right: tab, name, the blue planet with its green ring, the bars
    chamfer(d, (2240, 270, 2780, 620), 60, (40, 30, 44, 235), (110, 80, 90), 4)
    d.polygon([(2240, 200), (2560, 200), (2600, 260), (2240, 260)], fill=(62, 46, 60))
    d.text((2270, 206), 'PLANET', font=font(BOLD, 48), fill=WHITE)
    tx = 2270 + d.textlength('PLANET', font=font(BOLD, 48)) + 20
    d.rectangle((tx, 218, tx + 60, 240), fill=(225, 40, 50))
    d.text((2320, 290), 'AVALON', font=font(BOLD, 60), fill=WHITE)
    planet = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    pd = ImageDraw.Draw(planet)
    pd.ellipse((2290, 380, 2490, 580), fill=(60, 110, 220, 255))
    pd.ellipse((2320, 400, 2430, 470), fill=(130, 180, 250, 200))
    img.alpha_composite(planet.filter(ImageFilter.GaussianBlur(2)))
    d = ImageDraw.Draw(img)
    d.arc((2250, 455, 2530, 515), 150, 390, fill=(91, 200, 91), width=9)
    d.rectangle((2530, 400, 2750, 470), fill=(4, 8, 18))
    for i, (_, col) in enumerate(ELEMENTS):
        d.rectangle((2650, 408 + i * 15, 2720, 416 + i * 15), fill=col)

    # ok / edit
    hexbutton(img, 2320, 720, 'ok', 'o')
    hexbutton(img, 2250, 900, 'edit', 'x')

    # the dialogue box, which GRUB fills with the menu
    box = vgrad(BOX[2] - BOX[0], BOX[3] - BOX[1], (34, 36, 130), (16, 18, 74)).convert('RGBA')
    box.putalpha(242)
    img.alpha_composite(box, BOX[:2])
    d = ImageDraw.Draw(img)
    d.rectangle(BOX, outline=(70, 74, 170), width=4)
    d.text((BOX[0] + 30, BOX[1] - 70), 'START', font=font(BOLD, 44), fill=CYAN)
    return img.convert('RGB')


def bands():
    """the chosen line: a violet bar ending in a point, as in the game's Pixy list"""
    h = 64
    Image.new('RGBA', (14, h), (150, 160, 255, 255)).save(OUT / 'select_w.png')
    Image.new('RGBA', (8, h), VIOLET + (255,)).save(OUT / 'select_c.png')
    tip = Image.new('RGBA', (40, h), (0, 0, 0, 0))
    ImageDraw.Draw(tip).polygon([(0, 0), (40, h // 2), (0, h)], fill=VIOLET + (255,))
    tip.save(OUT / 'select_e.png')


def fonts():
    ranges = '0x20-0x7e,0xa0-0x17f,0x400-0x4ff,0x2010-0x2027,0x2190-0x21ff'
    for path, size, name in ((BOLD, 52, 'menu'), (SANS, 34, 'hint')):
        subprocess.run(['grub-mkfont', '-s', str(size), '-r', ranges, '-o', str(OUT / f'{name}.pf2'), path],
                       check=True)


THEME = '''# Avalon's GRUB theme (made by build/make-grub-theme.py)
title-text: ""
desktop-image: "background.png"
desktop-image-scale-method: "crop"
desktop-color: "#000006"
terminal-font: "DejaVu Sans Regular 34"

+ boot_menu {
	left = 36.5%
	top = 64.5%
	width = 58%
	height = 23%
	item_font = "DejaVu Sans Bold 52"
	selected_item_font = "DejaVu Sans Bold 52"
	item_color = "#9ea4d8"
	selected_item_color = "#ffffff"
	item_height = 84
	item_padding = 30
	item_spacing = 14
	icon_width = 0
	icon_height = 0
	selected_item_pixmap_style = "select_*.png"
	scrollbar = false
}

+ label {
	left = 35%
	top = 90.2%
	width = 61%
	align = "right"
	id = "__timeout__"
	text = "Starting in %d s   ·   ↑ ↓ choose   ·   Enter starts   ·   e edits"
	color = "#bfe3d6"
	font = "DejaVu Sans Regular 34"
}
'''

if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    for old in OUT.glob('item_*.png'):
        old.unlink()
    background().save(OUT / 'background.png', optimize=True)
    bands()
    fonts()
    (OUT / 'theme.txt').write_text(THEME)
    print('\n'.join(sorted(p.name for p in OUT.iterdir())))
