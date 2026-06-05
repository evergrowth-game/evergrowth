--[[
    Evergrowth Villages - Settlement Database
    =========================================
    Provides persistence and CRUD operations for the Town Ledger system.
    Uses a dirty-flag pattern to batch disk writes.
]]--

local S = minetest.get_translator("eg_settlers")

eg_settlers.db = {}

local DB_FILE = minetest.get_worldpath() .. "/evergrowth_settlements.dat"

local db_data = {
    next_id = 1,
    settlements = {}
}

local is_dirty = false

function eg_settlers.db.load()
    local file = io.open(DB_FILE, "r")
    if file then
        local content = file:read("*a")
        file:close()
        local data = minetest.deserialize(content)
        if data then
            db_data = data
        end
    end
end

function eg_settlers.db.mark_dirty()
    is_dirty = true
end

function eg_settlers.db.save()
    if is_dirty then
        local file = io.open(DB_FILE, "w")
        if file then
            file:write(minetest.serialize(db_data))
            file:close()
            is_dirty = false
        else
            minetest.log("error", "[eg_settlers] Failed to write settlement database!")
        end
    end
end

minetest.register_on_shutdown(eg_settlers.db.save)

-- Dirty flag flush timer (60 seconds)
local flush_timer = 0
minetest.register_globalstep(function(dtime)
    flush_timer = flush_timer + dtime
    if flush_timer >= 60.0 then
        flush_timer = 0
        eg_settlers.db.save()
    end
end)

-- CRUD
function eg_settlers.db.create_settlement(ledger_pos, name)
    local id = tostring(db_data.next_id)
    db_data.next_id = db_data.next_id + 1
    
    db_data.settlements[id] = {
        name = name,
        ledger_pos = {x=ledger_pos.x, y=ledger_pos.y, z=ledger_pos.z},
        reserve_points = 0,
        satiated = 0,
        last_tick_gametime = minetest.get_gametime(),
        residents = {}
    }
    eg_settlers.db.mark_dirty()
    return id
end

function eg_settlers.db.delete_settlement(settlement_id)
    if db_data.settlements[settlement_id] then
        db_data.settlements[settlement_id] = nil
        eg_settlers.db.mark_dirty()
    end
end

function eg_settlers.db.get_settlement(settlement_id)
    return db_data.settlements[settlement_id]
end

function eg_settlers.db.get_settlement_at(ledger_pos)
    for id, s in pairs(db_data.settlements) do
        if vector.equals(s.ledger_pos, ledger_pos) then
            return id, s
        end
    end
    return nil, nil
end

function eg_settlers.db.set_name(settlement_id, name)
    local s = db_data.settlements[settlement_id]
    if s then
        s.name = name
        eg_settlers.db.mark_dirty()
    end
end

function eg_settlers.db.register_resident(settlement_id, deed_pos, resident_name, profession)
    local s = db_data.settlements[settlement_id]
    if s then
        local pos_str = deed_pos.x .. "," .. deed_pos.y .. "," .. deed_pos.z
        s.residents[pos_str] = {
            name = resident_name,
            profession = profession or "Unknown"
        }
        eg_settlers.db.mark_dirty()
    end
end

function eg_settlers.db.unregister_resident(settlement_id, deed_pos)
    local s = db_data.settlements[settlement_id]
    if s then
        local pos_str = deed_pos.x .. "," .. deed_pos.y .. "," .. deed_pos.z
        if s.residents[pos_str] then
            s.residents[pos_str] = nil
            eg_settlers.db.mark_dirty()
        end
    end
end

function eg_settlers.db.get_resident_count(settlement_id)
    local s = db_data.settlements[settlement_id]
    if not s then return 0 end
    local count = 0
    for _ in pairs(s.residents) do
        count = count + 1
    end
    return count
end

function eg_settlers.db.add_food(settlement_id, points)
    local s = db_data.settlements[settlement_id]
    if s and points > 0 then
        s.reserve_points = s.reserve_points + points
        if s.satiated == 0 then
            s.satiated = 1
        end
        eg_settlers.db.mark_dirty()
    end
end

function eg_settlers.db.process_daily_tick(settlement_id, time_diff)
    local s = db_data.settlements[settlement_id]
    if s then
        local total_days = math.floor(time_diff / 1200)
        local capped_days = math.min(30, total_days)
        
        local resident_count = eg_settlers.db.get_resident_count(settlement_id)
        local demand = resident_count * 4 * capped_days
        s.reserve_points = math.max(0, s.reserve_points - demand)
        
        if s.reserve_points > 0 then
            s.satiated = 1
        else
            s.satiated = 0
        end
        
        s.last_tick_gametime = s.last_tick_gametime + (total_days * 1200)
        eg_settlers.db.mark_dirty()
    end
end

function eg_settlers.db.is_satiated(settlement_id)
    local s = db_data.settlements[settlement_id]
    if s then
        return s.satiated == 1
    end
    return false
end

function eg_settlers.db.get_all_settlement_ids()
    local ids = {}
    for id, _ in pairs(db_data.settlements) do
        table.insert(ids, id)
    end
    return ids
end

function eg_settlers.db.find_nearest_settlement(pos, max_radius)
    local nearest_id = nil
    local nearest_dist = max_radius + 1
    
    for id, s in pairs(db_data.settlements) do
        local dist = vector.distance(pos, s.ledger_pos)
        if dist <= max_radius and dist < nearest_dist then
            nearest_dist = dist
            nearest_id = id
        end
    end
    
    return nearest_id
end

-- Food Value Scanner
eg_settlers.food_values = {}

function eg_settlers.get_food_value(item_name)
    return eg_settlers.food_values[item_name]
end

minetest.register_on_mods_loaded(function()
    for item_name, def in pairs(minetest.registered_items) do
        if def.on_use then
            local value = nil
            
            -- Layer A: explicit food group value
            if def.groups and def.groups.food and def.groups.food > 0 then
                value = def.groups.food
            end
            
            -- Layer B/C: fallback for known food mods or generic food group
            if not value then
                if def.groups and def.groups.food then
                    value = 1
                elseif string.sub(item_name, 1, 8) == "farming:" then
                    value = 2
                elseif string.sub(item_name, 1, 9) == "ethereal:" and string.match(item_name, "fish_") then
                    value = 2
                elseif string.sub(item_name, 1, 5) == "wine:" then
                    value = 2
                end
            end
            
            if value then
                eg_settlers.food_values[item_name] = value
            end
        end
    end
end)

-- Load immediately
eg_settlers.db.load()
