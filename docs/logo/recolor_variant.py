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
WHITE = (0xFF, 0xFF, 0xFF)
DARK = (0x1A, 0x14, 0x0A)

# dark tone, light tone, glyph. Pass None for the glyph to have it chosen by
# contrast, which is the safe default for a new ramp.
RAMPS = {
    # Gold is a flatter block in game, so its ramp is deliberately short: the
    # same speckle at full strength reads as sand. The glyph is dark because
    # the white one it inherited from dirt vanished against yellow.
    "gold": ((0xC2, 0x9E, 0x1A), (0xFA, 0xF0, 0x62), DARK),
    # Stone is speckled exactly like this, so it takes the full contrast. Its
    # glyph is white by choice rather than by the contrast rule, which would
    # pick dark here.
    "stone": ((0x5E, 0x5E, 0x5E), (0xA8, 0xA8, 0xA8), WHITE),
}


def luminance(pixel):
    r, g, b = pixel[:3]
    return 0.299 * r + 0.587 * g + 0.114 * b


def relative_luminance(color):
    """WCAG relative luminance, for picking a glyph that can be read."""
    channels = []
    for c in color[:3]:
        c /= 255
        channels.append(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4)
    return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]


def glyph_color(dark, light):
    """Black or white, whichever the block can actually be read against.

    The source glyph is white, which works on dirt and disappears on gold. The
    choice is made per ramp rather than fixed so a new ramp cannot repeat that.
    """
    mid = tuple((d + l) // 2 for d, l in zip(dark, light))
    contrast_white = 1.05 / (relative_luminance(mid) + 0.05)
    contrast_black = (relative_luminance(mid) + 0.05) / 0.05
    return (0xFF, 0xFF, 0xFF) if contrast_white >= contrast_black else (0x1A, 0x14, 0x0A)


def is_texture(pixel):
    """True for block pixels, false for the glyph drawn on top of them.

    The glyph is pure white and nothing else in the source is. Judging by
    saturation instead looks reasonable and is wrong: dirt has seven near-grey
    speckles scattered across the block, which are texture, and treating them
    as glyph left dark flecks all over the recoloured gold.
    """
    return tuple(pixel[:3]) != WHITE


def recolor(image, dark, light, glyph=None):
    # Read through tobytes rather than getdata, which Pillow has deprecated in
    # favour of a method too new to rely on here.
    raw = image.tobytes()
    pixels = [tuple(raw[i:i + 4]) for i in range(0, len(raw), 4)]
    texture = [p for p in pixels if is_texture(p)]
    low = min(luminance(p) for p in texture)
    high = max(luminance(p) for p in texture)
    span = high - low or 1

    glyph = glyph or glyph_color(dark, light)

    out = []
    for pixel in pixels:
        # The glyph is one flat tone, so it is replaced rather than mapped.
        if not is_texture(pixel):
            out.append((*glyph, pixel[3]))
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
    for name, (dark, light, glyph) in RAMPS.items():
        path = os.path.join("variants", f"{name}.png")
        recolor(source, dark, light, glyph).save(path)
        print(f"wrote {path}")
    source.close()


if __name__ == "__main__":
    main()
