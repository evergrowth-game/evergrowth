import os
import re
from collections import defaultdict
import math

def parse_trades(init_lua_path):
    with open(init_lua_path, 'r') as f:
        lines = f.readlines()

    edges = []
    current_prof = None
    in_trades_list = False

    for line in lines:
        if 'eg_settlers.trades_list =' in line:
            in_trades_list = True
            continue
            
        if in_trades_list and line.strip() == '}':
            in_trades_list = False
            continue

        if in_trades_list:
            prof_match = re.match(r'\s+([a-zA-Z_]+)\s*=\s*\{', line)
            if prof_match:
                current_prof = prof_match.group(1)
                continue

        pool_match = re.match(r'eg_settlers\.([a-zA-Z_]+)_master_pool\s*=\s*\{', line)
        if pool_match:
            current_prof = pool_match.group(1)
            
        trade_match = re.search(r'\{"([^" ]+)\s+(\d+)",\s*"([^" ]+)\s+(\d+)",\s*(\d+)\}', line)
        if trade_match and current_prof:
            goods_item, goods_qty, price_item, price_qty, chance = trade_match.groups()
            goods_qty = float(goods_qty)
            price_qty = float(price_qty)
            
            # price_item -> goods_item
            # rate: how much of get_item you receive for 1 give_item
            rate = goods_qty / price_qty
            
            # Forward edge (what the player can do)
            # Player gives price_item, gets goods_item
            edges.append({
                'from': price_item,
                'from_qty': price_qty,
                'to': goods_item,
                'to_qty': goods_qty,
                'rate': rate,
                'prof': current_prof
            })

    return edges

def find_arbitrage(edges):
    nodes = set()
    for e in edges:
        nodes.add(e['from'])
        nodes.add(e['to'])
        
    nodes = list(nodes)
    distance = {n: float('inf') for n in nodes}
    distance['default:gold_lump'] = 0  # Start constraint
    
    predecessor = {n: None for n in nodes}
    edge_used = {n: None for n in nodes}
    
    for _ in range(len(nodes) - 1):
        for e in edges:
            u = e['from']
            v = e['to']
            weight = -math.log(e['rate'])
            if distance[u] + weight < distance[v] - 1e-9:
                distance[v] = distance[u] + weight
                predecessor[v] = u
                edge_used[v] = e

    arbitrage_cycles = []
    visited_for_cycle = set()
    
    for e in edges:
        u = e['from']
        v = e['to']
        weight = -math.log(e['rate'])
        if distance[u] + weight < distance[v] - 1e-9:
            curr = v
            visited = []
            while curr not in visited and curr is not None:
                visited.append(curr)
                curr = predecessor[curr]
                
            if curr is not None:
                cycle_start_idx = visited.index(curr)
                cycle_nodes = visited[cycle_start_idx:]
                cycle_nodes.reverse() 
                
                cycle_set = frozenset(cycle_nodes)
                if cycle_set not in visited_for_cycle:
                    visited_for_cycle.add(cycle_set)
                    
                    cycle_edges = []
                    for i in range(len(cycle_nodes)):
                        u_cycle = cycle_nodes[i]
                        v_cycle = cycle_nodes[(i+1)%len(cycle_nodes)]
                        # Find corresponding edge
                        for ce in edges:
                            if ce['from'] == u_cycle and ce['to'] == v_cycle and ce == edge_used[v_cycle]:
                                cycle_edges.append(ce)
                                break
                                
                    if cycle_edges:
                        arbitrage_cycles.append(cycle_edges)

    return arbitrage_cycles

def audit():
    init_lua_path = os.path.join(os.path.dirname(__file__), "../npc/trades.lua")
    edges = parse_trades(init_lua_path)
    if not edges:
        print("No trades returned by parser.")
        return
        
    print("=== EVERGROWTH ECONOMY AUDIT ===")
    print(f"Loaded {len(edges)} trades.\n")
    
    cycles = find_arbitrage(edges)
    
    if not cycles:
        print("PASS: No arbitrage cycles found. Economy mathematically secure against infinite trade loops.")
    else:
        print(f"FAIL: Found {len(cycles)} arbitrage loops generating infinite wealth.\n")
        for i, cycle in enumerate(cycles):
            print(f"--- Loop {i+1} ---")
            multiplier = 1.0
            for e in cycle:
                print(f"Trade with {e['prof']:<11}: Give {e['from_qty']:>3g} {e['from']:<20} -> Get {e['to_qty']:>3g} {e['to']}")
                multiplier *= e['rate']
            print(f"Arbitrage Multiplier: {multiplier:.2f}x per iteration\n")

if __name__ == "__main__":
    audit()
