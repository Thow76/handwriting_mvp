"""
Render the real Andika 'e' glyph and overlay a 10% fraction grid, so its
section rectangles can be measured against actual ink instead of guessed.

Reproduces Flutter's TemplateRasterizer pipeline in Python (same approach as
scripts/visualize_f_rects.py, updated for the Andika font now used by the
app — see lib/drawing_canvas.dart's _fontFamily and
lib/models/guidelines.dart's Guidelines.fromFont ratios):

  1. Render Andika 'e' at fontSize=120 into an offscreen bitmap sized to the
     glyph's advance box (painter.width x (ascent+descent)), matching
     TemplateRasterizer.rasterize.
  2. Compute tightBounds (first/last inked pixel on both axes) exactly as
     TemplateRasterResult.tightBounds does.
  3. Render the glyph enlarged with a 10% fraction grid so section
     boundaries can be read off directly against the ink.

Fraction values (section rectangles) are relative to tightBounds and are
therefore independent of the app's runtime canvasWidth/canvasHeight, which
only affect how the glyph is centred on screen, not its own rendered size at
fontSize=120.
"""

import os
from PIL import Image, ImageDraw, ImageFont

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
FONT_PATH = os.path.join(PROJECT_DIR, "fonts", "Andika-Regular.ttf")
OUTPUT_PATH = os.path.join(PROJECT_DIR, "e_glyph_grid.png")

FONT_SIZE = 120.0
LETTER = "e"

font = ImageFont.truetype(FONT_PATH, size=int(FONT_SIZE))
ascent_px, descent_px = font.getmetrics()
glyph_advance = font.getlength(LETTER)

flutter_canvas_w = int(glyph_advance)       # painter.width.ceil()
flutter_canvas_h = ascent_px + descent_px   # painter.height.ceil()

RENDER_W = flutter_canvas_w + 20
RENDER_H = flutter_canvas_h + 4
tmp_raw = Image.new("RGBA", (RENDER_W, RENDER_H), (0, 0, 0, 0))
ImageDraw.Draw(tmp_raw).text((0, 0), LETTER, font=font, fill=(0, 0, 0, 255))
tmp = tmp_raw.crop((0, 0, flutter_canvas_w, flutter_canvas_h))
TEMP_W, TEMP_H = flutter_canvas_w, flutter_canvas_h

pixels = tmp.load()
mask = [
    [pixels[col, row][3] > 10 for col in range(TEMP_W)]
    for row in range(TEMP_H)
]

first_ink_row = next(r for r in range(TEMP_H) if any(mask[r]))
last_ink_row = max(r for r in range(TEMP_H) if any(mask[r]))
first_ink_col = next(
    c for c in range(TEMP_W) if any(mask[r][c] for r in range(TEMP_H))
)
last_ink_col = max(
    c for c in range(TEMP_W) if any(mask[r][c] for r in range(TEMP_H))
)

tight_w = last_ink_col - first_ink_col + 1
tight_h = last_ink_row - first_ink_row + 1

print("=" * 60)
print("e's tightBounds (pixels, at fontSize=120)")
print("=" * 60)
print(f"  tight_w = {tight_w}, tight_h = {tight_h}")
print(f"  first_ink_row={first_ink_row} last_ink_row={last_ink_row}")
print(f"  first_ink_col={first_ink_col} last_ink_col={last_ink_col}")

# ---------------------------------------------------------------------------
# Ink extent helpers, used to read off boundaries at specific fractions.
# ---------------------------------------------------------------------------


def ink_cols_in_row_band(y0_frac, y1_frac):
    """Return (min_col_frac, max_col_frac) of ink within a y-fraction band."""
    r0 = first_ink_row + int(y0_frac * tight_h)
    r1 = first_ink_row + int(y1_frac * tight_h)
    cols = [
        c
        for r in range(r0, min(r1 + 1, TEMP_H))
        for c in range(first_ink_col, last_ink_col + 1)
        if mask[r][c]
    ]
    if not cols:
        return None
    return (
        (min(cols) - first_ink_col) / tight_w,
        (max(cols) - first_ink_col) / tight_w,
    )


def ink_rows_in_col_band(x0_frac, x1_frac):
    """Return (min_row_frac, max_row_frac) of ink within an x-fraction band."""
    c0 = first_ink_col + int(x0_frac * tight_w)
    c1 = first_ink_col + int(x1_frac * tight_w)
    rows = [
        r
        for c in range(c0, min(c1 + 1, TEMP_W))
        for r in range(first_ink_row, last_ink_row + 1)
        if mask[r][c]
    ]
    if not rows:
        return None
    return (
        (min(rows) - first_ink_row) / tight_h,
        (max(rows) - first_ink_row) / tight_h,
    )


print()
print("=" * 60)
print("Ink probes")
print("=" * 60)
for y0, y1 in [(0.0, 0.1), (0.1, 0.2), (0.3, 0.4), (0.4, 0.5), (0.5, 0.6),
               (0.6, 0.7), (0.8, 0.9), (0.9, 1.0)]:
    r = ink_cols_in_row_band(y0, y1)
    print(f"  y[{y0:.1f},{y1:.1f}) -> x ink range: {r}")

print()
for x0, x1 in [(0.0, 0.1), (0.1, 0.2), (0.4, 0.5), (0.5, 0.6),
               (0.8, 0.9), (0.9, 1.0)]:
    r = ink_rows_in_col_band(x0, x1)
    print(f"  x[{x0:.1f},{x1:.1f}) -> y ink range: {r}")

# ---------------------------------------------------------------------------
# Build the grid overlay image.
# ---------------------------------------------------------------------------
SCALE = 8
VIZ_W = tight_w * SCALE
VIZ_H = tight_h * SCALE

viz = Image.new("RGBA", (VIZ_W, VIZ_H), (245, 245, 245, 255))
glyph_crop = tmp.crop(
    (first_ink_col, first_ink_row, last_ink_col + 1, last_ink_row + 1)
)
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

grid_draw = ImageDraw.Draw(viz, "RGBA")
try:
    label_font = ImageFont.truetype(FONT_PATH, size=13)
except Exception:
    label_font = ImageFont.load_default()

for i in range(1, 10):
    frac = i / 10
    x = int(frac * VIZ_W)
    grid_draw.line([(x, 0), (x, VIZ_H)], fill=(80, 140, 220, 140), width=1)
    grid_draw.text((x + 2, 2), f"{int(frac * 100)}%", fill=(40, 90, 170, 230),
                    font=label_font)
    y = int(frac * VIZ_H)
    grid_draw.line([(0, y), (VIZ_W, y)], fill=(220, 100, 80, 140), width=1)
    grid_draw.text((2, y + 2), f"{int(frac * 100)}%", fill=(170, 60, 40, 230),
                    font=label_font)

grid_draw.rectangle([0, 0, VIZ_W - 1, VIZ_H - 1], outline=(0, 0, 0, 200), width=2)

viz.convert("RGB").save(OUTPUT_PATH)
print()
print(f"Saved grid overlay -> {OUTPUT_PATH}")
