import os
import colorsys

def recolor_txt(input_txt, output_txt, target_hue_shift, skin_hue_range=(0.02, 0.14)):
    with open(input_txt, 'r') as f:
        lines = f.readlines()
        
    out_lines = []
    out_lines.append(lines[0])
    
    for line in lines[1:]:
        if not line.strip():
            continue
        parts = line.split(':')
        coords = parts[0]
        rest = parts[1].strip()
        
        start_paren = rest.find('(')
        end_paren = rest.find(')')
        color_str = rest[start_paren+1:end_paren]
        
        vals = color_str.split(',')
        r = float(vals[0].strip())
        g = float(vals[1].strip())
        b = float(vals[2].strip())
        a = 255
        if len(vals) > 3:
            a = float(vals[3].strip())
            
        if a == 0:
            out_lines.append(line)
            continue
            
        h, s, v = colorsys.rgb_to_hsv(r/255.0, g/255.0, b/255.0)
        
        # 0.15 saturation threshold might miss very dark parts, lower it to 0.10
        if s > 0.10 and not (skin_hue_range[0] <= h <= skin_hue_range[1]):
            # Shift hue
            new_h = (h + target_hue_shift) % 1.0
            
            # Since the original clothes are olive green (h ~ 0.18),
            # Shifting by +0.5 makes them Blue (h ~ 0.68)
            # Shifting by +0.25 makes them Cyan/Blueish. Let's make Aircraft true green (+0.15)
            # Or if Aircraft is already olive green, shifting it to pure green.
            
            nr, ng, nb = colorsys.hsv_to_rgb(new_h, s, v)
            
            nr, ng, nb = int(nr*255), int(ng*255), int(nb*255)
            
            # Format hex code: #RRGGBBAA
            # Important: image magick needs uppercase hex
            hex_code = f"#{nr:02X}{ng:02X}{nb:02X}{int(a):02X}"
            
            out_lines.append(f"{coords}: ({nr},{ng},{nb},{int(a)})  {hex_code}\n")
        else:
            out_lines.append(line)
            
    with open(output_txt, 'w') as f:
        f.writelines(out_lines)

def process_image(img_path, out_path, hue_shift):
    print(f"Processing {img_path} -> {out_path} with shift {hue_shift}")
    txt_path = img_path + ".txt"
    out_txt_path = out_path + ".txt"
    
    os.system(f"magick '{img_path}' '{txt_path}'")
    recolor_txt(txt_path, out_txt_path, hue_shift)
    os.system(f"magick '{out_txt_path}' '{out_path}'")
    
    os.remove(txt_path)
    os.remove(out_txt_path)
    
textures_dir = "/Users/Aresh/Library/Application Support/minetest/games/evergrowth/mods/eg_settlers/textures"

# Original is Olive Green (Hue ~ 0.18)
# Nautical (Blue shift): +0.42 puts it at ~0.60 (Blue)
process_image(os.path.join(textures_dir, "male_mechanic.png"), os.path.join(textures_dir, "male_nautical_mechanic.png"), 0.42)
process_image(os.path.join(textures_dir, "female_mechanic.png"), os.path.join(textures_dir, "female_nautical_mechanic.png"), 0.42)

# Aircraft (Green shift): +0.15 puts it at ~0.33 (True Green)
process_image(os.path.join(textures_dir, "male_mechanic.png"), os.path.join(textures_dir, "male_aircraft_mechanic.png"), 0.15)
process_image(os.path.join(textures_dir, "female_mechanic.png"), os.path.join(textures_dir, "female_aircraft_mechanic.png"), 0.15)
