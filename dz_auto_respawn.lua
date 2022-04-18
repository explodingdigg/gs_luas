local PREFIX_LOCATION = "auto_respawn_location_"
local function get_respawn_location(map)
	return database.read(PREFIX_LOCATION .. map)
end
local function set_respawn_location(map, location)
	database.write(PREFIX_LOCATION .. map, location)
end
local function get_respawn_gear()
	return database.read("auto_respawn_gear")
end
local function set_respawn_gear(gear)
	database.write("auto_respawn_gear", gear)
end
local toggle_respawn_location = ui.new_checkbox("lua", "b", "Danger zone auto spawn location")
local button_reset_location = ui.new_button("lua", "b", "Reset spawn location", function()
	local map = globals.mapname()
	if map then
		return set_respawn_location(map)
	end
end)

local function update_menu_objects()
	ui.set_visible(button_reset_location, ui.get(toggle_respawn_location))
end
update_menu_objects()

client.set_event_callback("post_config_load", update_menu_objects)
ui.set_callback(toggle_respawn_location, update_menu_objects)

client.set_event_callback("round_start", function()
	local warmup = entity.get_prop(game_rules, "m_bWarmupPeriod") == 0
	if cvar.game_type:get_int() == 6 and not warmup then
		local map = globals.mapname()
		database.write("last_dz_map", map)
		if ui.get(toggle_respawn_location) then
			local location = get_respawn_location(map)
			if location then
				client.exec(location)
			end
		end
		local gear = get_respawn_gear()
		if gear then
			client.exec(gear)
		end
	end
end)

client.set_event_callback("paint", function()
	if cvar.game_type:get_int() == 6 and ui.get(toggle_respawn_location) then
		local map = globals.mapname()
		if not get_respawn_location(map) then
			renderer.text(200, 200, 255, 0, 0, 125, "+", nil, "Respawn location not set")
		end
	end
end)

client.set_event_callback("string_cmd", function(e)
	if e.text:match("dz_spawnselect_choose_hex") and ui.get(toggle_respawn_location) then
		local map = globals.mapname()
		set_respawn_location(map, e.text)
	end
	if e.text:match("survival_equip") then
		set_respawn_gear(e.text)
	end
end)
