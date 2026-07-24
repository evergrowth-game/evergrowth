#!/usr/bin/env python3
import sys
import re
from collections import defaultdict

def check_disparities(trades_path):
    try:
        with open(trades_path, 'r') as f:
            lines = f.readlines()
    except FileNotFoundError:
        print(f"Error: File not found at {trades_path}")
        sys.exit(1)

    current_prof = None
    prof_data = defaultdict(list)
    trade_pattern = re.compile(r'\{\s*"([^"]+)"\s*,\s*"([^"]+)"\s*,\s*(\d+)\s*\}')

    for line in lines:
        line_strip = line.strip()
        # Ignore comments
        if line_strip.startswith('--'):
            continue
            
        prof_match = re.match(r'^([a-zA-Z_]+)\s*=\s*\{', line_strip)
        if prof_match:
            current_prof = prof_match.group(1)
            continue
            
        if current_prof and (line_strip == '},' or line_strip == '}'):
            current_prof = None
            continue
            
        if current_prof:
            # We don't care about the comment direction, we just infer from item2 vs item1
            # But wait, mobs_npc defines direction by which item is given to get the other.
            # But the script can just use the gold position like analyze_trades did.
            match = trade_pattern.search(line_strip)
            if match:
                item_str1, item_str2, chance = match.groups()
                parts1 = item_str1.split()
                parts2 = item_str2.split()
                
                if len(parts1) == 2 and len(parts2) == 2:
                    name1, qty1 = parts1[0], float(parts1[1])
                    name2, qty2 = parts2[0], float(parts2[1])
                    prof_data[current_prof].append({
                        'item1': name1, 'qty1': qty1,
                        'item2': name2, 'qty2': qty2,
                        'line': line_strip
                    })

    gold_values = defaultdict(lambda: {'sell_gold': [], 'buy_gold': []})
    
    for prof, trades in prof_data.items():
        for t in trades:
            if t['item2'] == 'default:gold_lump':
                # Player gives gold (item2), gets raw item (item1). NPC Sells.
                raw_item = t['item1']
                gold_per_unit = t['qty2'] / t['qty1']
                gold_values[raw_item]['sell_gold'].append((prof, gold_per_unit, t['line']))
            elif t['item1'] == 'default:gold_lump':
                # Player gets gold (item1), gives raw item (item2). NPC Buys.
                raw_item = t['item2']
                gold_per_unit = t['qty1'] / t['qty2']
                gold_values[raw_item]['buy_gold'].append((prof, gold_per_unit, t['line']))

    disparities_found = False

    for item, values in sorted(gold_values.items()):
        # Check for sell disparities
        if values['sell_gold']:
            sell_prices = [val for prof, val, line in values['sell_gold']]
            if len(set(round(p, 4) for p in sell_prices)) > 1:
                disparities_found = True
                print(f"❌ DISPARITY DETECTED: {item} has inconsistent NPC SELL prices.")
                for prof, val, line in values['sell_gold']:
                    print(f"    [{prof}] Sells for {val:.4f} gold/unit  -> {line}")
        
        # Check for buy disparities
        if values['buy_gold']:
            buy_prices = [val for prof, val, line in values['buy_gold']]
            if len(set(round(p, 4) for p in buy_prices)) > 1:
                disparities_found = True
                print(f"❌ DISPARITY DETECTED: {item} has inconsistent NPC BUY prices.")
                for prof, val, line in values['buy_gold']:
                    print(f"    [{prof}] Buys for {val:.4f} gold/unit  -> {line}")

        # Check margin
        if values['sell_gold'] and values['buy_gold']:
            max_buy = max(val for prof, val, line in values['buy_gold'])
            min_sell = min(val for prof, val, line in values['sell_gold'])
            # We allow max_buy == min_sell, but max_buy > min_sell is arbitrage!
            if max_buy > min_sell:
                disparities_found = True
                print(f"❌ ARBITRAGE DETECTED: {item}")
                print(f"    Max Buy Price: {max_buy:.4f} gold/unit")
                print(f"    Min Sell Price: {min_sell:.4f} gold/unit")

    if disparities_found:
        print("\nEconomy is UNSTABLE! Disparities or arbitrage loops were found.")
        sys.exit(1)
    else:
        print("✅ Economy is perfectly balanced and consistent. No disparities found.")
        sys.exit(0)

if __name__ == "__main__":
    path = "trades.lua"
    if len(sys.argv) > 1:
        path = sys.argv[1]
    check_disparities(path)
