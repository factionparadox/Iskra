#!/usr/bin/env python3
"""Make Iskra's logo files from Pasha, the howling wolf pup (run after changing the art):
  branding/pasha.png                              the source picture (transparent background)
  branding/iskra-logo.png and -512/-256/-128/-64  the logo, Pasha on a transparent square
  branding/pasha-512/-256/-128.png                the same, kept under Pasha's name
  desktop/root/usr/share/iskra/iskra-logo.png     the logo, for the system
  desktop/root/usr/share/pixmaps/iskra.png        256 px icon
  desktop/root/usr/share/iskra/iskra-wallpaper.png Pasha howling at the aurora (build/sky.py)
  desktop/root/usr/share/iskra/fastfetch/pasha.txt fastfetch's logo, made from the neofetch logo
                                                  branding/pasha-fastfetch-original.txt
Needs Pillow and NumPy:  python3 build/make-branding.py
"""
import json, re
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont
import sys; sys.path.insert(0, str(Path(__file__).parent)); from sky import sky

ROOT = Path(__file__).resolve().parents[1]
B, SHARE = ROOT / 'branding', ROOT / 'desktop/root/usr/share'
BACKGROUND = (12, 12, 16)          # '#0c0c10', as in iskra-session and the bar
RED, GREY = (213, 43, 30), (150, 150, 158)
FONT = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'


def logo(size):
    """Pasha centred on a transparent square."""
    p = Image.open(B / 'pasha.png').convert('RGBA')
    p = p.crop(p.getchannel('A').getbbox())
    sq = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    t = p.copy(); t.thumbnail((int(size * 0.94),) * 2, Image.LANCZOS)
    sq.paste(t, ((size - t.width) // 2, (size - t.height) // 2), t)
    return sq


def fastfetch():
    """neofetch's logo format (a 'colors' line, ${c1}..${c6}) to fastfetch's ($1..$6).
    Returns fastfetch's logo text and the colours, for the config's logo.color."""
    src = (B / 'pasha-fastfetch-original.txt').read_text().split('\n')
    colours = src[0].split()[1:]
    lines = src[1:]
    while lines and not lines[0].strip(): lines.pop(0)
    while lines and not lines[-1].strip(): lines.pop()
    code = re.compile(r'\$\{c(\d)\}')
    width = lambda l: len(code.sub('', l))
    indent = min(width(l) - len(code.sub('', l).lstrip()) for l in lines if code.sub('', l).strip())
    out = []
    for l in lines:
        l = l.replace('\\\\', '\\')                           # neofetch's \\ is one backslash
        n, i, pre = indent, 0, ''
        while n and i < len(l):                                # drop the shared left margin
            m = code.match(l, i)
            if m: pre += m.group(); i = m.end(); continue
            i += 1; n -= 1
        l = (pre + l[i:]).rstrip()
        parts = code.split(l)                                  # text, colour, text, colour, ...
        out.append(''.join(t.replace('$', '$$') if k % 2 == 0 else '$' + t   # fastfetch: $$ is a $
                           for k, t in enumerate(parts)))
    return '\n'.join(out) + '\n', colours


def main():
    big = logo(1200)
    big.save(B / 'iskra-logo.png', optimize=True)
    for n in (512, 256, 128, 64):
        big.resize((n, n), Image.LANCZOS).save(B / f'iskra-{n}.png', optimize=True)
    for n in (512, 256, 128):
        big.resize((n, n), Image.LANCZOS).save(B / f'pasha-{n}.png', optimize=True)
    for d in ('iskra/fastfetch', 'pixmaps'):
        (SHARE / d).mkdir(parents=True, exist_ok=True)
    big.resize((512, 512), Image.LANCZOS).save(SHARE / 'iskra/iskra-logo.png', optimize=True)
    big.resize((256, 256), Image.LANCZOS).save(SHARE / 'pixmaps/iskra.png', optimize=True)

    wall = sky(2880, 1920).convert('RGBA')                      # Pasha howling at the aurora
    p = logo(760)
    shadow = Image.new('RGBA', wall.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).ellipse((800 - 260, 1795 - 30, 800 + 260, 1795 + 30), fill=(0, 0, 0, 140))
    wall.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(16)))
    wall.alpha_composite(p, (420, 1800 - 760 + 30))
    wall.convert('RGB').save(SHARE / 'iskra/iskra-wallpaper.png', optimize=True)

    text, colours = fastfetch()
    (SHARE / 'iskra/fastfetch/pasha.txt').write_text(text, encoding='utf-8')
    cfg = ROOT / 'desktop/root/etc/xdg/fastfetch/config.jsonc'
    c = cfg.read_text()
    c = re.sub(r'"logo": \{.*?\n  \}', '"logo": {\n    "type": "file",\n'
               '    "source": "/usr/share/iskra/fastfetch/pasha.txt",\n'
               f'    "color": {json.dumps({str(i + 1): v for i, v in enumerate(colours)})},\n'
               '    "padding": { "top": 1, "right": 3 }\n  }', c, flags=re.S)
    cfg.write_text(c)


if __name__ == '__main__':
    main()
