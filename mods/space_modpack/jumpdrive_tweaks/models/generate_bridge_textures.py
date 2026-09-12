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
    # Clean, organized cockpit flight deck: status strip, throttle sliders, structured keypad
    pixels = []
    panel_bg = (34, 40, 50, 255)       # Calm aerospace dark slate
    panel_border = (50, 58, 70, 255)   # Subtle panel rim
    track_slot = (18, 22, 28, 255)     # Dark slider track
    slider_thumb = (220, 228, 238, 255) # Polished slider grip
    key_body = (48, 56, 68, 255)       # Uniform dark keycap
    key_rim = (62, 72, 86, 255)        # Keycap bevel
    key_label_blue = (90, 175, 235, 255) # Soft cyan function key label
    key_label_amber = (240, 175, 50, 255) # Amber enter / execute key
    key_label_white = (205, 215, 230, 255) # Clean numpad label

    led_green = (0, 230, 120, 255)
    led_blue = (0, 170, 255, 255)
    led_amber = (245, 170, 25, 255)
    led_red = (240, 55, 65, 255)

    for y in range(h):
        for x in range(w):
            # Outer clean 1px bezel
            if x == 0 or x == w - 1 or y == 0 or y == h - 1:
                pixels.append(panel_border)

            # 1. Top Status Annunciator Bar (y = 2..5)
            elif 2 <= y <= 5:
                if 4 <= x <= 7:
                    pixels.append(led_green)
                elif 11 <= x <= 14:
                    pixels.append(led_blue)
                elif 18 <= x <= 21:
                    pixels.append(led_amber)
                elif 25 <= x <= 28:
                    pixels.append(led_red)
                else:
                    pixels.append(panel_bg)

            # Divider line (y = 7)
            elif y == 7 and 2 <= x <= w - 3:
                pixels.append(panel_border)

            # 2. Throttle Bank (middle y = 9..15)
            elif 9 <= y <= 15:
                if x in (7, 15, 23):
                    # Slider track slot
                    if (x == 7 and y in (11, 12)) or (x == 15 and y in (10, 11)) or (x == 23 and y in (12, 13)):
                        pixels.append(slider_thumb)
                    else:
                        pixels.append(track_slot)
                elif x in (6, 8, 14, 16, 22, 24):
                    pixels.append((26, 32, 40, 255))
                else:
                    pixels.append(panel_bg)

            # Divider line (y = 17)
            elif y == 17 and 2 <= x <= w - 3:
                pixels.append(panel_border)

            # 3. Clean Structured Keypad (bottom y = 19..29)
            # Left Cluster: 3x3 Nav Keys (x: 4..13)
            # Right Cluster: 3x3 Coordinate Numpad (x: 18..27)
            elif 19 <= y <= 29:
                in_left_col = (4 <= x <= 6) or (8 <= x <= 10) or (12 <= x <= 14)
                in_right_col = (17 <= x <= 19) or (21 <= x <= 23) or (25 <= x <= 27)
                in_row = (19 <= y <= 21) or (23 <= y <= 25) or (27 <= y <= 29)

                if (in_left_col or in_right_col) and in_row:
                    is_center = False
                    if in_left_col and (x in (5, 9, 13)) and (y in (20, 24, 28)):
                        is_center = True
                    elif in_right_col and (x in (18, 22, 26)) and (y in (20, 24, 28)):
                        is_center = True

                    if is_center:
                        if in_left_col:
                            pixels.append(key_label_blue if y < 28 else key_label_amber)
                        else:
                            pixels.append(key_label_white)
                    elif x in (4, 8, 12, 17, 21, 25) or y in (19, 23, 27):
                        pixels.append(key_rim)
                    else:
                        pixels.append(key_body)
                else:
                    pixels.append(panel_bg)

            else:
                pixels.append(panel_bg)
    return pixels


def make_console_side(w=16, h=16):
    # Seamless brushed titanium alloy panel without corner rivets or clashing borders
    pixels = []
    base_alloy = (148, 156, 168, 255)
    alloy_grain1 = (154, 162, 174, 255)
    alloy_grain2 = (142, 150, 162, 255)
    edge_highlight = (168, 176, 188, 255)
    edge_shadow = (130, 138, 150, 255)

    for y in range(h):
        for x in range(w):
            # Subtle top/bottom edge shading for 3D depth
            if y == 0:
                pixels.append(edge_highlight)
            elif y == h - 1:
                pixels.append(edge_shadow)
            # Gentle horizontal brushed metal grain (seamless across box junctions)
            elif y % 4 == 0:
                pixels.append(alloy_grain1)
            elif y % 4 == 2:
                pixels.append(alloy_grain2)
            elif (x + y) % 5 == 0:
                pixels.append(alloy_grain1)
            else:
                pixels.append(base_alloy)
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
