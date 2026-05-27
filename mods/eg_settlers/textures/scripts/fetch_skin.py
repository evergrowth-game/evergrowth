import urllib.request
import json
import base64
import sys
import os

def fetch_page(page, per_page=1000):
    # Fetch skins using the supported pagination API with a large per_page limit
    url = f"https://skinsdb.terraqueststudios.net/api/v1/content?client=web&page={page}&per_page={per_page}"
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=10) as response:
            return json.loads(response.read().decode())
    except Exception as e:
        print(f"Error fetching page {page} (per_page={per_page}): {e}")
        return {}

def main():
    dest_dir = "/Users/Aresh/Library/Application Support/minetest/games/evergrowth/research"
    
    # Master list of all required online skins
    all_targets = {
        '1166': ('character_1166.png', 'Knight'),
        '2335': ('character_2335.png', 'Knighted Girl'),
        '390': ('character_390.png', 'Builder'),
        '732': ('character_732.png', 'Woodcutter'),
        '1435': ('character_1435.png', 'The Green Wizard'),
        '1841': ('character_1841.png', 'PirateMan'),
        '467': ('character_467.png', 'Pirate girl'),
        '1798': ('character_1798.png', 'Scientist 1'),
        '1961': ('character_1961.png', 'woman_lott'),
        '369': ('character_369.png', 'Adventer girl'),
        '2165': ('character_2165.png', 'blue_maid'),
        '466': ('character_466.png', 'farmer girl pink and green'),
        '815': ('character_815.png', 'Female Train Driver')
    }
    
    # Check for existing local files to avoid redundant network calls
    targets = {}
    for skin_id, (filename, label) in all_targets.items():
        output_path = os.path.join(dest_dir, filename)
        if not os.path.exists(output_path):
            targets[skin_id] = (filename, label)
            
    if not targets:
        print("All target skins already downloaded locally. Nothing to fetch.")
        return
        
    print(f"Need to fetch {len(targets)} missing skins from SkinsDB API: {list(targets.keys())}")
    print("Initializing high-efficiency pagination scan (per_page=1000)...")
    
    # Query page 1 with per_page=1000 to scan the first 1000 skins
    first_page_data = fetch_page(1, per_page=1000)
    if not first_page_data or "pages" not in first_page_data:
        print("Error: Could not retrieve data from SkinsDB API.")
        sys.exit(1)
        
    total_pages = first_page_data["pages"]
    print(f"SkinsDB has {total_pages} total pages (at 1000 items per page).")
    
    found_skins = {}
    
    # Process the first 1000 skins from the first request
    for skin in first_page_data.get('skins', []):
        skin_id = str(skin.get('id'))
        if skin_id in targets:
            found_skins[skin_id] = skin
            print(f"Found ID {skin_id}: '{skin.get('name')}' on page 1")
            
    # Scan subsequent pages if we haven't found all targets yet
    if len(found_skins) < len(targets):
        for p in range(2, total_pages + 1):
            print(f"Scanning page {p}/{total_pages}...", end="\r")
            page_data = fetch_page(p, per_page=1000)
            
            for skin in page_data.get('skins', []):
                skin_id = str(skin.get('id'))
                if skin_id in targets:
                    found_skins[skin_id] = skin
                    print(f"\nFound ID {skin_id}: '{skin.get('name')}' on page {p}")
                    
            if len(found_skins) == len(targets):
                break
                
    print("\nPage scanning complete. Processing downloads...")
    
    for skin_id, (filename, label) in targets.items():
        skin = found_skins.get(skin_id)
        if not skin:
            print(f"Error: Skin ID {skin_id} ({label}) was not found in the database.")
            continue
            
        output_path = os.path.join(dest_dir, filename)
        print(f"\nDownloading ID {skin_id}: '{skin.get('name')}' by {skin.get('author')}")
        print(f"License: {skin.get('license')}")
        
        img_b64 = skin.get('img')
        if not img_b64:
            print(f"Error: Skin {skin_id} does not contain image data.")
            continue
            
        try:
            img_data = base64.b64decode(img_b64)
            with open(output_path, "wb") as fh:
                fh.write(img_data)
            print(f"Successfully downloaded skin to: {output_path}")
        except Exception as e:
            print(f"Failed to decode or save skin {skin_id}: {e}")

if __name__ == "__main__":
    main()
