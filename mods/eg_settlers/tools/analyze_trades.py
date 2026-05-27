#!/usr/bin/env python3
import sys
import re
from collections import defaultdict

def analyze_trades(trades_path):
    try:
        with open(trades_path, 'r') as f:
            lines = f.readlines()
    except FileNotFoundError:
        print(f"Error: File not found at {trades_path}")
        sys.exit(1)

    current_prof = None
    current_direction = "unknown"
    prof_data = defaultdict(list)

    # Regex to capture trade tuples: {"item_name count", "price_name count", chance}
    trade_pattern = re.compile(r'\{\s*"([^"]+)"\s*,\s*"([^"]+)"\s*,\s*(\d+)\s*\}')

    for line in lines:
        line_strip = line.strip()
        
        # Detect profession table start (e.g., farmer = {)
        prof_match = re.match(r'^([a-zA-Z_]+)\s*=\s*\{', line_strip)
        if prof_match:
            current_prof = prof_match.group(1)
            current_direction = "unknown"
            continue
            
        # Detect profession table end
        if current_prof and (line_strip == '},' or line_strip == '}'):
            current_prof = None
            continue
            
        if current_prof:
            # Set direction based on comment headers
            if "NPC Sells" in line or "Sells" in line:
                current_direction = "NPC Sells (Player Buys)"
            elif "NPC Buys" in line or "Buys" in line:
                current_direction = "NPC Buys (Player Sells)"
                
            match = trade_pattern.search(line_strip)
            if match:
                item_str1, item_str2, chance = match.groups()
                
                parts1 = item_str1.split()
                parts2 = item_str2.split()
                
                if len(parts1) == 2 and len(parts2) == 2:
                    name1, qty1 = parts1[0], float(parts1[1])
                    name2, qty2 = parts2[0], float(parts2[1])
                    
                    prof_data[current_prof].append({
                        'direction': current_direction,
                        'item1': name1,
                        'qty1': qty1,
                        'item2': name2,
                        'qty2': qty2,
                        'chance': int(chance)
                    })

    # Group values of items in terms of gold lumps (1 Gold Lump = 1.0)
    gold_values = defaultdict(lambda: {'sell_gold': [], 'buy_gold': []})
    
    for prof, trades in prof_data.items():
        for t in trades:
            if t['item2'] == 'default:gold_lump':
                # Player gives gold (item2), gets raw item (item1). NPC Sells.
                raw_item = t['item1']
                gold_paid = t['qty2']
                qty_received = t['qty1']
                gold_per_unit = gold_paid / qty_received
                gold_values[raw_item]['sell_gold'].append((prof, gold_per_unit, f"{t['qty2']} gold for {t['qty1']} units"))
            elif t['item1'] == 'default:gold_lump':
                # Player gets gold (item1), gives raw item (item2). NPC Buys.
                raw_item = t['item2']
                gold_received = t['qty1']
                qty_given = t['qty2']
                gold_per_unit = gold_received / qty_given
                gold_values[raw_item]['buy_gold'].append((prof, gold_per_unit, f"{t['qty1']} gold for {t['qty2']} units"))
                
    print(f"\n=========================================")
    print(f"       EVERGROWTH TRADE VALUE AUDIT      ")
    print(f"=========================================\n")
    print(f"This report shows the implied value of items in Gold Lumps.")
    print(f"(1 Gold Lump = 1.0 Value)\n")
    
    for item, values in sorted(gold_values.items()):
        print(f"📦 Item: {item}")
        if values['sell_gold']:
            print("  🟢 NPC Sells to Player (Player Buys):")
            for prof, val, desc in values['sell_gold']:
                print(f"    - [{prof}] 1 unit = {val:.4f} gold ({desc})")
        if values['buy_gold']:
            print("  🔴 NPC Buys from Player (Player Sells):")
            for prof, val, desc in values['buy_gold']:
                print(f"    - [{prof}] 1 unit = {val:.4f} gold ({desc})")
        print()

if __name__ == "__main__":
    path = "trades.lua"
    if len(sys.argv) > 1:
        path = sys.argv[1]
    analyze_trades(path)
