"""
Visualise PROPOSED new WaypointSection rectangles for letter 'e' (issue #149).

Full replacement of the old 5-section design (agent-authored in PR #141,
never grid-validated), which copied its closing section straight from a's
bowl-closing rectangle. a is a closed loop; e is not — e's real stroke ends
in an open curl (a short terminal hook) that never reaches that region,
so the old section 5 was unreachable and every correctly-drawn e scored 0%.

Measured against the real Andika 'e' glyph (see scripts/measure_e_glyph.py
and e_glyph_grid.png) using the same PIL/TemplateRasterizer-replica pipeline
as scripts/visualize_f_rects.py, updated for Andika.

New 7-section design:
  1, 2: tongue, split left to right
  3, 4: top-right -> top-middle (sweeping right to left across the top)
  5:    full left edge as one section, top-left through bottom-left
  6, 7: bottom-middle -> bottom-right (finish — the real open terminal hook,
        not a's closed-loop point)
"""

import os
from PIL import Image, ImageDraw, ImageFont

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
FONT_PATH = os.path.join(PROJECT_DIR, "fonts", "Andika-Regular.ttf")
OUTPUT_PATH = os.path.join(PROJECT_DIR, "e_proposed_sections.png")

FONT_SIZE = 120.0
LETTER = "e"

font = ImageFont.truetype(FONT_PATH, size=int(FONT_SIZE))
ascent_px, descent_px = font.getmetrics()
glyph_advance = font.getlength(LETTER)
flutter_canvas_w = int(glyph_advance)
flutter_canvas_h = ascent_px + descent_px

tmp_raw = Image.new("RGBA", (flutter_canvas_w + 20, flutter_canvas_h + 4), (0, 0, 0, 0))
ImageDraw.Draw(tmp_raw).text((0, 0), LETTER, font=font, fill=(0, 0, 0, 255))
tmp = tmp_raw.crop((0, 0, flutter_canvas_w, flutter_canvas_h))
TEMP_W, TEMP_H = flutter_canvas_w, flutter_canvas_h

px = tmp.load()
mask = [[px[c, r][3] > 10 for c in range(TEMP_W)] for r in range(TEMP_H)]
first_ink_row = next(r for r in range(TEMP_H) if any(mask[r]))
last_ink_row = max(r for r in range(TEMP_H) if any(mask[r]))
first_ink_col = next(c for c in range(TEMP_W) if any(mask[r][c] for r in range(TEMP_H)))
last_ink_col = max(c for c in range(TEMP_W) if any(mask[r][c] for r in range(TEMP_H)))
tight_w = last_ink_col - first_ink_col + 1
tight_h = last_ink_row - first_ink_row + 1

# ---------------------------------------------------------------------------
# Proposed sections (fractions of tightBounds)
# ---------------------------------------------------------------------------
rects = [
    dict(number=1, name="Tongue (left)", minX=0.00, maxX=0.48, minY=0.35, maxY=0.55,
         color=(220, 60, 60)),
    dict(number=2, name="Tongue (right)", minX=0.48, maxX=0.95, minY=0.35, maxY=0.55,
         color=(230, 140, 30)),
    dict(number=3, name="Top-right", minX=0.55, maxX=1.00, minY=0.00, maxY=0.30,
         color=(200, 180, 20)),
    dict(number=4, name="Top-middle", minX=0.10, maxX=0.60, minY=0.00, maxY=0.20,
         color=(90, 180, 60)),
    dict(number=5, name="Left edge (top-left thru bottom-left)", minX=0.00, maxX=0.35,
         minY=0.10, maxY=0.85, color=(40, 160, 160)),
    dict(number=6, name="Bottom-middle", minX=0.15, maxX=0.65, minY=0.80, maxY=1.00,
         color=(60, 110, 220)),
    dict(number=7, name="Bottom-right (finish)", minX=0.65, maxX=1.00, minY=0.65, maxY=0.85,
         color=(160, 70, 200)),
]

print("=" * 62)
print("Proposed 'e' section rectangles (fractions of tightBounds)")
print("=" * 62)
for r in rects:
    print(f"  {r['number']}. {r['name']:38s} "
          f"x[{r['minX']:.2f},{r['maxX']:.2f}) y[{r['minY']:.2f},{r['maxY']:.2f})")

# ---------------------------------------------------------------------------
# Render overlay
# ---------------------------------------------------------------------------
SCALE = 8
VIZ_W = tight_w * SCALE
VIZ_H = tight_h * SCALE

viz = Image.new("RGBA", (VIZ_W, VIZ_H), (245, 245, 245, 255))
glyph_crop = tmp.crop((first_ink_col, first_ink_row, last_ink_col + 1, last_ink_row + 1))
glyph_large = glyph_crop.resize((VIZ_W, VIZ_H), Image.NEAREST)
glyph_pixels = glyph_large.load()
viz_pixels = viz.load()
for y in range(VIZ_H):
    for x in range(VIZ_W):
        alpha = glyph_pixels[x, y][3]
        if alpha > 10:
            a = alpha / 255.0
            v = int(30 * a + 245 * (1 - a))
            viz_pixels[x, y] = (v, v, v, 255)

try:
    label_font = ImageFont.truetype(FONT_PATH, size=20)
except Exception:
    label_font = ImageFont.load_default()

for r in rects:
    rx0 = int(r["minX"] * VIZ_W)
    rx1 = int(r["maxX"] * VIZ_W)
    ry0 = int(r["minY"] * VIZ_H)
    ry1 = int(r["maxY"] * VIZ_H)
    rc, gc, bc = r["color"]

    overlay = Image.new("RGBA", (VIZ_W, VIZ_H), (0, 0, 0, 0))
    ov_draw = ImageDraw.Draw(overlay, "RGBA")
    ov_draw.rectangle([rx0, ry0, rx1, ry1], fill=(rc, gc, bc, 70))
    viz = Image.alpha_composite(viz, overlay)

    border_draw = ImageDraw.Draw(viz, "RGBA")
    for t in range(3):
        border_draw.rectangle([rx0 + t, ry0 + t, rx1 - t, ry1 - t], outline=(rc, gc, bc, 230))

    lx, ly = (rx0 + rx1) // 2, (ry0 + ry1) // 2
    label_draw = ImageDraw.Draw(viz, "RGBA")
    label_draw.text((lx, ly), str(r["number"]), fill=(rc, gc, bc, 255),
                     font=label_font, anchor="mm", stroke_width=2, stroke_fill=(255, 255, 255, 230))

border = ImageDraw.Draw(viz, "RGBA")
border.rectangle([0, 0, VIZ_W - 1, VIZ_H - 1], outline=(0, 0, 0, 200), width=2)

viz_rgb = viz.convert("RGB")

# Legend
LEGEND_H = 20 * len(rects) + 30
full = Image.new("RGB", (max(VIZ_W, 620), VIZ_H + LEGEND_H), (255, 255, 255))
full.paste(viz_rgb, (0, 0))
leg = ImageDraw.Draw(full)
try:
    leg_font = ImageFont.truetype(FONT_PATH, size=15)
except Exception:
    leg_font = ImageFont.load_default()

ly_start = VIZ_H + 8
leg.text((8, ly_start), "Proposed sections (expected sequence: 1→2→3→4→5→6→7):",
          fill=(0, 0, 0), font=leg_font)
ly_start += 20
for r in rects:
    rc, gc, bc = r["color"]
    leg.rectangle([8, ly_start + 2, 24, ly_start + 14], fill=(rc, gc, bc))
    leg.text((30, ly_start),
              f"{r['number']}. {r['name']}  "
              f"x {r['minX']:.2f}–{r['maxX']:.2f}, y {r['minY']:.2f}–{r['maxY']:.2f}",
              fill=(rc, gc, bc), font=leg_font)
    ly_start += 20

full.save(OUTPUT_PATH)
print()
print(f"Saved -> {OUTPUT_PATH}")
