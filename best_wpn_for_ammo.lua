local csgo_weapons = require "gamesense/csgo_weapons"

local function contains(tbl, val)
	for i = 1, #tbl do
		if tbl[i] == val then return true end
	end
	return false
end

local toggle = ui.new_checkbox("lua", "a", "Show most common weapons")
local weapons = {}
local ignored_types = {"tablet", "c4", "grenade", "equipment", "fists", "bumpmine", "knife", "stackableitem", "taser", "breachcharge", "melee"}
local ignored_types = {["tablet"]=true, ["taser"]=true, ["c4"]=true, ["grenade"]=true, ["equipment"]=true, ["fists"]=true, ["bumpmine"]=true, ["knife"]=true, ["stackableitem"]=true, ["breachcharge"]=true, ["melee"]=true}
local weapons_type = {}
local function update_weapons()
	local entities = entity.get_all()
			weapons = {}
	for i = 1, #entities do
		local ent = entities[i]
		local weapon = csgo_weapons(ent)
		if weapon then
			
			if not weapons[weapon.idx] then
				weapons[weapon.idx] = 1
			else
				weapons[weapon.idx] = weapons[weapon.idx] + 1
			end
		end
	end
end
update_weapons()
client.set_event_callback("item_pickup", update_weapons)

client.set_event_callback("paint", function(d)
	if ui.get(toggle) then
		local weapons_copy = {}
		for name, v in next, weapons do
			weapons_copy[name] = v
		end
		weapons_type = {}
		local pos = 50
		local gap = 8
		for name, v in next, weapons_copy do
			local csgo_weapon = csgo_weapons[name]
			local wpn_t = csgo_weapon.type
			if not ignored_types[wpn_t] then
				if not weapons_type[wpn_t] then weapons_type[wpn_t] = {} end
				weapons_type[wpn_t][name] = weapons_copy[name]
			end
		end

		if weapons_type ~= {} then
			renderer.text(80, pos, 255, 0, 255, 255, "-", nil, "MOST COMMON WEAPONS")
			pos = pos + gap
		end
		for wpn_t, list in next, weapons_type do
			local ordered_by_size = {}
			renderer.text(100, pos, 255, 100, 255, 255, "-", nil, string.upper(wpn_t))
			pos = pos + gap
			local i = 1
			for i = 1, 3 do
				local most_name, most_val, most_i
				for index, v in next, weapons_type[wpn_t] do
					if v then
						local name = csgo_weapons[index].name
						if not most_val or most_val < v then
							most_name = name
							most_val = v
							most_i = index
						end
					end
				end
				if most_name then
					renderer.text(120, pos, 255, 255, 255, 255, "-", nil, most_val, "  ", string.upper(most_name))
					pos = pos + gap
				end
				if most_i then
					weapons_type[wpn_t][most_i] = nil
				end
			end
		end
	end
end)
