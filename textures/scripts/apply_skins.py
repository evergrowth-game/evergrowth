import shutil
import os
import sys
import struct
import subprocess

def get_png_dimensions(file_path):
    # Pure Python PNG parser to read dimensions from IHDR chunk
    try:
        with open(file_path, 'rb') as f:
            data = f.read(24)
            if len(data) < 24 or data[:8] != b'\x89PNG\r\n\x1a\n':
                return None
            w, h = struct.unpack('>II', data[16:24])
            return w, h
    except Exception:
        return None

def main():
    dest_dir = "/Users/Aresh/Library/Application Support/minetest/games/evergrowth/mods/evergrowth_villages/textures"
    
    mapping = [
        # Farmer 1
        ("/Users/Aresh/Library/Application Support/minetest/mods/skinsdb/textures/character_farmer_male.png", "male_farmer_1.png"),
        ("/Users/Aresh/Library/Application Support/minetest/mods/skinsdb/textures/character_farmer_female.png", "female_farmer_1.png"),
        
        # Farmer 2
        ("/Users/Aresh/Library/Application Support/minetest/mods/mobf_trader/textures/tomatenhaendler.png", "male_farmer_2.png"),
        ("/Users/Aresh/Library/Application Support/minetest/mods/mobf_trader/textures/baeuerin.png", "female_farmer_2.png"),
        
        # Smith (Male uses Builder ID 390, Female uses woman_lott ID 1961)
        ("/Users/Aresh/Library/Application Support/minetest/games/evergrowth/research/character_390.png", "male_smith.png"),
        ("/Users/Aresh/Library/Application Support/minetest/games/evergrowth/research/character_1961.png", "female_blacksmith.png"),
        
        # Lumberjack (Male uses Woodcutter ID 732, Female uses Adventer girl ID 369)
        ("/Users/Aresh/Library/Application Support/minetest/games/evergrowth/research/character_732.png", "male_lumberjack.png"),
        ("/Users/Aresh/Library/Application Support/minetest/games/evergrowth/research/character_369.png", "female_lumberjack.png"),
        
        # Miner
        ("/Users/Aresh/Library/Application Support/minetest/mods/skinsdb/textures/character_rogue_male.png", "male_miner.png"),
        ("/Users/Aresh/Library/Application Support/minetest/mods/skinsdb/textures/character_rogue_female.png", "female_miner.png"),
        
        # Merchant (Prince/Princess)
        ("/Users/Aresh/Library/Application Support/minetest/mods/skinsdb/textures/character_prince.png", "male_merchant.png"),
        ("/Users/Aresh/Library/Application Support/minetest/mods/skinsdb/textures/character_princess.png", "female_merchant.png"),
        
        # Brewer (Male uses Sonntagskleidung, Female uses mobs_npc4)
        ("/Users/Aresh/Library/Application Support/minetest/mods/mobf_trader/textures/bauer_in_sonntagskleidung.png", "male_brewer.png"),
        ("/Users/Aresh/Library/Application Support/minetest/mods/mobs_npc/textures/mobs_npc4.png", "female_brewer.png"),
        
        # Librarian
        ("/Users/Aresh/Library/Application Support/minetest/mods/mobs_npc/textures/mobs_trader3.png", "male_librarian.png"),
        ("/Users/Aresh/Library/Application Support/minetest/mods/mobs_npc/textures/mobs_trader4.png", "female_librarian.png"),
        
        # Mage (Male uses Green Wizard ID 1435)
        ("/Users/Aresh/Library/Application Support/minetest/games/evergrowth/research/character_1435.png", "male_mage.png"),
        ("/Users/Aresh/Library/Application Support/minetest/mods/mobs_npc/textures/mobs_npc6.png", "female_mage.png"),
        
        # Gunsmith
        ("/Users/Aresh/Library/Application Support/minetest/mods/mobs_npc/textures/mobs_npc.png", "male_gunsmith.png"),
        ("/Users/Aresh/Library/Application Support/minetest/mods/mobs_npc/textures/mobs_npc2.png", "female_gunsmith.png"),
        
        # Fisher (Male uses PirateMan ID 1841)
        ("/Users/Aresh/Library/Application Support/minetest/games/evergrowth/research/character_1841.png", "male_fisher.png"),
        ("/Users/Aresh/Library/Application Support/minetest/games/evergrowth/research/character_467.png", "female_fisher.png"),
        
        # Guard (Male uses Knight ID 1166, Female uses Knighted Girl ID 2335)
        ("/Users/Aresh/Library/Application Support/minetest/games/evergrowth/research/character_1166.png", "male_guard.png"),
        ("/Users/Aresh/Library/Application Support/minetest/games/evergrowth/research/character_2335.png", "female_guard.png"),

        # Technologist (Scientist 1 ID 1798 and blue_maid ID 2165)
        ("/Users/Aresh/Library/Application Support/minetest/games/evergrowth/research/character_1798.png", "male_technologist.png"),
        ("/Users/Aresh/Library/Application Support/minetest/games/evergrowth/research/character_2165.png", "female_technologist.png"),

        # Carpenter (Male uses mobs_npc3, Female uses farmer girl pink/green ID 466)
        ("/Users/Aresh/Library/Application Support/minetest/mods/mobs_npc/textures/mobs_npc3.png", "male_carpenter.png"),
        ("/Users/Aresh/Library/Application Support/minetest/games/evergrowth/research/character_466.png", "female_carpenter.png"),

        # Mechanic (Male uses mobs_npc5, Female uses Female Train Driver ID 815)
        ("/Users/Aresh/Library/Application Support/minetest/mods/mobs_npc/textures/mobs_npc5.png", "male_mechanic.png"),
        ("/Users/Aresh/Library/Application Support/minetest/games/evergrowth/research/character_815.png", "female_mechanic.png"),
    ]
    
    print("Executing NPC skin copy and crop operations...")
    os.makedirs(dest_dir, exist_ok=True)
    
    success = True
    for src, filename in mapping:
        dest = os.path.join(dest_dir, filename)
        if not os.path.exists(src):
            print(f"Error: Source file does not exist: {src}")
            success = False
            continue
            
        dims = get_png_dimensions(src)
        
        try:
            # If the skin is 64x64 (modern Minecraft/Luanti format), crop the top 64x32 half
            # because the mobs_character.b3d model only expects 64x32 legacy skins.
            if dims and dims == (64, 64):
                subprocess.run([
                    "sips",
                    "--cropOffset", "32", "0",
                    "--cropToHeightWidth", "32", "64",
                    src,
                    "--out", dest
                ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                print(f"Cropped & Copied (64x64 -> 64x32): {os.path.basename(src)} -> {filename}")
            else:
                shutil.copy2(src, dest)
                print(f"Copied directly (64x32): {os.path.basename(src)} -> {filename}")
        except Exception as e:
            print(f"Failed to process {filename}: {e}")
            success = False
            
    if success:
        print("\nAll skins successfully processed.")
    else:
        print("\nSome skin operations failed.")
        sys.exit(1)

if __name__ == "__main__":
    main()
