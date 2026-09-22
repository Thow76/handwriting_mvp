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
    python3 scripts/glyph_sections.py g --spec proposals/g.json --check-only

Output goes to artifacts/<letter>_sections.png.

Every run validates the design first (see `validate`). A design that is not a
well-formed ragged grid, or that has a zone with no ink in it, is reported zone
by zone and the tool exits non-zero. --check-only validates without drawing.

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
        out.append({"n": s["n"], "stroke": s.get("stroke", 0),
                    "label": s.get("label", ""), **rect})
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
# Validator — the ragged-grid rules, enforced on every render
# ---------------------------------------------------------------------------
#
# A design is a RAGGED GRID. Boundary lines are chosen per letter; every zone
# is a rectangle whose four edges sit on those shared lines. A line need not
# run the full width or height of the letter, so one column may be cut into
# different rows from its neighbour. The rules are:
#
#   1. Zone numbers are 1..N with no gaps and no repeats.
#   2. Every rectangle is inside 0..1 and has positive width and height.
#   3. No two zones overlap.
#   4. Every zone edge lines up: it sits on the outer 0.0/1.0 boundary, or on
#      the same line as some other zone's edge, or it is the outer silhouette
#      of the design (nothing at all is claimed between that edge and the
#      outer boundary, so the edge cannot be out of line with anything).
#   5. Every zone actually contains ink.
#
# Any breach is a hard failure: the message names the offending zones and the
# process exits non-zero.

TOL = 1e-6
MIN_INK = 0.02          # a zone with less ink than this is "essentially empty"


def _overlap_errors(sections):
    errs = []
    for i, a in enumerate(sections):
        for b in sections[i + 1:]:
            ox = min(a["maxX"], b["maxX"]) - max(a["minX"], b["minX"])
            oy = min(a["maxY"], b["maxY"]) - max(a["minY"], b["minY"])
            if ox > TOL and oy > TOL:
                errs.append(
                    f"zones {a['n']} and {b['n']} OVERLAP over "
                    f"x {max(a['minX'], b['minX']):.3f}-{min(a['maxX'], b['maxX']):.3f}, "
                    f"y {max(a['minY'], b['minY']):.3f}-{min(a['maxY'], b['maxY']):.3f} "
                    f"(zone {a['n']}: x {a['minX']:.2f}-{a['maxX']:.2f} "
                    f"y {a['minY']:.2f}-{a['maxY']:.2f}; "
                    f"zone {b['n']}: x {b['minX']:.2f}-{b['maxX']:.2f} "
                    f"y {b['minY']:.2f}-{b['maxY']:.2f})"
                )
    return errs


def _claims(sections, x0, x1, y0, y1, skip=None):
    """Any zone (other than `skip`) with positive-area overlap of this box?"""
    for s in sections:
        if s is skip:
            continue
        if (min(s["maxX"], x1) - max(s["minX"], x0) > TOL
                and min(s["maxY"], y1) - max(s["minY"], y0) > TOL):
            return s
    return None


def _edge_errors(sections):
    """Rule 4: no free-floating edges inside the claimed area."""
    errs = []
    axes = (
        # label,  edge key,  the other edge on the same axis, span keys, direction
        ("left",   "minX", "maxX", "minY", "maxY", -1, "x"),
        ("right",  "maxX", "minX", "minY", "maxY", +1, "x"),
        ("top",    "minY", "maxY", "minX", "maxX", -1, "y"),
        ("bottom", "maxY", "minY", "minX", "maxX", +1, "y"),
    )
    for s in sections:
        for name, key, twin, span0, span1, direction, axis in axes:
            v = s[key]
            if abs(v) < TOL or abs(v - 1.0) < TOL:
                continue                                    # outer boundary

            # Shared with any other zone's edge on the same axis?
            shared = any(
                abs(o[k] - v) < TOL
                for o in sections if o is not s
                for k in (key, twin)
            )
            if shared:
                continue

            # Outer silhouette? Nothing claimed between this edge and the rim.
            b0, b1 = s[span0], s[span1]
            if direction > 0:
                beyond = (v, 1.0) if axis == "x" else (v, 1.0)
            else:
                beyond = (0.0, v)
            if axis == "x":
                blocker = _claims(sections, beyond[0], beyond[1], b0, b1, skip=s)
            else:
                blocker = _claims(sections, b0, b1, beyond[0], beyond[1], skip=s)
            if blocker is None:
                continue

            errs.append(
                f"zone {s['n']}'s {name} edge at {axis}={v:.3f} does not line up "
                f"with any other zone edge or the outer boundary "
                f"(zone {blocker['n']} sits beyond it, so the gap is not open to "
                f"the rim). Move it onto a shared line."
            )
    return errs


def validate(letter, sections, mask, box, source=""):
    """Return a list of human-readable failures. Empty list means the design is
    a well-formed ragged grid with ink in every zone."""
    errs = []
    where = f"{letter}" + (f" ({source})" if source else "")

    if not sections:
        return [f"{where}: no zones at all."]

    # Rule 1 — numbering is 1..N, no gaps, no repeats.
    nums = sorted(s["n"] for s in sections)
    expected = list(range(1, len(sections) + 1))
    if nums != expected:
        errs.append(
            f"zone numbers are {nums}, expected {expected} "
            f"(numbers must run 1..{len(sections)} with no gaps and no repeats)"
        )

    # Rule 2 — rectangles are sane.
    for s in sections:
        if not (0.0 - TOL <= s["minX"] < s["maxX"] <= 1.0 + TOL
                and 0.0 - TOL <= s["minY"] < s["maxY"] <= 1.0 + TOL):
            errs.append(
                f"zone {s['n']} is not a valid rectangle inside 0..1: "
                f"x {s['minX']:.2f}-{s['maxX']:.2f} y {s['minY']:.2f}-{s['maxY']:.2f}"
            )
    if errs:
        return [f"{where}: {e}" for e in errs]

    # Rule 3 — no overlaps.
    errs += _overlap_errors(sections)

    # Rule 4 — every edge lines up.
    errs += _edge_errors(sections)

    # Rule 5 — every zone contains ink.
    for s in sections:
        frac = ink_fraction(mask, box, s)
        if frac < MIN_INK:
            errs.append(
                f"zone {s['n']} contains essentially no ink ({frac * 100:.1f}%, "
                f"needs at least {MIN_INK * 100:.0f}%): "
                f"x {s['minX']:.2f}-{s['maxX']:.2f} y {s['minY']:.2f}-{s['maxY']:.2f}"
            )

    return [f"{where}: {e}" for e in errs]


def report(letter, sections, errors):
    """Print the check result for one letter."""
    if errors:
        print(f"  FAIL  {letter}: {len(errors)} problem(s)")
        for e in errors:
            print(f"    !! {e}")
    else:
        print(f"  ok    {letter}: {len(sections)} zones, ragged grid valid, "
              f"ink in every zone")



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
    for s in sections:
        frac = ink_fraction(mask, box, s)
        cx = X((s["minX"] + s["maxX"]) / 2)
        cy = Y((s["minY"] + s["maxY"]) / 2)
        label = str(s["n"])
        tb = d.textbbox((0, 0), label, font=lf)
        w, h = tb[2] - tb[0], tb[3] - tb[1]
        r = max(w, h) // 2 + 12
        d.ellipse([cx - r, cy - r, cx + r, cy + r],
                  fill=(WARN if frac < MIN_INK else LABEL_BG))
        d.text((cx - w / 2 - tb[0], cy - h / 2 - tb[1]), label,
               font=lf, fill=LABEL_FG)

    canvas.convert("RGB").save(out_path)

    print(f"  {letter}: {len(sections)} sections -> "
          f"{os.path.relpath(out_path, PROJECT_DIR)}")
    for s in sections:
        frac = ink_fraction(mask, box, s)
        flag = "  <-- NO INK" if frac < MIN_INK else ""
        lbl = f"  {s.get('label','')}" if s.get("label") else ""
        print(f"     {s['n']} (stroke {s['stroke']})  "
              f"x {s['minX']:.2f}-{s['maxX']:.2f}  y {s['minY']:.2f}-{s['maxY']:.2f}"
              f"  ink {frac * 100:5.1f}%{flag}{lbl}")


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
    ap.add_argument("--check-only", action="store_true",
                    help="validate the design(s) without drawing anything")
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

    failed = []
    for letter in letters:
        img, mask, box = render_glyph(letter)
        source = args.spec if args.spec else "registry"
        sections = (sections_from_spec(args.spec) if args.spec
                    else sections_from_registry(letter))

        errors = validate(letter, sections, mask, box, source=source)
        report(letter, sections, errors)
        if errors:
            failed.append(letter)

        if not args.check_only:
            out = os.path.join(OUT_DIR, f"{letter}_{args.suffix}.png")
            draw(letter, img, mask, box, sections, out)
        print()

    if failed:
        print("=" * 72)
        print(f"CHECK FAILED for: {', '.join(failed)}")
        print("The zones above are not a valid ragged grid (see the !! lines).")
        print("=" * 72)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
