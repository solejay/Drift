#!/usr/bin/env python3
"""
Render App Store marketing screenshots (1320x2868 px).

Composites a raw screenshot into a device-frame mockup with gradient
background, headline, and subtitle text.

Dependencies:
    pip install Pillow
    -- or --
    uv run --with Pillow render_screenshots.py ...

Usage:
    python render_screenshots.py \
        --input  screenshots/01-spending-overview.png \
        --output marketing/01-spending-overview.png \
        --headline "Your daily spending mirror" \
        --subtitle "See where your money quietly drifts"
"""

import argparse
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    sys.exit(
        "Pillow is required.  Install it with:\n"
        "  pip install Pillow\n"
        "or run this script via:\n"
        "  uv run --with Pillow render_screenshots.py ..."
    )

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
CANVAS_W, CANVAS_H = 1320, 2868

# Gradient colours (top -> bottom)
GRAD_TOP = (15, 21, 32)       # #0F1520
GRAD_BOTTOM = (26, 42, 68)    # #1A2A44

# Text colours
COLOR_HEADLINE = (255, 255, 255)   # #FFFFFF
COLOR_SUBTITLE = (122, 156, 198)   # #7A9CC6

# Device frame
FRAME_BORDER_COLOR = (61, 135, 199)  # #3D87C7
FRAME_BORDER_WIDTH = 3
FRAME_CORNER_RADIUS = 40

# Layout
HEADLINE_Y = 200
SUBTITLE_GAP = 40       # gap below headline baseline
DEVICE_TOP_PAD = 120     # padding between subtitle and device frame
DEVICE_SIDE_PAD = 80     # horizontal padding for the device frame
DEVICE_BOTTOM_PAD = 80   # padding at the bottom of the canvas

# Font sizes
HEADLINE_SIZE = 60
SUBTITLE_SIZE = 32


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _lerp(a: int, b: int, t: float) -> int:
    """Linear interpolation between two integers."""
    return int(a + (b - a) * t)


def make_gradient(width: int, height: int, top: tuple, bottom: tuple) -> Image.Image:
    """Create a vertical linear-gradient image."""
    img = Image.new("RGB", (width, height))
    draw = ImageDraw.Draw(img)
    for y in range(height):
        t = y / (height - 1)
        r = _lerp(top[0], bottom[0], t)
        g = _lerp(top[1], bottom[1], t)
        b = _lerp(top[2], bottom[2], t)
        draw.line([(0, y), (width, y)], fill=(r, g, b))
    return img


def load_font(families: list[str], size: int) -> ImageFont.FreeTypeFont:
    """Try to load a TrueType font from a list of common paths / names."""
    # macOS system font paths
    search_dirs = [
        Path("/System/Library/Fonts"),
        Path("/System/Library/Fonts/Supplemental"),
        Path("/Library/Fonts"),
        Path.home() / "Library" / "Fonts",
    ]

    for family in families:
        # Try the family name as given (Pillow may resolve it)
        for suffix in (".ttf", ".ttc", ".otf"):
            for d in search_dirs:
                candidate = d / f"{family}{suffix}"
                if candidate.exists():
                    try:
                        return ImageFont.truetype(str(candidate), size)
                    except Exception:
                        continue

    # Ultimate fallback -- Pillow's built-in bitmap font (not ideal but works)
    print(
        f"Warning: Could not find any of {families}; falling back to default font.",
        file=sys.stderr,
    )
    return ImageFont.load_default()


def draw_rounded_rect(
    draw: ImageDraw.ImageDraw,
    xy: tuple[int, int, int, int],
    radius: int,
    outline: tuple,
    width: int,
):
    """Draw a rounded rectangle outline."""
    draw.rounded_rectangle(xy, radius=radius, outline=outline, width=width)


def render(
    input_path: str,
    output_path: str,
    headline: str,
    subtitle: str,
) -> None:
    # ------------------------------------------------------------------
    # 1. Canvas with gradient background
    # ------------------------------------------------------------------
    canvas = make_gradient(CANVAS_W, CANVAS_H, GRAD_TOP, GRAD_BOTTOM)
    draw = ImageDraw.Draw(canvas)

    # ------------------------------------------------------------------
    # 2. Load fonts
    # ------------------------------------------------------------------
    serif_families = ["Georgia", "Times New Roman", "NewYork"]
    sans_families = ["Helvetica", "HelveticaNeue", "Arial", "SF-Pro-Display-Regular"]

    font_headline = load_font(serif_families, HEADLINE_SIZE)
    font_subtitle = load_font(sans_families, SUBTITLE_SIZE)

    # ------------------------------------------------------------------
    # 3. Draw headline (centered)
    # ------------------------------------------------------------------
    hl_bbox = draw.textbbox((0, 0), headline, font=font_headline)
    hl_w = hl_bbox[2] - hl_bbox[0]
    hl_h = hl_bbox[3] - hl_bbox[1]
    hl_x = (CANVAS_W - hl_w) // 2
    hl_y = HEADLINE_Y
    draw.text((hl_x, hl_y), headline, fill=COLOR_HEADLINE, font=font_headline)

    # ------------------------------------------------------------------
    # 4. Draw subtitle (centered, below headline)
    # ------------------------------------------------------------------
    st_bbox = draw.textbbox((0, 0), subtitle, font=font_subtitle)
    st_w = st_bbox[2] - st_bbox[0]
    st_x = (CANVAS_W - st_w) // 2
    st_y = hl_y + hl_h + SUBTITLE_GAP
    draw.text((st_x, st_y), subtitle, fill=COLOR_SUBTITLE, font=font_subtitle)

    st_bottom = st_y + (st_bbox[3] - st_bbox[1])

    # ------------------------------------------------------------------
    # 5. Compute device frame region
    # ------------------------------------------------------------------
    frame_top = st_bottom + DEVICE_TOP_PAD
    frame_left = DEVICE_SIDE_PAD
    frame_right = CANVAS_W - DEVICE_SIDE_PAD
    frame_bottom = CANVAS_H - DEVICE_BOTTOM_PAD

    frame_inner_w = (frame_right - frame_left) - 2 * FRAME_BORDER_WIDTH
    frame_inner_h = (frame_bottom - frame_top) - 2 * FRAME_BORDER_WIDTH

    # ------------------------------------------------------------------
    # 6. Load, scale, and paste the raw screenshot
    # ------------------------------------------------------------------
    screenshot = Image.open(input_path).convert("RGBA")
    sc_w, sc_h = screenshot.size

    # Scale to fit within the inner frame, preserving aspect ratio
    scale = min(frame_inner_w / sc_w, frame_inner_h / sc_h)
    new_w = int(sc_w * scale)
    new_h = int(sc_h * scale)
    screenshot = screenshot.resize((new_w, new_h), Image.LANCZOS)

    # Center the screenshot inside the frame
    paste_x = frame_left + FRAME_BORDER_WIDTH + (frame_inner_w - new_w) // 2
    paste_y = frame_top + FRAME_BORDER_WIDTH + (frame_inner_h - new_h) // 2

    # Create a rounded-rect mask so the screenshot corners match the frame
    inner_radius = max(FRAME_CORNER_RADIUS - FRAME_BORDER_WIDTH, 0)
    mask = Image.new("L", (new_w, new_h), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle(
        (0, 0, new_w - 1, new_h - 1),
        radius=inner_radius,
        fill=255,
    )
    canvas.paste(screenshot, (paste_x, paste_y), mask)

    # ------------------------------------------------------------------
    # 7. Draw the device frame (rounded rectangle border)
    # ------------------------------------------------------------------
    draw_rounded_rect(
        draw,
        (frame_left, frame_top, frame_right, frame_bottom),
        radius=FRAME_CORNER_RADIUS,
        outline=FRAME_BORDER_COLOR,
        width=FRAME_BORDER_WIDTH,
    )

    # ------------------------------------------------------------------
    # 8. Save
    # ------------------------------------------------------------------
    out = Path(output_path)
    out.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(str(out), "PNG")
    print(f"Saved: {out}")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Render an App Store marketing screenshot (1320x2868 px)."
    )
    parser.add_argument(
        "--input",
        required=True,
        help="Path to the raw screenshot PNG.",
    )
    parser.add_argument(
        "--output",
        required=True,
        help="Path for the output marketing screenshot PNG.",
    )
    parser.add_argument(
        "--headline",
        required=True,
        help="Headline text displayed above the device frame.",
    )
    parser.add_argument(
        "--subtitle",
        required=True,
        help="Subtitle text displayed below the headline.",
    )
    args = parser.parse_args()

    render(
        input_path=args.input,
        output_path=args.output,
        headline=args.headline,
        subtitle=args.subtitle,
    )


if __name__ == "__main__":
    main()
