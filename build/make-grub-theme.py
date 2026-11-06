#!/usr/bin/env python3
"""Make Avalon's GRUB theme (run after changing the design below):
  desktop/usr/share/avalon/grub-theme/   background.png, theme.txt, the menu's band pieces, fonts
The disc uses it for its own boot menu (build/make-iso); the installer copies it to
/boot/grub/themes/avalon.

The screen is the Garden System's: the 3D garden (desktop/usr/share/avalon/garden-wallpaper.png,
from build/render-garden.py) with a HUD panel laid over the soil at the bottom, in the shell's
colours (services/Theme.qml). On the left, the AVALON banner from the star system screen; on the
right, the menu as chevron bands, the chosen one bright blue with a cyan edge.
Drawn for the 13 Pro's 3:2 panel (2880 x 1920); GRUB crops it to other shapes.
Needs Pillow and grub-mkfont:  python3 build/make-grub-theme.py
"""
import subprocess
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'desktop/usr/share/avalon/grub-theme'
W, H = 2880, 1920
NIGHT, PANEL, EDGE = (7, 11, 22), (12, 20, 38), (58, 90, 140)
CYAN, MAGENTA, MINT = (95, 216, 240), (255, 63, 164), (191, 227, 214)
BLUE, SLATE = (47, 92, 208), (52, 60, 92)
ELEMENTS = (('土', (201, 163, 90)), ('水', (74, 100, 200)), ('風', (91, 200, 91)), ('火', (224, 112, 90)))
SANS = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
BOLD = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
CJK = '/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc'

# the HUD panel: x0, y0, x1, y1, and how far its corners are cut
PX0, PY0, PX1, PY1, CUT = 150, 1270, 2730, 1860, 56


def cut_box(x0, y0, x1, y1, c):
    return [(x0 + c, y0), (x1, y0), (x1, y1 - c), (x1 - c, y1), (x0, y1), (x0, y0 + c)]


def background():
    img = Image.open(ROOT / 'desktop/usr/share/avalon/garden-wallpaper.png').convert('RGBA')
    img = img.resize((W, H), Image.NEAREST) if img.size != (W, H) else img
    # the panel's shadow, then the panel, its edge, and a cyan accent along the top
    sh = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(sh).polygon(cut_box(PX0 + 14, PY0 + 18, PX1 + 14, PY1 + 18, CUT), fill=(0, 0, 0, 150))
    img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(14)))
    layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.polygon(cut_box(PX0, PY0, PX1, PY1, CUT), fill=PANEL + (226,), outline=EDGE + (255,), width=4)
    d.line([(PX0 + CUT + 30, PY0 + 2), (PX0 + 760, PY0 + 2)], fill=CYAN + (255,), width=6)
    d.line([(PX1 - 420, PY1 - 2), (PX1 - CUT - 20, PY1 - 2)], fill=MAGENTA + (255,), width=6)
    img.alpha_composite(layer)

    d = ImageDraw.Draw(img)
    # the banner: AVALON on a blue block, between cyan quote marks (as on the star system screen)
    title = ImageFont.truetype(BOLD, 150)
    bx, by = PX0 + 150, PY0 + 70
    tw = d.textlength('AVALON', font=title)
    d.rectangle((bx, by, bx + tw + 90, by + 190), fill=(22, 52, 150))
    d.rectangle((bx + tw + 90, by, bx + tw + 150, by + 190), fill=NIGHT)
    d.text((bx + 40, by + 14), 'AVALON', font=title, fill=(245, 248, 255))
    quote = ImageFont.truetype(BOLD, 150)
    d.text((bx - 90, by - 40), '‘', font=quote, fill=CYAN)
    d.text((bx + tw + 160, by - 40), '’', font=quote, fill=CYAN)
    sub = ImageFont.truetype(SANS, 54)
    d.text((bx + 6, by + 215), 'Avalon 1 (Iskra)  ·  CRUX 3.8', font=sub, fill=MINT)
    # the four elements, as in the HUD's planet panel
    cjk = ImageFont.truetype(CJK, 64)
    x = bx + 6
    for glyph, colour in ELEMENTS:
        d.rectangle((x, by + 300, x + 96, by + 306), fill=colour)
        d.text((x + 16, by + 308), glyph, font=cjk, fill=colour)
        x += 130
    # a thin divider between the banner and the menu
    d.line([(1230, PY0 + 60), (1230, PY1 - 60)], fill=EDGE, width=3)
    return img.convert('RGB')


def bands():
    # menu lines: a solid band that fades out to the right, like the star system's planet list.
    # GRUB stretches the centre piece and draws the west and east pieces at their own size
    def piece(name, size, colour, fade=False):
        im = Image.new('RGBA', size, (0, 0, 0, 0))
        px = im.load()
        for x in range(size[0]):
            a = colour[3] * (1 - x / size[0]) ** 1.4 if fade else colour[3]
            for y in range(size[1]):
                px[x, y] = colour[:3] + (int(a),)
        im.save(OUT / name)
    piece('select_w.png', (12, 8), CYAN + (255,))
    piece('select_c.png', (8, 8), BLUE + (235,))
    piece('select_e.png', (320, 8), BLUE + (235,), fade=True)
    piece('item_w.png', (12, 8), SLATE + (200,))
    piece('item_c.png', (8, 8), SLATE + (170,))
    piece('item_e.png', (320, 8), SLATE + (170,), fade=True)


def fonts():
    ranges = '0x20-0x7e,0xa0-0x17f,0x400-0x4ff,0x2010-0x2027,0x2190-0x21ff'
    for path, size, name in ((BOLD, 46, 'menu'), (SANS, 32, 'hint')):
        subprocess.run(['grub-mkfont', '-s', str(size), '-r', ranges, '-o', str(OUT / f'{name}.pf2'), path],
                       check=True)


THEME = '''# Avalon's GRUB theme (made by build/make-grub-theme.py)
title-text: ""
desktop-image: "background.png"
desktop-image-scale-method: "crop"
desktop-color: "#070b16"
terminal-font: "DejaVu Sans Regular 32"

+ boot_menu {
	left = 46%
	top = 70%
	width = 46%
	height = 25%
	item_font = "DejaVu Sans Bold 46"
	selected_item_font = "DejaVu Sans Bold 46"
	item_color = "#c8cce0"
	selected_item_color = "#ffffff"
	item_height = 74
	item_padding = 26
	item_spacing = 12
	icon_width = 0
	icon_height = 0
	item_pixmap_style = "item_*.png"
	selected_item_pixmap_style = "select_*.png"
	scrollbar = false
}

+ label {
	left = 10.5%
	top = 93%
	width = 32%
	align = "left"
	id = "__timeout__"
	text = "Starting in %d s  ·  ↑ ↓  ·  Enter  ·  e edits"
	color = "#bfe3d6"
	font = "DejaVu Sans Regular 32"
}
'''

if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    background().save(OUT / 'background.png', optimize=True)
    bands()
    fonts()
    (OUT / 'theme.txt').write_text(THEME)
    print('\n'.join(sorted(p.name for p in OUT.iterdir())))
