#!/usr/bin/env python3
"""Generate PNG textures for jumpdrive_tweaks bridge console and jump lever."""

import os
import struct
import zlib

TEXTURE_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "textures")


def save_png(filename, width, height, pixels):
    """Write an RGBA image using pure Python with zlib."""
    raw_data = bytearray()
    for y in range(height):
        raw_data.append(0)  # filter type 0 (None)
        for x in range(width):
            r, g, b, a = pixels[y * width + x]
            raw_data.extend([r, g, b, a])

    compressed = zlib.compress(raw_data)

    def chunk(chunk_type, data):
        return (
            struct.pack(">I", len(data))
            + chunk_type
            + data
            + struct.pack(">I", zlib.crc32(chunk_type + data) & 0xFFFFFFFF)
        )

    png = (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
        + chunk(b"IDAT", compressed)
        + chunk(b"IEND", b"")
    )

    filepath = os.path.join(TEXTURE_DIR, filename)
    with open(filepath, "wb") as f:
        f.write(png)
    print(f"Generated texture {filename} ({width}x{height})")


def make_console_screen(w=32, h=32):
    # Dark high-tech radar screen with crosshairs and orbital vectors
    pixels = []
    bg = (10, 16, 24, 255)
    border = (28, 42, 58, 255)
    grid = (20, 48, 65, 255)
    accent = (0, 230, 200, 255)
    hud_green = (0, 255, 136, 255)
    hud_amber = (255, 180, 0, 255)

    for y in range(h):
        for x in range(w):
            # Outer screen border
            if x == 0 or x == w - 1 or y == 0 or y == h - 1:
                pixels.append(border)
            elif x == 1 or x == w - 2 or y == 1 or y == h - 2:
                pixels.append((15, 24, 35, 255))
            # Grid lines
            elif x % 6 == 0 or y % 6 == 0:
                pixels.append(grid)
            # Radar circle ring
            elif abs((x - 16) ** 2 + (y - 16) ** 2 - 80) < 14:
                pixels.append((0, 180, 160, 255))
            # Radar center crosshair
            elif (x == 16 and 10 <= y <= 22) or (y == 16 and 10 <= x <= 22):
                pixels.append(accent)
            # Trajectory vector vector line
            elif abs(y - (30 - x * 0.6)) < 1.0 and 6 <= x <= 26:
                pixels.append(hud_green)
            # Target waypoint node
            elif (x - 22) ** 2 + (y - 10) ** 2 <= 2:
                pixels.append(hud_amber)
            # Status telemetry bar top
            elif y == 3 and 4 <= x <= 27:
                pixels.append((0, 140, 220, 255) if x <= 20 else (50, 70, 90, 255))
            # Scanline pattern
            elif y % 2 == 0:
                pixels.append((bg[0] + 3, bg[1] + 3, bg[2] + 4, 255))
            else:
                pixels.append(bg)
    return pixels


def make_console_front(w=32, h=32):
    # Cockpit keyboard matrix, throttle dials, status LEDs
    pixels = []
    chassis = (42, 48, 58, 255)
    chassis_dark = (30, 34, 42, 255)
    key_bg = (24, 28, 36, 255)
    key_glow = (0, 210, 255, 255)
    key_amber = (240, 150, 20, 255)
    led_green = (0, 255, 120, 255)
    led_red = (255, 50, 60, 255)
    led_blue = (0, 160, 255, 255)

    for y in range(h):
        for x in range(w):
            # Bevels and borders
            if x == 0 or x == w - 1 or y == 0 or y == h - 1:
                pixels.append((20, 23, 28, 255))
            # Top LED diagnostic bar
            elif 2 <= y <= 5:
                if 4 <= x <= 7:
                    pixels.append(led_green)
                elif 10 <= x <= 13:
                    pixels.append(led_blue)
                elif 16 <= x <= 19:
                    pixels.append(key_amber)
                elif 22 <= x <= 25:
                    pixels.append(led_red)
                else:
                    pixels.append(chassis_dark)
            # Throttle slider trench (middle)
            elif 7 <= y <= 13 and 3 <= x <= 28:
                if x in (8, 16, 24):
                    # Slider track
                    if y in (9, 10):
                        pixels.append((200, 210, 225, 255))  # Slider thumb
                    else:
                        pixels.append((12, 15, 18, 255))
                else:
                    pixels.append(chassis)
            # Keypad matrix (bottom half)
            elif 15 <= y <= 29 and 3 <= x <= 28:
                if (x - 3) % 4 == 0 or (y - 15) % 4 == 0:
                    pixels.append(chassis_dark)
                else:
                    if (x + y) % 7 == 0:
                        pixels.append(key_glow)
                    elif (x * y) % 11 == 0:
                        pixels.append(key_amber)
                    else:
                        pixels.append(key_bg)
            else:
                pixels.append(chassis)
    return pixels


def make_console_side(w=16, h=16):
    # Brushed titanium alloy side panel with mounting rivets
    pixels = []
    base = (48, 54, 64, 255)
    base_dark = (36, 41, 48, 255)
    rivet = (85, 95, 110, 255)

    for y in range(h):
        for x in range(w):
            # Corner rivets
            if (x in (2, 13) and y in (2, 13)) or (x in (2, 13) and y in (7, 8)):
                pixels.append(rivet)
            # Seam lines
            elif x == 0 or x == w - 1 or y == 0 or y == h - 1 or y == 8:
                pixels.append(base_dark)
            elif (x + y) % 3 == 0:
                pixels.append((54, 60, 72, 255))
            else:
                pixels.append(base)
    return pixels


def make_lever_base(w=16, h=16):
    # Steel wall mounting bracket with center circular pivot housing
    pixels = []
    steel = (55, 62, 72, 255)
    dark_steel = (35, 40, 48, 255)
    bolt = (95, 105, 120, 255)
    pivot = (25, 28, 35, 255)

    for y in range(h):
        for x in range(w):
            # Corner mounting bolts
            if (x in (2, 13) and y in (2, 13)):
                pixels.append(bolt)
            # Outer border
            elif x == 0 or x == w - 1 or y == 0 or y == h - 1:
                pixels.append(dark_steel)
            # Center pivot circle
            elif (x - 7.5) ** 2 + (y - 7.5) ** 2 <= 9:
                if (x - 7.5) ** 2 + (y - 7.5) ** 2 <= 3:
                    pixels.append((120, 130, 145, 255))
                else:
                    pixels.append(pivot)
            else:
                pixels.append(steel)
    return pixels


def make_lever_handle(w=16, h=16):
    # Chrome shaft with yellow/black hazard safety grip
    pixels = []
    hazard_yellow = (235, 175, 15, 255)
    hazard_black = (25, 25, 28, 255)
    chrome = (175, 185, 198, 255)
    chrome_dark = (110, 120, 132, 255)

    for y in range(h):
        for x in range(w):
            # Top half: hazard grip
            if y <= 9:
                if (x + y) % 5 in (0, 1):
                    pixels.append(hazard_black)
                else:
                    pixels.append(hazard_yellow)
            # Bottom half: chrome actuator shaft
            else:
                if x in (0, 1, 14, 15):
                    pixels.append(chrome_dark)
                elif x in (6, 7):
                    pixels.append((215, 225, 238, 255))  # chrome highlight
                else:
                    pixels.append(chrome)
    return pixels


def main():
    os.makedirs(TEXTURE_DIR, exist_ok=True)
    save_png("jumpdrive_bridge_console_top.png", 32, 32, make_console_screen(32, 32))
    save_png("jumpdrive_bridge_console_front.png", 32, 32, make_console_front(32, 32))
    save_png("jumpdrive_bridge_console_side.png", 16, 16, make_console_side(16, 16))
    save_png("jumpdrive_jump_lever_base.png", 16, 16, make_lever_base(16, 16))
    save_png("jumpdrive_jump_lever_handle.png", 16, 16, make_lever_handle(16, 16))


if __name__ == "__main__":
    main()
