import os
from collections import Counter

def analyze_colors(txt_path):
    colors = []
    with open(txt_path, 'r') as f:
        lines = f.readlines()
        
    for line in lines[1:]:
        if not line.strip():
            continue
        parts = line.split(':')
        rest = parts[1].strip()
        
        start_paren = rest.find('(')
        end_paren = rest.find(')')
        color_str = rest[start_paren+1:end_paren]
        
        vals = color_str.split(',')
        r, g, b = int(vals[0]), int(vals[1]), int(vals[2])
        a = int(vals[3]) if len(vals) > 3 else 255
        
        if a > 0:
            colors.append((r,g,b))
            
    c = Counter(colors)
    print("Most common colors (R,G,B):")
    for color, count in c.most_common(15):
        print(f"{color}: {count} pixels")

os.system("magick '" + os.path.expanduser("~/Library/Application Support/minetest/games/evergrowth/mods/eg_settlers/textures/female_mechanic.png") + "' temp.txt")
analyze_colors("temp.txt")
os.remove("temp.txt")
