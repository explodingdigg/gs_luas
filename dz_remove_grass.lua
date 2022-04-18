--removing danger zone grass original credit to infirms1337 on forum
local remove_grass = ui.new_checkbox("visuals", "effects", "Remove danger zone grass")
local grass_state = false
local function grass_on_update()
	grass_state = false
end
ui.set_callback(remove_grass, grass_on_update)
client.set_event_callback("player_connect_full", grass_on_update) --works between games
local function grass_remove()
	local map_name = globals.mapname()
	local bool = ui.get(remove_grass)
	if map_name == "dz_blacksite" then
		local grass = materialsystem.find_materials("detail/detailsprites_survival")
		for i = 1, #grass do
			grass[i]:set_material_var_flag(2, bool)
		end
	elseif map_name == "dz_sirocco" then
		local grass = materialsystem.find_materials("detail/dust_massive_detail_sprites")
		for i = 1, #grass do
			grass[i]:set_material_var_flag(2, bool)
		end
	elseif map_name == "dz_frostbite" then
		local grass = materialsystem.find_materials("ski/detail/detailsprites_overgrown_ski")
		for i = 1, #grass do
			grass[i]:set_material_var_flag(2, bool)
		end	
	elseif map_name == "dz_county" then
		local grass = materialsystem.find_material("detail/county/detailsprites_county")
		grass:set_material_var_flag(2, bool)
	else
		local mats = materialsystem.find_materials("detail/") -- this is really bad but it just makes it so i don"t have to update for every map
		for i = 1, #mats do
			mats[i]:set_material_var_flag(2, bool)
		end
	end
end
client.set_event_callback("net_update_end", function()
	if not grass_state then
		grass_remove()
		grass_state = true
	end
end)
client.set_event_callback("shutdown", function()
	grass_state = false
end)
