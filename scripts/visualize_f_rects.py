"""
Visualise the StrokeStartScorer rectangles for letter 'f' at true pixel size.

Reproduces Flutter's TemplateRasterizer pipeline in Python:
  1. Render Comic Neue 'f' at fontSize=120 into an offscreen bitmap.
  2. Compute tightBounds (first/last inked pixel on both axes).
  3. Convert f's two startRect fractions to pixel coords within tightBounds.
  4. Render glyph + rectangles + observed stroke-start dots into one PNG.

Flutter positioning:
  canvasWidth  = 400
  canvasHeight = 600
  fontFamily   = 'Comic Neue'
  fontSize     = 120

  Guidelines.fromFont:
    ascenderRatio  = 0.685  → ascenderHeight = 82.2 px
    descenderRatio = 0.193  → descenderDepth = 23.16 px
    totalHeight    = 105.36 px
    baseline       = (600 - 105.36) / 2 + 82.2 = 329.52 px
    ascenderLine   = 329.52 - 82.2  = 247.32 px
    midline        = 329.52 - 59.16 = 270.36 px

  TemplateRasterizer.rasterize:
    baselineOffset = painter.computeDistanceToActualBaseline(alphabetic)
                   ≈ the font's ascent value at fontSize=120
    x = (400 - painter.width) / 2
    y = baseline - baselineOffset
    bounds = Rect(x, y, painter.width, painter.height)

  buildScoreResult passes tightBounds as formationBounds.

PIL replication note:
  PIL's ImageFont.truetype(size=120) treats 'size' as point size at 96 DPI by
  default (so 1 point = 1.333... px). We want the glyph to occupy the same
  logical-pixel size as Flutter's fontSize=120, so we pass size=120 and scale
  at 1 pt = 1 px (72 DPI convention matches Flutter's dp=pt assumption).
  We use font.getbbox() to find the glyph's tight bounding box.
"""

import os
from PIL import Image, ImageDraw, ImageFont

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
FONT_PATH = os.path.join(PROJECT_DIR, "fonts", "ComicNeue-Regular.ttf")
OUTPUT_PATH = os.path.join(PROJECT_DIR, "f_start_rects.png")

# ---------------------------------------------------------------------------
# Flutter constants
# ---------------------------------------------------------------------------
FONT_SIZE = 120.0
CANVAS_WIDTH = 400.0
CANVAS_HEIGHT = 600.0

ASCENDER_RATIO  = 0.685
DESCENDER_RATIO = 0.193
X_HEIGHT_RATIO  = 0.493

ascender_height = FONT_SIZE * ASCENDER_RATIO    # 82.2
descender_depth = FONT_SIZE * DESCENDER_RATIO   # 23.16
total_height    = ascender_height + descender_depth  # 105.36
baseline        = (CANVAS_HEIGHT - total_height) / 2 + ascender_height  # 329.52
midline         = baseline - FONT_SIZE * X_HEIGHT_RATIO  # 270.36

# ---------------------------------------------------------------------------
# Render 'f' with PIL at size=120 (1 pt = 1 px, matching Flutter's dp)
# ---------------------------------------------------------------------------
font = ImageFont.truetype(FONT_PATH, size=int(FONT_SIZE))

# Get the glyph metrics.
# font.getmetrics() -> (ascent, descent) in pixels at this size.
# font.getbbox(text)  -> (left, top, right, bottom) relative to drawing origin.
#   'top' is negative when ink is above the baseline.
# font.getlength(text) -> advance width in pixels.

ascent_px, descent_px = font.getmetrics()

# Glyph tight bounding box: (left_bearing, top-above-baseline, right, bottom)
glyph_bbox = font.getbbox("f")   # (left, top, right, bottom) in PIL coords
# PIL bbox convention: top is negative for ink above the baseline anchor point.
# The anchor point in PIL is the TOP-LEFT of the em square when using
# ImageDraw.text(..., anchor="la") (left-baseline anchor).
# But getbbox with no anchor returns offsets from the top-left of the
# character cell (i.e. measured from the top of the ascent box).

glyph_width_advance = font.getlength("f")

# Flutter's canvas is EXACTLY painter.width.ceil() × painter.height.ceil().
# Clip to this so tightBounds matches Flutter's computation.
flutter_canvas_w = int(glyph_width_advance)  # math.ceil(painter.width)
flutter_canvas_h = ascent_px + descent_px    # math.ceil(painter.height)

# Render slightly wider to capture any bleed, then crop to Flutter's size.
RENDER_W = flutter_canvas_w + 20
RENDER_H = flutter_canvas_h + 4
tmp_raw = Image.new("RGBA", (RENDER_W, RENDER_H), (0, 0, 0, 0))
draw = ImageDraw.Draw(tmp_raw)
# Draw 'f' at the PIL default position (0,0), which places the glyph
# origin at top-left of the em box (matching Flutter's painter.paint(canvas, Offset.zero)).
draw.text((0, 0), "f", font=font, fill=(0, 0, 0, 255))

# Crop to Flutter's exact canvas dimensions.
tmp = tmp_raw.crop((0, 0, flutter_canvas_w, flutter_canvas_h))
TEMP_W, TEMP_H = flutter_canvas_w, flutter_canvas_h

# Convert to boolean mask (True = ink).
pixels = tmp.load()
mask = [
    [pixels[col, row][3] > 10 for col in range(TEMP_W)]
    for row in range(TEMP_H)
]

# Find tightBounds (matching TemplateRasterResult.tightBounds):
# first/last ink row, first/last ink col.
first_ink_row = None
last_ink_row  = None
for row in range(TEMP_H):
    if any(mask[row]):
        if first_ink_row is None:
            first_ink_row = row
        last_ink_row = row

first_ink_col = None
last_ink_col  = None
for col in range(TEMP_W):
    if any(mask[row][col] for row in range(TEMP_H)):
        if first_ink_col is None:
            first_ink_col = col
        last_ink_col = col

tight_h = last_ink_row  - first_ink_row + 1   # height in px
tight_w = last_ink_col  - first_ink_col + 1   # width in px

print("=" * 60)
print("STEP 1 — f's tightBounds")
print("=" * 60)
print(f"  Rendered glyph box: {TEMP_W} × {TEMP_H} px")
print(f"  first_ink_row = {first_ink_row},  last_ink_row = {last_ink_row}")
print(f"  first_ink_col = {first_ink_col},  last_ink_col = {last_ink_col}")
print(f"  tightBounds width  = {tight_w} px")
print(f"  tightBounds height = {tight_h} px")
print()

# Flutter's bounds.left / bounds.top are the canvas-space offsets.
# We do not need the absolute canvas position for the fraction math —
# tightBounds fractions are relative to tightBounds itself.
# But let's compute them for completeness.
painter_width  = glyph_width_advance
painter_height = float(ascent_px + descent_px)
canvas_x = (CANVAS_WIDTH - painter_width) / 2
# baselineOffset ≈ ascent_px in PIL (distance from text-box top to baseline)
canvas_y = baseline - ascent_px

tight_left = canvas_x + first_ink_col
tight_top  = canvas_y + first_ink_row

print(f"  Flutter canvas position:")
print(f"    bounds.left = {canvas_x:.1f}, bounds.top = {canvas_y:.1f}")
print(f"    bounds.width = {painter_width:.1f}, bounds.height = {painter_height:.1f}")
print(f"  tightBounds (canvas coords):")
print(f"    left  = {tight_left:.1f}")
print(f"    top   = {tight_top:.1f}")
print(f"    right = {tight_left + tight_w:.1f}")
print(f"    bottom = {tight_top + tight_h:.1f}")
print()

# ---------------------------------------------------------------------------
# STEP 2 — Convert f startRect fractions to pixels within tightBounds
# ---------------------------------------------------------------------------
# Stroke 0 (stem):    minX=0.60, maxX=0.90, minY=0.00, maxY=0.30
# Stroke 1 (crossbar):minX=0.00, maxX=0.20, minY=0.44, maxY=0.56

rects = [
    dict(name="Stroke 0 — stem",    minX=0.60, maxX=0.90, minY=0.00, maxY=0.30,
         color=(255, 80, 80),  label_short="STEM"),
    dict(name="Stroke 1 — crossbar", minX=0.00, maxX=0.20, minY=0.44, maxY=0.56,
         color=(80, 160, 255), label_short="XBAR"),
]

print("=" * 60)
print("STEP 2 — Rectangle pixel positions (within tightBounds)")
print("=" * 60)

for r in rects:
    px0 = r["minX"] * tight_w
    px1 = r["maxX"] * tight_w
    py0 = r["minY"] * tight_h
    py1 = r["maxY"] * tight_h
    r["px0"], r["px1"], r["py0"], r["py1"] = px0, px1, py0, py1
    print(f"\n  {r['name']}  ({int(r['minX']*100)}–{int(r['maxX']*100)}% x, "
          f"{int(r['minY']*100)}–{int(r['maxY']*100)}% y)")
    print(f"    pixel x-range: {px0:.1f} – {px1:.1f}  (width = {px1-px0:.1f} px)")
    print(f"    pixel y-range: {py0:.1f} – {py1:.1f}  (height = {py1-py0:.1f} px)")

# ---------------------------------------------------------------------------
# STEP 3+4 — Build the visualisation image
# ---------------------------------------------------------------------------
# Scale factor: render at 4× for clarity, annotate in scaled space.
SCALE = 6
VIZ_W = tight_w * SCALE
VIZ_H = tight_h * SCALE

viz = Image.new("RGBA", (VIZ_W, VIZ_H), (240, 240, 240, 255))

# Paste the actual glyph pixels (cropped to tightBounds) as the background.
glyph_crop = tmp.crop((first_ink_col, first_ink_row,
                        last_ink_col + 1, last_ink_row + 1))
glyph_large = glyph_crop.resize((VIZ_W, VIZ_H), Image.NEAREST)

# Compose glyph ink (black) over the grey background.
# We'll turn ink pixels dark and keep the background grey.
viz_draw = ImageDraw.Draw(viz, "RGBA")

# Draw glyph ink as very dark grey so rectangles stay visible on top.
glyph_rgba = glyph_large.convert("RGBA")
glyph_pixels = glyph_rgba.load()
viz_pixels = viz.load()
for y in range(VIZ_H):
    for x in range(VIZ_W):
        alpha = glyph_pixels[x, y][3]
        if alpha > 10:
            # Blend dark ink with grey background
            ink_alpha = alpha / 255.0
            r = int(50  * ink_alpha + 220 * (1 - ink_alpha))
            g = int(50  * ink_alpha + 220 * (1 - ink_alpha))
            b = int(50  * ink_alpha + 220 * (1 - ink_alpha))
            viz_pixels[x, y] = (r, g, b, 255)

# Draw rectangles with semi-transparent fill and solid border.
for r in rects:
    rx0 = int(r["px0"] * SCALE)
    rx1 = int(r["px1"] * SCALE)
    ry0 = int(r["py0"] * SCALE)
    ry1 = int(r["py1"] * SCALE)
    rc, gc, bc = r["color"]

    # Semi-transparent fill layer.
    overlay = Image.new("RGBA", (VIZ_W, VIZ_H), (0, 0, 0, 0))
    ov_draw = ImageDraw.Draw(overlay, "RGBA")
    ov_draw.rectangle([rx0, ry0, rx1, ry1], fill=(rc, gc, bc, 60))
    viz = Image.alpha_composite(viz, overlay)

    # Solid border.
    border_draw = ImageDraw.Draw(viz, "RGBA")
    for thickness in range(3):
        border_draw.rectangle(
            [rx0 + thickness, ry0 + thickness, rx1 - thickness, ry1 - thickness],
            outline=(rc, gc, bc, 220),
        )

    # Label inside rectangle.
    lx = (rx0 + rx1) // 2
    ly = (ry0 + ry1) // 2
    lbl = r["label_short"]
    try:
        lbl_font = ImageFont.truetype(FONT_PATH, size=14)
    except Exception:
        lbl_font = ImageFont.load_default()
    label_draw = ImageDraw.Draw(viz, "RGBA")
    label_draw.text((lx, ly), lbl, fill=(rc, gc, bc, 255), font=lbl_font,
                    anchor="mm")

# ---------------------------------------------------------------------------
# STEP 5 — Observed stroke-start dots
# ---------------------------------------------------------------------------
# Stem starts:    66–83% x,   5–7% y
# Crossbar starts: 9% x,    29–31% y
#
# The observed percentages are relative to tightBounds (that's how the scorer
# maps them — formationBounds = tightBounds).

observed_points = [
    dict(name="Stem start (observed)",    rx_lo=0.66, rx_hi=0.83, ry_lo=0.05, ry_hi=0.07,
         color=(200, 80, 0)),
    dict(name="Crossbar start (observed)", rx_lo=0.09, rx_hi=0.09, ry_lo=0.29, ry_hi=0.31,
         color=(0, 100, 220)),
]

dot_draw = ImageDraw.Draw(viz, "RGBA")
DOT_R = 6

print()
print("=" * 60)
print("STEP 5 — Observed stroke-start dots (pixel positions)")
print("=" * 60)

for op in observed_points:
    # Use midpoint of range as the dot centre.
    rx_mid = (op["rx_lo"] + op["rx_hi"]) / 2
    ry_mid = (op["ry_lo"] + op["ry_hi"]) / 2
    px = rx_mid * tight_w * SCALE
    py = ry_mid * tight_h * SCALE
    rc, gc, bc = op["color"]

    print(f"\n  {op['name']}")
    print(f"    rx_mid = {rx_mid*100:.1f}%  →  pixel x = {rx_mid*tight_w:.1f}")
    print(f"    ry_mid = {ry_mid*100:.1f}%  →  pixel y = {ry_mid*tight_h:.1f}")

    # Draw a cross-hair dot.
    dot_draw.ellipse(
        [px - DOT_R, py - DOT_R, px + DOT_R, py + DOT_R],
        fill=(rc, gc, bc, 230), outline=(255, 255, 255, 200), width=2
    )

    # If a range was given (not a single point), also draw the extremes.
    for rx, ry in [(op["rx_lo"], op["ry_lo"]), (op["rx_hi"], op["ry_hi"])]:
        if abs(rx - rx_mid) > 0.001 or abs(ry - ry_mid) > 0.001:
            px2 = rx * tight_w * SCALE
            py2 = ry * tight_h * SCALE
            dot_draw.ellipse(
                [px2 - 4, py2 - 4, px2 + 4, py2 + 4],
                fill=(rc, gc, bc, 140), outline=(255, 255, 255, 150), width=1
            )

# ---------------------------------------------------------------------------
# Add tightBounds border and axis labels
# ---------------------------------------------------------------------------
border = ImageDraw.Draw(viz, "RGBA")
border.rectangle([0, 0, VIZ_W - 1, VIZ_H - 1], outline=(0, 0, 0, 200), width=2)

# Add midline marker (y = xHeight fraction within tightBounds)
# xHeight = baseline - midline; tightBounds.top is near ascenderLine.
# Proportion of midline within tightBounds:
#   tight_top relative to canvas: canvas_y + first_ink_row
#   midline at: baseline - xHeight = 270.36
#   midline within tight = midline - tight_top
midline_within_tight = midline - tight_top
if 0 <= midline_within_tight <= tight_h:
    ml_y = int(midline_within_tight * SCALE)
    border.line([(0, ml_y), (VIZ_W, ml_y)], fill=(100, 180, 100, 180), width=2)
    border.text((4, ml_y - 14), "midline", fill=(100, 180, 100, 230),
                font=ImageFont.load_default())

baseline_within_tight = baseline - tight_top
if 0 <= baseline_within_tight <= tight_h:
    bl_y = int(baseline_within_tight * SCALE)
    border.line([(0, bl_y), (VIZ_W, bl_y)], fill=(180, 100, 30, 180), width=2)
    border.text((4, bl_y + 2), "baseline", fill=(180, 100, 30, 230),
                font=ImageFont.load_default())

# Convert back to RGB for saving.
viz_rgb = viz.convert("RGB")

# ---------------------------------------------------------------------------
# Add a legend below the glyph
# ---------------------------------------------------------------------------
LEGEND_H = 120
full = Image.new("RGB", (VIZ_W, VIZ_H + LEGEND_H), (255, 255, 255))
full.paste(viz_rgb, (0, 0))
leg = ImageDraw.Draw(full)

try:
    leg_font = ImageFont.truetype(FONT_PATH, size=15)
    leg_font_sm = ImageFont.truetype(FONT_PATH, size=12)
except Exception:
    leg_font = ImageFont.load_default()
    leg_font_sm = leg_font

ly_start = VIZ_H + 8
leg.text((8, ly_start), "Legend:", fill=(0, 0, 0), font=leg_font)
ly_start += 20

# Rectangles
for r in rects:
    rc, gc, bc = r["color"]
    leg.rectangle([8, ly_start + 2, 24, ly_start + 14], fill=(rc, gc, bc))
    leg.text((30, ly_start),
             f"{r['name']}  "
             f"x {int(r['minX']*100)}–{int(r['maxX']*100)}%,"
             f" y {int(r['minY']*100)}–{int(r['maxY']*100)}%  "
             f"({r['px1']-r['px0']:.0f}×{r['py1']-r['py0']:.0f} px)",
             fill=(rc, gc, bc), font=leg_font_sm)
    ly_start += 18

# Dots
for op in observed_points:
    rc, gc, bc = op["color"]
    leg.ellipse([8, ly_start + 2, 20, ly_start + 14],
                fill=(rc, gc, bc), outline=(0, 0, 0))
    rx_mid = (op["rx_lo"] + op["rx_hi"]) / 2
    ry_mid = (op["ry_lo"] + op["ry_hi"]) / 2
    leg.text((30, ly_start),
             f"{op['name']}  ({rx_mid*100:.0f}%, {ry_mid*100:.0f}%)",
             fill=(rc, gc, bc), font=leg_font_sm)
    ly_start += 18

full.save(OUTPUT_PATH)
print()
print("=" * 60)
print(f"Image saved → {OUTPUT_PATH}")
print("=" * 60)
