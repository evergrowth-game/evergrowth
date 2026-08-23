#!/usr/bin/env python3
"""
Evergrowth Project - Human Settler Skin Generator
===================================================
Generates a 64x32 human settler skin compatible with mobs_character.b3d
in the same style as eg_settlers (flat clothing blocks, 2-pixel eyes,
solid hair, belt, pants, and boots).

Usage:
    python3 utils/generate_human_texture.py [output_path]
"""

import os
import sys
import zlib
import struct

W, H = 64, 32

# ---------------------------------------------------------------------------
# Settler Palette
# ---------------------------------------------------------------------------
SKIN_BASE   = [232, 190, 155, 255]
SKIN_SHADOW = [210, 165, 130, 255]

HAIR_LIGHT  = [115, 80,  52,  255]
HAIR_MID    = [90,  60,  38,  255]
HAIR_DARK   = [65,  42,  25,  255]

EYE_WHITE   = [245, 245, 250, 255]
EYE_IRIS    = [45,  115, 195, 255]

TUNIC_LIGHT = [60,  155, 85,  255]
TUNIC_MID   = [45,  125, 65,  255]
TUNIC_DARK  = [30,  95,  48,  255]
TRIM_GOLD   = [215, 175, 50,  255]

BELT_LEATHER= [70,  45,  25,  255]
BELT_BUCKLE = [230, 195, 70,  255]

PANTS_MID   = [95,  75,  55,  255]
PANTS_DARK  = [75,  58,  42,  255]

BOOT_MID    = [45,  35,  28,  255]
BOOT_DARK   = [28,  22,  18,  255]


def generate_human_skin(output_path: str):
    grid = [[[0, 0, 0, 0] for _ in range(W)] for _ in range(H)]

    def fill(x1, y1, x2, y2, color):
        for y in range(y1, y2 + 1):
            for x in range(x1, x2 + 1):
                grid[y][x] = list(color)

    # -----------------------------------------------------------------------
    # 1. HEAD (x: 0..31, y: 0..15)
    # -----------------------------------------------------------------------
    fill(0, 0, 31, 15, HAIR_MID)

    # Top of head (8..15, 0..7) - Hair
    fill(8, 0, 15, 7, HAIR_MID)
    fill(9, 1, 14, 6, HAIR_LIGHT)

    # Bottom of head (16..23, 0..7) - Neck / Jaw underside
    fill(16, 0, 23, 7, SKIN_SHADOW)
    fill(18, 2, 21, 5, SKIN_BASE)

    # Front Face (8..15, 8..15)
    fill(8, 8, 15, 15, SKIN_BASE)
    # Hair bangs / fringe on forehead
    fill(8, 8, 15, 8, HAIR_DARK)
    fill(9, 9, 14, 9, HAIR_MID)
    grid[9][8] = list(HAIR_DARK)
    grid[9][15] = list(HAIR_DARK)

    # Eyes: (x=10..11 left eye, x=12..13 right eye)
    # 2-pixel wide eyes at y=11
    grid[11][10] = list(EYE_WHITE)
    grid[11][11] = list(EYE_IRIS)
    grid[11][12] = list(EYE_IRIS)
    grid[11][13] = list(EYE_WHITE)

    # Nose / mouth subtle accents
    grid[12][11] = list(SKIN_SHADOW)
    grid[12][12] = list(SKIN_SHADOW)
    grid[13][11] = list(SKIN_SHADOW)
    grid[13][12] = list(SKIN_SHADOW)

    # Left & Right Sides of Head (0..7, 8..15) and (16..23, 8..15)
    for ox in (0, 16):
        fill(ox, 8, ox + 7, 15, HAIR_MID)
        if ox == 0:
            fill(6, 11, 7, 14, SKIN_BASE)
            grid[14][7] = list(SKIN_SHADOW)
        else:
            fill(16, 11, 17, 14, SKIN_BASE)
            grid[14][16] = list(SKIN_SHADOW)

    # Back of Head (24..31, 8..15)
    fill(24, 8, 31, 15, HAIR_MID)
    fill(25, 9, 30, 14, HAIR_DARK)

    # -----------------------------------------------------------------------
    # 2. TORSO (x: 16..39, y: 16..31)
    # -----------------------------------------------------------------------
    # Top of Torso (20..27, 16..19) - Shoulders & Collar
    fill(20, 16, 27, 19, TUNIC_MID)
    fill(23, 17, 24, 18, SKIN_BASE)

    # Bottom of Torso (28..35, 16..19) - Pelvis underside
    fill(28, 16, 35, 19, PANTS_DARK)

    # Front Torso (20..27, 20..31)
    fill(20, 20, 27, 29, TUNIC_MID)
    fill(21, 21, 26, 27, TUNIC_LIGHT)
    grid[20][23] = list(SKIN_BASE)
    grid[20][24] = list(SKIN_BASE)
    grid[21][23] = list(TRIM_GOLD)
    grid[21][24] = list(TRIM_GOLD)

    # Leather Belt (y=29..30) & Buckle
    fill(20, 29, 27, 30, BELT_LEATHER)
    fill(23, 29, 24, 30, BELT_BUCKLE)

    # Pelvis / Top of pants (y=31)
    fill(20, 31, 27, 31, PANTS_MID)

    # Back Torso (32..39, 20..31)
    fill(32, 20, 39, 28, TUNIC_MID)
    fill(34, 21, 37, 27, TUNIC_DARK)
    fill(32, 29, 39, 30, BELT_LEATHER)
    fill(32, 31, 39, 31, PANTS_MID)

    # Torso Sides (16..19, 20..31) and (28..31, 20..31)
    for sx in (16, 28):
        fill(sx, 20, sx + 3, 28, TUNIC_MID)
        fill(sx, 29, sx + 3, 30, BELT_LEATHER)
        fill(sx, 31, sx + 3, 31, PANTS_MID)

    # -----------------------------------------------------------------------
    # 3. RIGHT LEG (x: 0..15, y: 16..31)
    # -----------------------------------------------------------------------
    fill(0, 16, 15, 31, PANTS_MID)
    fill(4, 16, 11, 19, PANTS_DARK)

    for lx in (0, 4, 8, 12):
        fill(lx, 20, lx + 3, 27, PANTS_MID)
        fill(lx + 1, 21, lx + 2, 26, PANTS_DARK)
        fill(lx, 28, lx + 3, 30, BOOT_MID)
        fill(lx, 31, lx + 3, 31, BOOT_DARK)

    # -----------------------------------------------------------------------
    # 4. RIGHT ARM (x: 40..55, y: 16..31)
    # -----------------------------------------------------------------------
    fill(40, 16, 55, 31, TUNIC_MID)
    fill(44, 16, 47, 19, TUNIC_LIGHT)
    fill(48, 16, 51, 19, SKIN_SHADOW)

    for ax in (40, 44, 48, 52):
        fill(ax, 20, ax + 3, 26, TUNIC_MID)
        fill(ax + 1, 20, ax + 2, 25, TUNIC_LIGHT)
        fill(ax, 26, ax + 3, 26, TRIM_GOLD)
        fill(ax, 27, ax + 3, 31, SKIN_BASE)
        fill(ax + 1, 28, ax + 2, 30, SKIN_SHADOW)

    # -----------------------------------------------------------------------
    # 5. PNG Serializer
    # -----------------------------------------------------------------------
    def chunk(tag: bytes, payload: bytes) -> bytes:
        return (
            struct.pack(">I", len(payload))
            + tag
            + payload
            + struct.pack(">I", zlib.crc32(tag + payload) & 0xFFFFFFFF)
        )

    ihdr = struct.pack(">IIBBBBB", W, H, 8, 6, 0, 0, 0)
    flat = bytearray()
    for y in range(H):
        flat.append(0)
        for x in range(W):
            flat.extend(grid[y][x])

    idat = zlib.compress(bytes(flat), 9)
    png_bytes = (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", ihdr)
        + chunk(b"IDAT", idat)
        + chunk(b"IEND", b"")
    )

    os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
    with open(output_path, "wb") as f:
        f.write(png_bytes)

    print(f"Generated human skin: {output_path}")


if __name__ == "__main__":
    target = (
        sys.argv[1]
        if len(sys.argv) > 1
        else "research/human_skin_sample.png"
    )
    generate_human_skin(target)
