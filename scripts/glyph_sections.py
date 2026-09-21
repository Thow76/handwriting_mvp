"""
Draw a letter's section zones on top of the real Andika glyph.

Replaces the per-letter throwaway scripts (visualize_e_proposed.py,
visualize_f_rects.py, ...) with one tool that works for any letter.

By default it reads the section rectangles straight out of
lib/models/letter_formation_registry.dart, so the picture always shows what
the app is actually using. Pass --spec to preview a proposed redesign before
writing it into the registry.

Usage:
    python3 scripts/glyph_sections.py g
    python3 scripts/glyph_sections.py g --spec proposals/g.json
    python3 scripts/glyph_sections.py --all

Output goes to artifacts/<letter>_sections.png.

Coordinates are fractions of the glyph's tight ink bounds (0.0-1.0), which is
the same coordinate system the registry and the scorer use. They do not depend
on the app's canvas size.
"""

import argparse
import json
import os
import re
import sys

from PIL import Image, ImageDraw, ImageFont

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
FONT_PATH = os.path.join(PROJECT_DIR, "fonts", "Andika-Regular.ttf")
REGISTRY_PATH = os.path.join(
    PROJECT_DIR, "lib", "models", "letter_formation_registry.dart"
)
OUT_DIR = os.path.join(PROJECT_DIR, "artifacts")

FONT_SIZE = 120.0          # matches drawing_canvas.dart
TARGET_HEIGHT = 460        # on-screen size of the rendered picture
ALPHA_THRESHOLD = 10       # matches TemplateRasterizer's ink test

INK = (20, 20, 20, 255)
GRID = (222, 42, 32, 255)
HATCH = (222, 42, 32, 90)
LABEL_BG = (20, 20, 20, 235)
LABEL_FG = (255, 255, 255, 255)
WARN = (214, 124, 0, 255)


# ---------------------------------------------------------------------------
# Glyph rendering — mirrors TemplateRasterizer + TemplateRasterResult.tightBounds
# ---------------------------------------------------------------------------

def render_glyph(letter):
    """Rasterize `letter` and return (mask, tight bounds as pixel box)."""
    font = ImageFont.truetype(FONT_PATH, size=int(FONT_SIZE))
    ascent, descent = font.getmetrics()
    w = int(font.getlength(letter))
    h = ascent + descent

    img = Image.new("RGBA", (w + 20, h + 4), (0, 0, 0, 0))
    ImageDraw.Draw(img).text((0, 0), letter, font=font, fill=INK)
    img = img.crop((0, 0, w, h))

    px = img.load()
    mask = [[px[c, r][3] > ALPHA_THRESHOLD for c in range(w)] for r in range(h)]

    rows = [r for r in range(h) if any(mask[r])]
    cols = [c for c in range(w) if any(mask[r][c] for r in range(h))]
    if not rows or not cols:
        raise SystemExit(f"No ink rendered for {letter!r}")

    # Matches Rect.fromLTRB(left+firstCol, top+firstRow, left+lastCol+1, top+lastRow+1)
    box = (cols[0], rows[0], cols[-1] + 1, rows[-1] + 1)
    return img, mask, box


# ---------------------------------------------------------------------------
# Section sources
# ---------------------------------------------------------------------------

LETTER_RE = r"^  '(?P<letter>[a-z])': LetterFormationData\("
SECTION_RE = re.compile(
    r"WaypointSection\(\s*"
    r"number:\s*(?P<n>\d+),\s*"
    r"rect:\s*const StrokeStartRect\(\s*"
    r"minX:\s*(?P<minX>[-\d.]+),\s*"
    r"maxX:\s*(?P<maxX>[-\d.]+),\s*"
    r"minY:\s*(?P<minY>[-\d.]+),\s*"
    r"maxY:\s*(?P<maxY>[-\d.]+),?\s*\)",
    re.S,
)


def sections_from_registry(letter):
    """Pull `letter`'s numbered sections out of the Dart registry."""
    src = open(REGISTRY_PATH).read()
    blocks = list(re.finditer(LETTER_RE, src, re.M))
    block = None
    for i, m in enumerate(blocks):
        if m.group("letter") == letter:
            end = blocks[i + 1].start() if i + 1 < len(blocks) else len(src)
            block = src[m.start():end]
            break
    if block is None:
        raise SystemExit(f"Letter {letter!r} not found in the registry.")

    # Stroke index = how many ExpectedStroke( headers precede this section.
    stroke_starts = [m.start() for m in re.finditer(r"ExpectedStroke\(", block)]

    out = []
    for m in SECTION_RE.finditer(block):
        stroke = sum(1 for s in stroke_starts if s < m.start()) - 1
        out.append({
            "n": int(m.group("n")),
            "stroke": max(stroke, 0),
            "minX": float(m.group("minX")), "maxX": float(m.group("maxX")),
            "minY": float(m.group("minY")), "maxY": float(m.group("maxY")),
        })
    return sorted(out, key=lambda s: s["n"])


def sections_from_spec(path):
    """Load a proposed design.

    Sections may be given either as explicit fractions, or as grid cells
    referring to `cols` / `rows` boundary lists (easier to author):

        {"cols": [0, 0.39, 0.72, 1.0],
         "rows": [0, 0.33, 0.65, 1.0],
         "sections": [{"n": 1, "stroke": 0, "col": 1, "row": 0}, ...]}
    """
    spec = json.load(open(path))
    cols, rows = spec.get("cols"), spec.get("rows")
    out = []
    for s in spec["sections"]:
        if "col" in s:
            c, r = s["col"], s["row"]
            rect = dict(minX=cols[c], maxX=cols[c + 1],
                        minY=rows[r], maxY=rows[r + 1])
        else:
            rect = {k: s[k] for k in ("minX", "maxX", "minY", "maxY")}
        out.append({"n": s["n"], "stroke": s.get("stroke", 0), **rect})
    return sorted(out, key=lambda s: s["n"])


# ---------------------------------------------------------------------------
# Ink diagnostics — the check that would have caught the broken 'e'
# ---------------------------------------------------------------------------

def ink_fraction(mask, box, sec):
    """What proportion of this section's area actually has letter ink in it?"""
    x0, y0, x1, y1 = box
    tw, th = x1 - x0, y1 - y0
    c0 = x0 + int(sec["minX"] * tw)
    c1 = x0 + int(sec["maxX"] * tw)
    r0 = y0 + int(sec["minY"] * th)
    r1 = y0 + int(sec["maxY"] * th)
    total = inked = 0
    for r in range(r0, min(r1, y1)):
        for c in range(c0, min(c1, x1)):
            total += 1
            if mask[r][c]:
                inked += 1
    return (inked / total) if total else 0.0



# ---------------------------------------------------------------------------
# Text view — lets the shape be inspected precisely without an image viewer
# ---------------------------------------------------------------------------

def ascii_view(letter, mask, box, cols=40, rows=34):
    """Print the glyph as text, with 10% gridlines, in tight-bounds fractions."""
    x0, y0, x1, y1 = box
    tw, th = x1 - x0, y1 - y0
    print(f"--- {letter} --- tight bounds {tw}x{th}px "
          f"(aspect {tw/th:.2f}); columns are x-fraction, rows are y-fraction")
    header = "     " + "".join(
        str(int(c / cols * 10)) if int(c / cols * 10) != int((c - 1) / cols * 10)
        else " " for c in range(cols))
    print(header)
    for r in range(rows):
        yf = r / rows
        band = []
        for c in range(cols):
            xf = c / cols
            r0 = y0 + int(yf * th)
            r1 = max(r0 + 1, y0 + int((r + 1) / rows * th))
            c0 = x0 + int(xf * tw)
            c1 = max(c0 + 1, x0 + int((c + 1) / cols * tw))
            n = sum(1 for rr in range(r0, min(r1, y1))
                    for cc in range(c0, min(c1, x1)) if mask[rr][cc])
            tot = (min(r1, y1) - r0) * (min(c1, x1) - c0)
            d = n / tot if tot else 0
            band.append("#" if d > 0.6 else ("+" if d > 0.25 else
                        ("." if d > 0.05 else " ")))
        print(f"{yf:4.2f} " + "".join(band))
    print()

# ---------------------------------------------------------------------------
# Drawing
# ---------------------------------------------------------------------------

def draw(letter, img, mask, box, sections, out_path):
    """Draw the numbered zones over the real glyph.

    Zone rectangles are outlined in red. Anything inside the letter's box that
    no zone claims is cross-hatched — that area is simply "don't care": the
    scorer never requires the pen to go there, and never penalises it either.
    """
    x0, y0, x1, y1 = box
    tight = img.crop(box)
    tw, th = x1 - x0, y1 - y0

    scale = TARGET_HEIGHT / th
    vw, vh = int(tw * scale), int(th * scale)
    pad = 30

    canvas = Image.new("RGBA", (vw + pad * 2, vh + pad * 2), (255, 255, 255, 255))
    glyph = tight.resize((vw, vh), Image.LANCZOS)
    canvas.paste(glyph, (pad, pad), glyph)

    def X(f): return pad + f * vw
    def Y(f): return pad + f * vh

    # --- cross-hatch everything no zone claims, as one clipped region --------
    claimed = Image.new("L", canvas.size, 0)
    cd = ImageDraw.Draw(claimed)
    for s in sections:
        cd.rectangle([X(s["minX"]), Y(s["minY"]), X(s["maxX"]), Y(s["maxY"])],
                     fill=255)
    inside = Image.new("L", canvas.size, 0)
    ImageDraw.Draw(inside).rectangle([X(0), Y(0), X(1), Y(1)], fill=255)
    unclaimed = Image.eval(claimed, lambda v: 255 - v)
    unclaimed = Image.composite(unclaimed, Image.new("L", canvas.size, 0), inside)

    hatch = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    hd = ImageDraw.Draw(hatch)
    for k in range(-canvas.size[1], canvas.size[0], 11):
        hd.line([(k, 0), (k + canvas.size[1], canvas.size[1])],
                fill=HATCH, width=2)
    canvas.paste(hatch, (0, 0), Image.composite(
        hatch.split()[3], Image.new("L", canvas.size, 0), unclaimed))

    d = ImageDraw.Draw(canvas)

    # --- zone outlines -------------------------------------------------------
    for s in sections:
        d.rectangle([X(s["minX"]), Y(s["minY"]), X(s["maxX"]), Y(s["maxY"])],
                    outline=GRID, width=3)
    d.rectangle([X(0), Y(0), X(1), Y(1)], outline=GRID, width=4)

    try:
        lf = ImageFont.truetype(FONT_PATH, size=32)
    except OSError:
        lf = ImageFont.load_default()

    # --- numbers -------------------------------------------------------------
    warnings = []
    for s in sections:
        frac = ink_fraction(mask, box, s)
        if frac < 0.02:
            warnings.append((s["n"], frac))
        cx = X((s["minX"] + s["maxX"]) / 2)
        cy = Y((s["minY"] + s["maxY"]) / 2)
        label = str(s["n"])
        tb = d.textbbox((0, 0), label, font=lf)
        w, h = tb[2] - tb[0], tb[3] - tb[1]
        r = max(w, h) // 2 + 12
        d.ellipse([cx - r, cy - r, cx + r, cy + r],
                  fill=(WARN if frac < 0.02 else LABEL_BG))
        d.text((cx - w / 2 - tb[0], cy - h / 2 - tb[1]), label,
               font=lf, fill=LABEL_FG)

    canvas.convert("RGB").save(out_path)

    print(f"  {letter}: {len(sections)} sections -> "
          f"{os.path.relpath(out_path, PROJECT_DIR)}")
    for s in sections:
        frac = ink_fraction(mask, box, s)
        flag = "  <-- NO INK" if frac < 0.02 else ""
        lbl = f"  {s.get('label','')}" if s.get("label") else ""
        print(f"     {s['n']} (stroke {s['stroke']})  "
              f"x {s['minX']:.2f}-{s['maxX']:.2f}  y {s['minY']:.2f}-{s['maxY']:.2f}"
              f"  ink {frac * 100:5.1f}%{flag}{lbl}")
    if warnings:
        ns = ", ".join(str(n) for n, _ in warnings)
        print(f"     WARNING: zone(s) {ns} contain essentially no ink.")
    return warnings


def migrated_letters():
    src = open(REGISTRY_PATH).read()
    blocks = list(re.finditer(LETTER_RE, src, re.M))
    out = []
    for i, m in enumerate(blocks):
        end = blocks[i + 1].start() if i + 1 < len(blocks) else len(src)
        if "WaypointSection(" in src[m.start():end]:
            out.append(m.group("letter"))
    return sorted(out)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("letter", nargs="?", help="a single lowercase letter")
    ap.add_argument("--spec", help="JSON file describing a proposed design")
    ap.add_argument("--all", action="store_true",
                    help="render every letter that already has sections")
    ap.add_argument("--suffix", default="sections", help="output filename suffix")
    ap.add_argument("--ascii", action="store_true", help="print the glyph as text and exit")
    args = ap.parse_args()

    os.makedirs(OUT_DIR, exist_ok=True)

    if args.all:
        letters = migrated_letters()
    elif args.letter:
        letters = [args.letter]
    else:
        ap.error("give a letter, or --all")

    if args.ascii:
        for letter in letters:
            _, mask, box = render_glyph(letter)
            ascii_view(letter, mask, box)
        return 0

    any_warn = False
    for letter in letters:
        img, mask, box = render_glyph(letter)
        sections = (sections_from_spec(args.spec) if args.spec
                    else sections_from_registry(letter))
        out = os.path.join(OUT_DIR, f"{letter}_{args.suffix}.png")
        if draw(letter, img, mask, box, sections, out):
            any_warn = True
        print()

    return 1 if any_warn else 0


if __name__ == "__main__":
    sys.exit(main())
