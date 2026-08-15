"""Builds a logo variant by recolouring the block texture of an existing one.

Several Minecraft blocks are the same speckled stone in a different colour, so
a variant for one of those is a recolour rather than a new drawing. The prompt
glyph is left alone: it is near-grey, and the texture is not, which is enough
to tell them apart without hand-marking pixels.

    cd docs/logo
    python recolor_variant.py

Writes into variants/. Existing files are overwritten, so it is safe to rerun
after changing a ramp.
"""

import os

from PIL import Image

SOURCE = os.path.join("variants", "dirt.png")

# Darkest and lightest tone of each block. The shades in between are taken from
# the source's own brightness, which is what keeps the speckle pattern.
RAMPS = {
    # Gold is a flatter block in game, so its ramp is deliberately short: the
    # same speckle at full strength reads as sand.
    "gold": ((0xC2, 0x9E, 0x1A), (0xFA, 0xF0, 0x62)),
    # Stone is speckled exactly like this, so it takes the full contrast.
    "stone": ((0x5E, 0x5E, 0x5E), (0xA8, 0xA8, 0xA8)),
}


def luminance(pixel):
    r, g, b = pixel[:3]
    return 0.299 * r + 0.587 * g + 0.114 * b


def is_texture(pixel):
    """True for block pixels, false for the glyph drawn on top of them.

    The glyph is white or near-grey; every texture tone is saturated, so the
    spread between the channels separates the two cleanly.
    """
    r, g, b = pixel[:3]
    return max(r, g, b) - min(r, g, b) > 25


def recolor(image, dark, light):
    # Read through tobytes rather than getdata, which Pillow has deprecated in
    # favour of a method too new to rely on here.
    raw = image.tobytes()
    pixels = [tuple(raw[i:i + 4]) for i in range(0, len(raw), 4)]
    texture = [p for p in pixels if is_texture(p)]
    low = min(luminance(p) for p in texture)
    high = max(luminance(p) for p in texture)
    span = high - low or 1

    out = []
    for pixel in pixels:
        if not is_texture(pixel):
            out.append(pixel)
            continue
        t = (luminance(pixel) - low) / span
        out.append(
            (
                round(dark[0] + (light[0] - dark[0]) * t),
                round(dark[1] + (light[1] - dark[1]) * t),
                round(dark[2] + (light[2] - dark[2]) * t),
                pixel[3],
            )
        )

    return Image.frombytes(
        "RGBA", image.size, bytes(channel for pixel in out for channel in pixel)
    )


def main():
    source = Image.open(SOURCE).convert("RGBA")
    for name, (dark, light) in RAMPS.items():
        path = os.path.join("variants", f"{name}.png")
        recolor(source, dark, light).save(path)
        print(f"wrote {path}")
    source.close()


if __name__ == "__main__":
    main()
