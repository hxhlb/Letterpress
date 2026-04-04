#!/usr/bin/env python3
"""Generate a Letterpress-inspired dot grid background as a PNG image."""
from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw


@dataclass
class GridStyle:
    rows: int = 10
    columns: int = 10
    spacing: float = 12.0
    dot_diameter: float = 4.0
    opacity: float = 0.3
    scale: int = 1
    background_color: tuple[int, int, int, int] = (0, 0, 0, 255)
    dot_color: tuple[int, int, int] = (255, 255, 255)


def craft_texture(style: GridStyle) -> Image.Image:
    """Build a seamless dot-grid tile (last row/column omitted, gap preserved)."""
    spacing_px = style.spacing * style.scale
    dot_px = style.dot_diameter * style.scale

    draw_columns = max(style.columns - 1, 1)
    draw_rows = max(style.rows - 1, 1)

    image_width = int(round(spacing_px * draw_columns))
    image_height = int(round(spacing_px * draw_rows))

    image = Image.new("RGBA", (image_width, image_height), style.background_color)
    draw = ImageDraw.Draw(image)

    radius = dot_px / 2
    start_x = radius
    start_y = radius
    alpha = max(0, min(255, int(style.opacity * 255)))

    for row in range(draw_rows):
        center_y = start_y + row * spacing_px
        for column in range(draw_columns):
            center_x = start_x + column * spacing_px
            bounds = (
                center_x - radius,
                center_y - radius,
                center_x + radius,
                center_y + radius,
            )
            draw.ellipse(bounds, fill=(*style.dot_color, alpha))
    return image


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=Path("dot_grid_texture.png"), help="Where to write the PNG file")
    parser.add_argument("--rows", type=int, default=10, help="Row spacing steps (drawn rows = value - 1)")
    parser.add_argument("--columns", type=int, default=10, help="Column spacing steps (drawn columns = value - 1)")
    parser.add_argument("--spacing", type=float, default=12.0, help="Distance between dot centers in pixels")
    parser.add_argument("--dot-size", type=float, default=4.0, help="Diameter of each dot in pixels")
    parser.add_argument("--opacity", type=float, default=0.3, help="Dot alpha as a float between 0 and 1")
    parser.add_argument("--scale", type=int, choices=(1, 2, 3), default=1, help="Output scale factor (1x, 2x, 3x)")
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    style = GridStyle(
        rows=args.rows,
        columns=args.columns,
        spacing=args.spacing,
        dot_diameter=args.dot_size,
        opacity=args.opacity,
        scale=args.scale,
    )

    image = craft_texture(style)
    output_path = args.output.expanduser()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    image.save(output_path, format="PNG")
    print(f"Generated texture saved to {output_path}")


if __name__ == "__main__":
    main()
