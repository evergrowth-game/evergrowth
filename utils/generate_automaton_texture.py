#!/usr/bin/env python3
"""
Evergrowth Project - Automaton Skin Generator
============================================
Generates a cohesive 64x32 Magitech Automaton character skin (PNG)
compatible with `mobs_character.b3d` and standard Minetest character models.

Usage:
    python3 utils/generate_automaton_texture.py [output_path]

Default output:
    mods/eg_constructs/textures/eg_constructs_combat_drone.png
"""

import os
import sys
import zlib
import struct

W, H = 64, 32

# ---------------------------------------------------------------------------
# Color Palette
# ---------------------------------------------------------------------------
P_LIGHT   = [145, 150, 158, 255]  # Bright steel highlight
P_STEEL   = [105, 110, 118, 255]  # Primary steel plate
P_MID     = [75,  80,  88,  255]  # Gunmetal mid-tone
P_DARK    = [48,  52,  58,  255]  # Dark carbon shadow
P_CREVICE = [28,  30,  35,  255]  # Deep seam / joint crevice

C_BRIGHT  = [160, 115, 65,  255]  # Highlighted brass/copper
C_MID     = [125, 80,  45,  255]  # Primary mechanical copper
C_DARK    = [85,  50,  30,  255]  # Shaded copper joint

V_BRIGHT  = [200, 245, 255, 255]  # Visor / reactor core hot center
V_CYAN    = [0,   200, 245, 255]  # Primary cyan energy glow
V_DEEP    = [0,   120, 170, 255]  # Outer glow falloff


def generate_automaton_png(output_path: str):
    grid = [[[0, 0, 0, 0] for _ in range(W)] for _ in range(H)]

    def fill(x1, y1, x2, y2, color):
        for y in range(y1, y2 + 1):
            for x in range(x1, x2 + 1):
                grid[y][x] = list(color)

    # -----------------------------------------------------------------------
    # 1. HEAD (x: 0..31, y: 0..15)
    # -----------------------------------------------------------------------
    fill(0, 0, 31, 15, P_MID)

    # Top of head (8..15, 0..7)
    fill(8, 0, 15, 7, P_STEEL)
    fill(9, 1, 14, 6, P_LIGHT)
    fill(11, 2, 12, 5, P_MID)

    # Bottom of head (16..23, 0..7)
    fill(16, 0, 23, 7, P_CREVICE)
    fill(18, 2, 21, 5, P_DARK)

    # Front face (8..15, 8..15)
    fill(8, 8, 15, 15, P_MID)
    fill(9, 8, 14, 9, P_STEEL)           # Brow armor plate
    fill(8, 10, 15, 11, P_CREVICE)       # Visor housing
    fill(10, 10, 13, 11, V_CYAN)         # Visor slit
    grid[10][11] = list(V_BRIGHT)
    grid[10][12] = list(V_BRIGHT)
    grid[11][10] = list(V_DEEP)
    grid[11][13] = list(V_DEEP)

    # Mouth / Lower face (y=12..15)
    fill(9, 12, 14, 13, P_DARK)          # Mouthplate recess
    grid[12][11] = list(P_CREVICE)
    grid[12][12] = list(P_CREVICE)       # Filter vents
    grid[13][10] = list(P_CREVICE)
    grid[13][13] = list(P_CREVICE)
    fill(9, 14, 14, 15, P_STEEL)         # Reinforced jaw
    fill(10, 15, 13, 15, C_MID)          # Chin copper fitting

    # Left & Right Head Sides (0..7, 8..15) and (16..23, 8..15)
    for ox in (0, 16):
        fill(ox, 8, ox + 7, 15, P_MID)
        fill(ox + 1, 9, ox + 6, 14, P_DARK)
        fill(ox + 2, 10, ox + 5, 13, C_MID)      # Ear sensor node
        fill(ox + 3, 11, ox + 4, 12, C_BRIGHT)

    # Back of head (24..31, 8..15)
    fill(24, 8, 31, 15, P_MID)
    fill(25, 9, 30, 14, P_DARK)
    for vy in (10, 12, 14):
        fill(26, vy, 29, vy, P_CREVICE)          # Cooling exhaust vents

    # -----------------------------------------------------------------------
    # 2. TORSO (x: 16..39, y: 16..31)
    # -----------------------------------------------------------------------
    fill(16, 16, 39, 31, P_DARK)

    # Top (20..27, 16..19)
    fill(20, 16, 27, 19, P_STEEL)
    fill(22, 17, 25, 18, P_LIGHT)

    # Bottom (28..35, 16..19)
    fill(28, 16, 35, 19, P_CREVICE)

    # Front Torso (20..27, 20..31)
    fill(20, 20, 27, 25, P_STEEL)                # Chest plate
    fill(21, 21, 26, 24, P_LIGHT)                # Beveled armor
    # Arc Reactor / Power Core
    fill(22, 22, 25, 24, P_CREVICE)
    fill(23, 22, 24, 23, V_CYAN)
    grid[22][23] = list(V_BRIGHT)
    grid[22][24] = list(V_BRIGHT)

    # Abdomen (y=26..29)
    fill(20, 26, 27, 29, P_CREVICE)              # Inner chassis
    fill(21, 26, 22, 28, C_MID)                  # Left copper piston
    fill(25, 26, 26, 28, C_MID)                  # Right copper piston
    fill(23, 27, 24, 28, P_DARK)                 # Center spinal strut

    # Utility Belt (y=30..31)
    fill(20, 30, 27, 31, P_STEEL)
    fill(23, 30, 24, 31, C_BRIGHT)               # Center buckle

    # Back Torso (32..39, 20..31)
    fill(32, 20, 39, 31, P_MID)
    fill(34, 20, 37, 28, P_STEEL)                # Spine casing
    for sy in (22, 24, 26, 28):
        fill(35, sy, 36, sy, V_CYAN)             # Spine power conduits
    fill(32, 30, 39, 31, P_DARK)

    # Torso Sides (16..19, 20..31) and (28..31, 20..31)
    for sx in (16, 28):
        fill(sx, 20, sx + 3, 31, P_MID)
        fill(sx + 1, 22, sx + 2, 28, P_DARK)
        fill(sx + 1, 29, sx + 2, 30, C_MID)

    # -----------------------------------------------------------------------
    # 3. RIGHT LEG (x: 0..15, y: 16..31)
    # -----------------------------------------------------------------------
    fill(0, 16, 15, 31, P_MID)
    fill(4, 16, 11, 19, P_DARK)                  # Top / bottom

    for lx in (0, 4, 8, 12):
        fill(lx, 20, lx + 3, 24, P_STEEL)        # Thigh armor
        fill(lx + 1, 21, lx + 2, 23, P_LIGHT)
        fill(lx, 25, lx + 3, 26, P_CREVICE)      # Knee hinge
        fill(lx + 1, 25, lx + 2, 26, C_MID)
        fill(lx, 27, lx + 3, 29, P_STEEL)        # Greave plate
        fill(lx, 30, lx + 3, 31, P_DARK)         # Armored boot
        grid[31][lx + 1] = list(P_STEEL)
        grid[31][lx + 2] = list(P_STEEL)

    # Outer leg energy line
    fill(1, 21, 2, 23, V_CYAN)
    fill(1, 27, 2, 28, V_CYAN)

    # -----------------------------------------------------------------------
    # 4. RIGHT ARM (x: 40..55, y: 16..31)
    # -----------------------------------------------------------------------
    fill(40, 16, 55, 31, P_MID)
    fill(44, 16, 47, 19, P_LIGHT)                # Shoulder top
    fill(48, 16, 51, 19, P_CREVICE)

    for ax in (40, 44, 48, 52):
        fill(ax, 20, ax + 3, 24, P_STEEL)        # Pauldron
        fill(ax + 1, 20, ax + 2, 23, P_LIGHT)
        fill(ax, 25, ax + 3, 26, P_CREVICE)      # Elbow joint
        fill(ax + 1, 25, ax + 2, 26, C_MID)
        fill(ax, 27, ax + 3, 29, P_STEEL)        # Forearm gauntlet
        fill(ax, 30, ax + 3, 31, P_DARK)         # Fist
        grid[31][ax + 1] = list(C_BRIGHT)
        grid[31][ax + 2] = list(C_BRIGHT)

    # Outer arm energy line
    fill(41, 21, 42, 23, V_CYAN)
    fill(41, 27, 42, 28, V_CYAN)

    # -----------------------------------------------------------------------
    # 5. PNG Binary Encoding (Standard Library struct + zlib)
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
        flat.append(0)  # Filter type None
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

    print(f"Generated automaton texture: {output_path}")


if __name__ == "__main__":
    target = (
        sys.argv[1]
        if len(sys.argv) > 1
        else "mods/eg_constructs/textures/eg_constructs_combat_drone.png"
    )
    generate_automaton_png(target)
