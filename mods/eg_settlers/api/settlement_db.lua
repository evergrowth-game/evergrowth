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
            db_data.settlements = db_data.settlements or {}
            db_data.next_id = db_data.next_id or 1
            -- Migration hook for legacy unowned settlements and Phase 3 integrity data
            for id, s in pairs(db_data.settlements) do
                local updated = false
                if not s.owner then
                    s.owner = minetest.settings:get("name") or "singleplayer"
                    updated = true
                end
                if not s.associates then
                    s.associates = {}
                    updated = true
                end
                if not s.death_log then
                    s.death_log = {}
                    updated = true
                end
                if not s.historical_fallen_count then
                    s.historical_fallen_count = 0
                    updated = true
                end
                if not s.criminal_records then
                    s.criminal_records = {}
                    updated = true
                end
                if updated then
                    eg_settlers.db.mark_dirty()
                end
            end
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
function eg_settlers.db.create_settlement(ledger_pos, name, owner)
    local id = tostring(db_data.next_id)
    db_data.next_id = db_data.next_id + 1
    
    db_data.settlements[id] = {
        name = name,
        ledger_pos = {x=ledger_pos.x, y=ledger_pos.y, z=ledger_pos.z},
        reserve_points = 0,
        satiated = 0,
        last_tick_gametime = minetest.get_gametime(),
        residents = {},
        owner = owner or "",
        associates = {},
        death_log = {},
        historical_fallen_count = 0,
        criminal_records = {},
        strike_records = {}
    }
    eg_settlers.db.mark_dirty()
    return id
end

function eg_settlers.db.is_owner(settlement_id, name)
    if not name or name == "" then
        return false
    end
    if minetest.is_singleplayer() then
        return true
    end
    local s = db_data.settlements[settlement_id]
    if s then
        return s.owner == name
    end
    return false
end

function eg_settlers.db.is_authorized(settlement_id, name)
    if not name or name == "" then
        return false
    end
    local s = db_data.settlements[settlement_id]
    if s then
        if s.owner == name then
            return true
        end
        for _, assoc in ipairs(s.associates) do
            if assoc == name then
                return true
            end
        end
        -- Check for admin bypass privilege
        if minetest.check_player_privs(name, {protection_bypass = true}) or
           minetest.check_player_privs(name, {server = true}) or
           minetest.is_singleplayer() then
            return true
        end
    end
    return false
end

function eg_settlers.db.add_associate(settlement_id, name)
    local s = db_data.settlements[settlement_id]
    if s then
        -- Check if already associate
        for _, assoc in ipairs(s.associates) do
            if assoc == name then
                return false
            end
        end
        table.insert(s.associates, name)
        eg_settlers.db.mark_dirty()
        return true
    end
    return false
end

function eg_settlers.db.remove_associate(settlement_id, name)
    local s = db_data.settlements[settlement_id]
    if s then
        for i, assoc in ipairs(s.associates) do
            if assoc == name then
                table.remove(s.associates, i)
                eg_settlers.db.mark_dirty()
                return true
            end
        end
    end
    return false
end

function eg_settlers.db.transfer_ownership(settlement_id, new_owner)
    local s = db_data.settlements[settlement_id]
    if s and new_owner and new_owner ~= "" then
        s.owner = new_owner
        eg_settlers.db.mark_dirty()
        return true
    end
    return false
end

function eg_settlers.db.delete_settlement(settlement_id)
    if db_data.settlements[settlement_id] then
        db_data.settlements[settlement_id] = nil
        eg_settlers.db.mark_dirty()
    end
end

function eg_settlers.db.get_settlement_by_deed(deed_pos)
    if not deed_pos then return nil end
    local pos_str = deed_pos.x .. "," .. deed_pos.y .. "," .. deed_pos.z
    for id, s in pairs(db_data.settlements) do
        if s.residents[pos_str] then
            return id
        end
    end
    return nil
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

function eg_settlers.db.get_town_tier(settlement_id)
    local s = db_data.settlements[settlement_id]
    if not s then return 1, S("Outpost") end
    
    local pos = s.ledger_pos
    local r = 200
    local has_granary = #minetest.find_nodes_in_area(vector.subtract(pos, r), vector.add(pos, r), {"eg_settlers:town_granary"}) > 0
    local has_depot = #minetest.find_nodes_in_area(vector.subtract(pos, r), vector.add(pos, r), {"eg_settlers:town_depot"}) > 0
    local has_ward = #minetest.find_nodes_in_area(vector.subtract(pos, r), vector.add(pos, r), {"eg_settlers:ward_stone"}) > 0
    local has_board = #minetest.find_nodes_in_area(vector.subtract(pos, r), vector.add(pos, r), {"eg_settlers:job_board"}) > 0

    if has_depot and has_ward and has_board then
        return 3, S("Village"), 20
    elseif has_granary then
        return 2, S("Hamlet"), 8
    else
        return 1, S("Outpost"), 3
    end
end

function eg_settlers.db.get_population_cap(settlement_id)
    local tier_num, tier_name, tier_cap = eg_settlers.db.get_town_tier(settlement_id)
    return tier_cap
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
        eg_settlers.db.decay_reputation_tick(settlement_id, capped_days)
        eg_settlers.db.mark_dirty()
    end
end

function eg_settlers.db.log_death(settlement_id, death_info)
    local s = db_data.settlements[settlement_id]
    if s then
        s.death_log = s.death_log or {}
        s.historical_fallen_count = s.historical_fallen_count or 0
        
        local entry = {
            id = string.format("death_%d_%04d", os.time(), math.random(1, 9999)),
            settler_name = death_info.settler_name or "Unknown Settler",
            profession = death_info.profession or "Settler",
            skin = death_info.skin or "",
            pos = death_info.pos and {x = death_info.pos.x, y = death_info.pos.y, z = death_info.pos.z} or {x=0, y=0, z=0},
            cause = death_info.cause or "Unknown",
            killer = death_info.killer or "Unknown",
            timestamp = os.time(),
            status = death_info.status or "Unburied"
        }
        
        table.insert(s.death_log, 1, entry)
        
        while #s.death_log > 25 do
            table.remove(s.death_log)
            s.historical_fallen_count = s.historical_fallen_count + 1
        end
        
        eg_settlers.db.mark_dirty()
        return entry.id
    end
    return nil
end

function eg_settlers.db.record_crime(settlement_id, player_name, crime_type)
    if not player_name or player_name == "" then return end
    local s = db_data.settlements[settlement_id]
    if s then
        s.criminal_records = s.criminal_records or {}
        local rec = s.criminal_records[player_name] or { assault_count = 0, murder_count = 0, last_offense_time = os.time() }
        if crime_type == "assault" then
            rec.assault_count = rec.assault_count + 1
        elseif crime_type == "murder" then
            rec.murder_count = rec.murder_count + 1
        end
        rec.last_offense_time = os.time()
        s.criminal_records[player_name] = rec
        eg_settlers.db.mark_dirty()
    end
end

function eg_settlers.db.is_criminal(settlement_id, player_name)
    if not player_name or player_name == "" then return false end
    local s = db_data.settlements[settlement_id]
    if s and s.criminal_records then
        local rec = s.criminal_records[player_name]
        if rec then
            if (rec.murder_count and rec.murder_count > 0) or (rec.assault_count and rec.assault_count > 0) then
                return true
            end
        end
    end
    return false
end

function eg_settlers.db.get_criminal_record(settlement_id, player_name)
    local s = db_data.settlements[settlement_id]
    if s and s.criminal_records and player_name then
        return s.criminal_records[player_name]
    end
    return nil
end

function eg_settlers.db.get_decay_time_estimate(settlement_id, player_name)
    local s = db_data.settlements[settlement_id]
    if s and s.criminal_records and player_name then
        local rec = s.criminal_records[player_name]
        if rec and rec.assault_count and rec.assault_count > 0 then
            local gametime = minetest.get_gametime()
            local time_diff = math.max(0, gametime - (s.last_tick_gametime or gametime))
            local total_sec_cycle = 3600 -- 3 in-game days = 3600 seconds
            local sec_into_cycle = time_diff % total_sec_cycle
            local sec_remaining = total_sec_cycle - sec_into_cycle
            
            local days_remaining = math.floor(sec_remaining / 1200)
            local mins_remaining = math.max(1, math.ceil(sec_remaining / 60))
            return days_remaining, mins_remaining
        end
    end
    return 0, 0
end

function eg_settlers.db.register_punch(settlement_id, player_name, damage_dealt, is_weapon, is_owner)
    local s = db_data.settlements[settlement_id]
    if not s then return "assault" end
    
    s.strike_records = s.strike_records or {}
    local rec = s.strike_records[player_name]
    local now = minetest.get_gametime()
    local window = is_owner and 300 or 180 -- 5 minutes for owner, 3 minutes for visitor
    
    damage_dealt = math.max(1, damage_dealt or 1)
    
    -- Heavy weapon hit (>= 4 HP damage) immediately escalates
    if is_weapon and damage_dealt >= 4 then
        s.strike_records[player_name] = { strike_count = 2, cumulative_damage = damage_dealt, last_punch_time = now }
        eg_settlers.db.mark_dirty()
        return "assault"
    end

    if not rec or (now - (rec.last_punch_time or 0)) > window then
        -- New strike window
        s.strike_records[player_name] = {
            strike_count = 1,
            cumulative_damage = damage_dealt,
            last_punch_time = now
        }
        eg_settlers.db.mark_dirty()
        return "warning"
    else
        -- Rapid input debounce (< 0.35s) to filter accidental double-clicks
        if (now - (rec.last_punch_time or 0)) < 0.35 then
            return "warning"
        end

        rec.strike_count = (rec.strike_count or 0) + 1
        rec.cumulative_damage = (rec.cumulative_damage or 0) + damage_dealt
        rec.last_punch_time = now
        eg_settlers.db.mark_dirty()

        -- Escalation condition: cumulative damage >= 4 HP OR 4 strikes within window
        if rec.cumulative_damage >= 4 or rec.strike_count >= 4 then
            return "assault"
        else
            return "warning"
        end
    end
end

function eg_settlers.db.pay_restitution(settlement_id, player_name, fine_type)
    local s = db_data.settlements[settlement_id]
    if s and s.criminal_records and player_name then
        local rec = s.criminal_records[player_name]
        if rec then
            if fine_type == "assault" then
                rec.assault_count = 0
            elseif fine_type == "murder" then
                rec.murder_count = 0
            end
            if rec.assault_count <= 0 and rec.murder_count <= 0 then
                s.criminal_records[player_name] = nil
            end
            eg_settlers.db.mark_dirty()
            return true
        end
    end
    return false
end

function eg_settlers.db.decay_reputation_tick(settlement_id, days_passed)
    local s = db_data.settlements[settlement_id]
    if s and s.criminal_records then
        local ticks = math.max(1, days_passed or 1)
        local decay_amount = math.floor(ticks / 3)
        if decay_amount > 0 then
            local updated = false
            for pname, rec in pairs(s.criminal_records) do
                if rec.assault_count and rec.assault_count > 0 then
                    rec.assault_count = math.max(0, rec.assault_count - decay_amount)
                    updated = true
                    if rec.assault_count == 0 and (not rec.murder_count or rec.murder_count == 0) then
                        s.criminal_records[pname] = nil
                    end
                end
            end
            if updated then
                eg_settlers.db.mark_dirty()
            end
        end
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
    local def = minetest.registered_items[item_name]
    if def and def.groups and def.groups.eatable and def.groups.eatable > 0 then
        return def.groups.eatable
    end
    return eg_settlers.food_values[item_name]
end

minetest.register_on_mods_loaded(function()
    for item_name, def in pairs(minetest.registered_items) do
        if def.on_use then
            local value = nil
            
            -- Layer A: explicit food group value
            if def.groups then
                if def.groups.eatable and def.groups.eatable > 0 then
                    value = def.groups.eatable
                elseif def.groups.food and def.groups.food > 0 then
                    value = def.groups.food
                end
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
