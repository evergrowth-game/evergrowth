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
    # Dark high-tech radar screen with crosshairs, orbit vectors, and top telemetry bar
    pixels = []
    bg = (8, 16, 26, 255)
    border = (35, 60, 85, 255)
    grid = (20, 52, 75, 255)
    accent = (0, 240, 215, 255)
    hud_green = (0, 255, 140, 255)
    hud_amber = (255, 185, 0, 255)
    hud_cyan = (0, 200, 255, 255)

    for y in range(h):
        for x in range(w):
            # Outer screen bezel frame
            if x == 0 or x == w - 1 or y == 0 or y == h - 1:
                pixels.append(border)
            elif x == 1 or x == w - 2 or y == 1 or y == h - 2:
                pixels.append((14, 28, 44, 255))
            # Status telemetry bar top (y = 3..4)
            elif (y in (3, 4)) and 3 <= x <= 28:
                if x in (3, 28):
                    pixels.append((60, 90, 120, 255))
                elif x <= 18:
                    pixels.append(hud_cyan)
                elif x <= 23:
                    pixels.append((0, 130, 180, 255))
                else:
                    pixels.append((30, 50, 70, 255))
            # Grid lines
            elif x % 6 == 0 or (y >= 6 and y % 6 == 0):
                pixels.append(grid)
            # Radar circle ring (centered at x=16, y=18)
            elif abs((x - 16) ** 2 + (y - 18) ** 2 - 70) < 12:
                pixels.append((0, 195, 175, 255))
            # Radar center crosshair
            elif (x == 16 and 12 <= y <= 24) or (y == 18 and 10 <= x <= 22):
                pixels.append(accent)
            # Trajectory vector line
            elif abs(y - (30 - x * 0.55)) < 1.0 and 5 <= x <= 27:
                pixels.append(hud_green)
            # Target waypoint node
            elif (x - 22) ** 2 + (y - 13) ** 2 <= 2:
                pixels.append(hud_amber)
            # Scanline pattern
            elif y % 2 == 0:
                pixels.append((bg[0] + 4, bg[1] + 5, bg[2] + 6, 255))
            else:
                pixels.append(bg)
    return pixels


def make_console_front(w=32, h=32):
    # Cockpit keyboard matrix, throttle dials, status LEDs on light alloy panel
    pixels = []
    panel_base = (145, 155, 168, 255)
    panel_dark = (110, 120, 132, 255)
    panel_rim = (85, 95, 108, 255)
    key_bg = (40, 46, 56, 255)
    key_cyan = (0, 215, 255, 255)
    key_amber = (245, 160, 20, 255)
    key_green = (0, 255, 130, 255)
    led_green = (0, 255, 130, 255)
    led_red = (255, 55, 65, 255)
    led_blue = (0, 180, 255, 255)

    for y in range(h):
        for x in range(w):
            # Outer border / bevel
            if x == 0 or x == w - 1 or y == 0 or y == h - 1:
                pixels.append(panel_rim)
            # Top LED diagnostic bar (y = 2..5)
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
                    pixels.append(panel_dark)
            # Throttle slider section (middle y = 7..13)
            elif 7 <= y <= 13 and 3 <= x <= 28:
                if x in (8, 16, 24):
                    # Slider track
                    if y in (9, 10):
                        pixels.append((240, 245, 255, 255))  # Slider thumb
                    else:
                        pixels.append((25, 30, 38, 255))
                elif x in (7, 9, 15, 17, 23, 25):
                    # Slider slot border
                    pixels.append((70, 78, 88, 255))
                elif y == 10 and (x in (5, 6, 13, 14, 21, 22, 26, 27)):
                    pixels.append((0, 200, 180, 255))  # Calibration tick mark
                else:
                    pixels.append(panel_base)
            # Keypad matrix (bottom half y = 15..29)
            elif 15 <= y <= 29 and 3 <= x <= 28:
                if (x - 3) % 4 == 0 or (y - 15) % 4 == 0:
                    pixels.append(panel_dark)
                else:
                    if (x + y) % 6 == 0:
                        pixels.append(key_cyan)
                    elif (x * y) % 9 == 0:
                        pixels.append(key_amber)
                    elif x >= 24 and y >= 24:
                        pixels.append(key_green)
                    else:
                        pixels.append(key_bg)
            else:
                pixels.append(panel_base)
    return pixels


def make_console_side(w=16, h=16):
    # Light brushed titanium alloy starship panel with chamfered seams and rivets
    pixels = []
    base = (148, 158, 170, 255)
    base_light = (175, 186, 200, 255)
    base_shadow = (105, 115, 128, 255)
    seam = (75, 84, 96, 255)
    rivet = (225, 235, 248, 255)

    for y in range(h):
        for x in range(w):
        # Corner / mounting rivets
            if (x in (2, 13) and y in (2, 13)) or (x in (2, 13) and y in (7, 8)):
                pixels.append(rivet)
            # Outer bevels and seam lines
            elif x == 0 or y == 0:
                pixels.append(base_light)
            elif x == w - 1 or y == h - 1 or y == 8:
                pixels.append(seam)
            elif x == 1 or y == 1:
                pixels.append(base_light)
            elif x == w - 2 or y == h - 2 or y == 7:
                pixels.append(base_shadow)
            elif (x + y) % 4 == 0:
                pixels.append((155, 165, 178, 255))
            else:
                pixels.append(base)
    return pixels


def make_lever_base(w=16, h=16):
    # Steel wall mounting bracket with center circular pivot housing
    pixels = []
    steel = (135, 145, 158, 255)
    dark_steel = (80, 90, 102, 255)
    light_steel = (180, 190, 205, 255)
    bolt = (230, 240, 252, 255)
    pivot = (45, 52, 62, 255)

    for y in range(h):
        for x in range(w):
            # Corner mounting bolts
            if (x in (2, 13) and y in (2, 13)):
                pixels.append(bolt)
            # Outer border
            elif x == 0 or y == 0:
                pixels.append(light_steel)
            elif x == w - 1 or y == h - 1:
                pixels.append(dark_steel)
            # Center pivot circle
            elif (x - 7.5) ** 2 + (y - 7.5) ** 2 <= 9:
                if (x - 7.5) ** 2 + (y - 7.5) ** 2 <= 3:
                    pixels.append((200, 210, 225, 255))
                else:
                    pixels.append(pivot)
            else:
                pixels.append(steel)
    return pixels


def make_lever_handle(w=16, h=16):
    # Chrome shaft with yellow/black hazard safety grip
    pixels = []
    hazard_yellow = (245, 185, 15, 255)
    hazard_black = (28, 30, 36, 255)
    chrome = (195, 205, 218, 255)
    chrome_light = (235, 242, 252, 255)
    chrome_dark = (125, 135, 148, 255)

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
                    pixels.append(chrome_light)  # chrome highlight
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
