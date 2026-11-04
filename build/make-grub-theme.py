#!/usr/bin/env python3
"""Make Iskra's GRUB theme (run after changing the design below):
  desktop/root/usr/share/iskra/grub-theme/   background.png, theme.txt, the menu's highlight
                                              pieces and its fonts (.pf2, with Cyrillic)
The installer copies it to /boot/grub/themes/iskra.

The screen: Паша the wolf pup (branding/pasha.png) on a meadow, howling at a Siberian aurora
(build/sky.py), ИСКРА and the menu on a dark glass panel on the right. Drawn for the 13 Pro's 3:2 panel
(2880 x 1920); GRUB crops it to other shapes.
Needs Pillow, NumPy and grub-mkfont (grub's tools):  python3 build/make-grub-theme.py
"""
import subprocess
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont
from sky import sky

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'desktop/root/usr/share/iskra/grub-theme'
W, H = 2880, 1920
BG = (12, 12, 16)
RED, DARKRED, GREY, WHITE = (213, 43, 30), (70, 8, 10), (150, 150, 158), (236, 236, 240)
SANS = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
BOLD = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'


def background():
    img = sky(W, H).convert('RGBA')
    # Pasha on the meadow, howling up at the aurora
    p = Image.open(ROOT / 'branding/pasha.png').convert('RGBA')
    p = p.crop(p.getchannel('A').getbbox())
    ph = 980
    p = p.resize((int(p.width * ph / p.height), ph), Image.LANCZOS)
    feet = 1760
    shadow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).ellipse((760 - 330, feet - 40, 760 + 330, feet + 40), fill=(0, 0, 0, 140))
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(18)))
    img.alpha_composite(p, (760 - p.width // 2, feet - ph))
    # a dark glass panel for the name and the menu, so they read against the sky
    panel = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(panel).rounded_rectangle((1500, 470, 2790, 1790), radius=48, fill=(8, 8, 20, 150))
    img.alpha_composite(panel.filter(ImageFilter.GaussianBlur(2)))
    d = ImageDraw.Draw(img)
    title = ImageFont.truetype(BOLD, 190)
    x0, y0 = 1580, 520
    x = x0
    for ch in 'ИСКРА':
        d.text((x, y0), ch, font=title, fill=WHITE)
        x += d.textlength(ch, font=title) + 30
    sub = ImageFont.truetype(SANS, 56)
    d.text((x0 + 6, y0 + 230), 'Iskra  ·  built on Slackware', font=sub, fill=(190, 200, 215))
    d.rectangle((x0 + 6, y0 + 320, x0 + 1110, y0 + 325), fill=RED)
    return img.convert('RGB')


def highlight():
    # the selected menu line: a translucent white band with a solid red bar at its left edge
    Image.new('RGBA', (8, 8), (255, 255, 255, 40)).save(OUT / 'select_c.png')
    Image.new('RGBA', (12, 8), (213, 43, 30, 255)).save(OUT / 'select_w.png')
    Image.new('RGBA', (8, 8), (255, 255, 255, 40)).save(OUT / 'select_e.png')


def fonts():
    ranges = '0x20-0x7e,0xa0-0x17f,0x400-0x4ff,0x2010-0x2027,0x2190-0x21ff,0x25b2-0x25bc'
    for path, size, name in ((SANS, 44, 'menu'), (SANS, 32, 'hint'), (BOLD, 44, 'menu-bold')):
        subprocess.run(['grub-mkfont', '-s', str(size), '-r', ranges, '-o', str(OUT / f'{name}.pf2'), path],
                       check=True)


THEME = '''# Iskra's GRUB theme (made by build/make-grub-theme.py)
title-text: ""
desktop-image: "background.png"
desktop-image-scale-method: "crop"
desktop-color: "#0a0a1c"
terminal-font: "DejaVu Sans Regular 32"

+ boot_menu {
	left = 54%
	top = 44%
	width = 40%
	height = 40%
	item_font = "DejaVu Sans Regular 44"
	selected_item_font = "DejaVu Sans Bold 44"
	item_color = "#b4bccc"
	selected_item_color = "#ececf0"
	item_height = 76
	item_padding = 28
	item_spacing = 14
	icon_width = 0
	icon_height = 0
	selected_item_pixmap_style = "select_*.png"
	scrollbar = false
}

+ label {
	left = 54%
	top = 88%
	width = 40%
	align = "left"
	id = "__timeout__"
	text = "Starting in %d s  ·  ↑ ↓ choose  ·  Enter starts  ·  e edits"
	color = "#b4bccc"
	font = "DejaVu Sans Regular 32"
}
'''


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    background().save(OUT / 'background.png', optimize=True)
    highlight()
    if not all((OUT / f'{n}.pf2').exists() for n in ('menu', 'hint', 'menu-bold')):
        fonts()
    (OUT / 'theme.txt').write_text(THEME)
    for f in sorted(OUT.iterdir()):
        print(f'{f.stat().st_size:>9}  {f.relative_to(ROOT)}')


if __name__ == '__main__':
    main()
