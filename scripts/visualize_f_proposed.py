"""
Visualise PROPOSED new StrokeStartScorer rectangles for letter 'f'.

Proposed values (not yet in the registry):
  Stroke 0 (stem):     x 0.55–1.00,  y 0.00–0.15
  Stroke 1 (crossbar): x 0.00–0.25,  y 0.25–0.40

Same glyph-rasterization pipeline as visualize_f_rects.py.
No observed-start dots — this is purely a "does the rectangle sit on the ink?"
check.
"""

import os
from PIL import Image, ImageDraw, ImageFont

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
SCRIPT_DIR  = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
FONT_PATH   = os.path.join(PROJECT_DIR, "fonts", "ComicNeue-Regular.ttf")
OUTPUT_PATH = os.path.join(PROJECT_DIR, "f_proposed_rects.png")

# ---------------------------------------------------------------------------
# Flutter constants (unchanged)
# ---------------------------------------------------------------------------
FONT_SIZE       = 120.0
CANVAS_WIDTH    = 400.0
CANVAS_HEIGHT   = 600.0
ASCENDER_RATIO  = 0.685
DESCENDER_RATIO = 0.193
X_HEIGHT_RATIO  = 0.493

ascender_height = FONT_SIZE * ASCENDER_RATIO     # 82.2
descender_depth = FONT_SIZE * DESCENDER_RATIO    # 23.16
total_height    = ascender_height + descender_depth  # 105.36
baseline        = (CANVAS_HEIGHT - total_height) / 2 + ascender_height  # 329.52
midline         = baseline - FONT_SIZE * X_HEIGHT_RATIO                  # 270.36

# ---------------------------------------------------------------------------
# Rasterize 'f' exactly as Flutter's TemplateRasterizer does
# ---------------------------------------------------------------------------
font = ImageFont.truetype(FONT_PATH, size=int(FONT_SIZE))
ascent_px, descent_px = font.getmetrics()
glyph_advance = font.getlength("f")

flutter_canvas_w = int(glyph_advance)          # painter.width.ceil()
flutter_canvas_h = ascent_px + descent_px      # painter.height.ceil()

# Render wider to capture any bleed, then crop to Flutter's canvas.
tmp_raw = Image.new("RGBA", (flutter_canvas_w + 20, flutter_canvas_h + 4), (0, 0, 0, 0))
ImageDraw.Draw(tmp_raw).text((0, 0), "f", font=font, fill=(0, 0, 0, 255))
tmp = tmp_raw.crop((0, 0, flutter_canvas_w, flutter_canvas_h))

# Boolean mask: True = ink pixel.
px = tmp.load()
mask = [[px[c, r][3] > 10 for c in range(flutter_canvas_w)]
        for r in range(flutter_canvas_h)]

# tightBounds: tight on both axes (matches TemplateRasterResult.tightBounds).
first_row = next(r for r in range(flutter_canvas_h) if any(mask[r]))
last_row  = max(r for r in range(flutter_canvas_h) if any(mask[r]))
first_col = next(c for c in range(flutter_canvas_w)
                 if any(mask[r][c] for r in range(flutter_canvas_h)))
last_col  = max(c for c in range(flutter_canvas_w)
                if any(mask[r][c] for r in range(flutter_canvas_h)))

tight_w = last_col  - first_col  + 1   # 33 px
tight_h = last_row  - first_row  + 1   # 83 px

# Canvas-space position of tightBounds.top (needed for midline offset).
canvas_x   = (CANVAS_WIDTH - glyph_advance) / 2
canvas_y   = baseline - ascent_px           # bounds.top in canvas coords
tight_top  = canvas_y + first_row           # tightBounds.top in canvas coords

# ---------------------------------------------------------------------------
# PROPOSED rectangles
# ---------------------------------------------------------------------------
rects = [
    dict(
        name="Stroke 0 — stem",
        label="STEM",
        minX=0.55, maxX=1.00,
        minY=0.00, maxY=0.15,
        fill=(220,  60,  60),   # red
        border=(180,  20,  20),
    ),
    dict(
        name="Stroke 1 — crossbar",
        label="XBAR",
        minX=0.00, maxX=0.25,
        minY=0.25, maxY=0.40,
        fill=( 60, 130, 230),   # blue
        border=( 20,  70, 190),
    ),
]

# Compute pixel positions and print measurements.
print("=" * 62)
print("PROPOSED rectangle pixel positions (within tightBounds)")
print(f"  tightBounds: {tight_w} × {tight_h} px")
print("=" * 62)
for r in rects:
    r["px0"] = r["minX"] * tight_w
    r["px1"] = r["maxX"] * tight_w
    r["py0"] = r["minY"] * tight_h
    r["py1"] = r["maxY"] * tight_h
    pw = r["px1"] - r["px0"]
    ph = r["py1"] - r["py0"]
    print(f"\n  {r['name']}")
    print(f"    fractions : x {r['minX']:.2f}–{r['maxX']:.2f},  y {r['minY']:.2f}–{r['maxY']:.2f}")
    print(f"    pixel x   : {r['px0']:.1f} – {r['px1']:.1f}  (width  {pw:.1f} px)")
    print(f"    pixel y   : {r['py0']:.1f} – {r['py1']:.1f}  (height {ph:.1f} px)")

# Midline in tightBounds-relative pixels.
midline_y_tight = midline - tight_top   # how many px from tight top to midline
print(f"\n  midline within tightBounds: y = {midline_y_tight:.1f} px  "
      f"({midline_y_tight/tight_h*100:.1f}% of height)")

# ---------------------------------------------------------------------------
# Build the visualisation image
# ---------------------------------------------------------------------------
SCALE = 6   # each glyph pixel → 6×6 screen pixels for readability
VIZ_W = tight_w * SCALE
VIZ_H = tight_h * SCALE

# --- background: glyph ink ---
glyph_crop  = tmp.crop((first_col, first_row, last_col + 1, last_row + 1))
glyph_large = glyph_crop.resize((VIZ_W, VIZ_H), Image.NEAREST).convert("RGBA")

viz = Image.new("RGBA", (VIZ_W, VIZ_H), (235, 235, 235, 255))
viz_px = viz.load()
gl_px  = glyph_large.load()
for y in range(VIZ_H):
    for x in range(VIZ_W):
        a = gl_px[x, y][3]
        if a > 10:
            t = a / 255.0
            v = int(45 * t + 235 * (1 - t))
            viz_px[x, y] = (v, v, v, 255)

# --- rectangles (fill then border) ---
for r in rects:
    rx0 = int(r["px0"] * SCALE)
    rx1 = int(r["px1"] * SCALE)
    ry0 = int(r["py0"] * SCALE)
    ry1 = int(r["py1"] * SCALE)
    rf, gf, bf = r["fill"]
    rb, gb, bb = r["border"]

    # semi-transparent fill
    ov = Image.new("RGBA", (VIZ_W, VIZ_H), (0, 0, 0, 0))
    ImageDraw.Draw(ov, "RGBA").rectangle([rx0, ry0, rx1, ry1], fill=(rf, gf, bf, 70))
    viz = Image.alpha_composite(viz, ov)

    # 2-px border
    d = ImageDraw.Draw(viz, "RGBA")
    d.rectangle([rx0,     ry0,     rx1,     ry1    ], outline=(rb, gb, bb, 240), width=2)
    d.rectangle([rx0 + 1, ry0 + 1, rx1 - 1, ry1 - 1], outline=(rb, gb, bb, 120), width=1)

    # label (centred inside rect)
    lx = (rx0 + rx1) // 2
    ly = (ry0 + ry1) // 2
    try:
        lf = ImageFont.truetype(FONT_PATH, size=13)
    except Exception:
        lf = ImageFont.load_default()
    ImageDraw.Draw(viz, "RGBA").text((lx, ly), r["label"],
                                     fill=(rb, gb, bb, 255), font=lf, anchor="mm")

# --- guide lines (midline and baseline) ---
ann = ImageDraw.Draw(viz, "RGBA")

if 0 <= midline_y_tight <= tight_h:
    ml_y = int(midline_y_tight * SCALE)
    ann.line([(0, ml_y), (VIZ_W, ml_y)], fill=(40, 160, 40, 200), width=2)
    try:
        gf = ImageFont.truetype(FONT_PATH, size=11)
    except Exception:
        gf = ImageFont.load_default()
    ann.text((3, ml_y - 14), "midline", fill=(40, 160, 40, 230), font=gf)

baseline_y_tight = baseline - tight_top
if 0 <= baseline_y_tight <= tight_h:
    bl_y = int(baseline_y_tight * SCALE)
    ann.line([(0, bl_y), (VIZ_W, bl_y)], fill=(170, 90, 20, 200), width=2)
    try:
        gf2 = ImageFont.truetype(FONT_PATH, size=11)
    except Exception:
        gf2 = ImageFont.load_default()
    ann.text((3, bl_y + 2), "baseline", fill=(170, 90, 20, 230), font=gf2)

# outer border
ann.rectangle([0, 0, VIZ_W - 1, VIZ_H - 1], outline=(0, 0, 0, 180), width=2)

# ---------------------------------------------------------------------------
# Legend strip below the glyph
# ---------------------------------------------------------------------------
LEGEND_H = 80
full = Image.new("RGB", (VIZ_W, VIZ_H + LEGEND_H), (255, 255, 255))
full.paste(viz.convert("RGB"), (0, 0))
leg  = ImageDraw.Draw(full)

try:
    lf_h  = ImageFont.truetype(FONT_PATH, size=14)
    lf_sm = ImageFont.truetype(FONT_PATH, size=11)
except Exception:
    lf_h  = ImageFont.load_default()
    lf_sm = lf_h

ly = VIZ_H + 6
leg.text((6, ly), "Proposed rectangles (code NOT changed yet):",
         fill=(0, 0, 0), font=lf_h)
ly += 18
for r in rects:
    rb, gb, bb = r["border"]
    leg.rectangle([6, ly + 2, 18, ly + 13], fill=r["fill"], outline=(rb, gb, bb))
    pw = r["px1"] - r["px0"]
    ph = r["py1"] - r["py0"]
    leg.text(
        (24, ly),
        f"{r['name']}  "
        f"x {r['minX']:.2f}–{r['maxX']:.2f}, y {r['minY']:.2f}–{r['maxY']:.2f}  "
        f"({pw:.0f}×{ph:.0f} px)",
        fill=(rb, gb, bb), font=lf_sm,
    )
    ly += 16

full.save(OUTPUT_PATH)
print()
print("=" * 62)
print(f"Saved → {OUTPUT_PATH}")
print("=" * 62)
