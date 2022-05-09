local function file_exists(file_name)
	local found = false
	for k, searcher in next, package.searchers do
		found = found or searcher(file_name)
	end
	return found
end
local indicators
if file_exists("crosshair_indicators.lua") then
	indicators = require("crosshair_indicators")
end
local ffi = require("ffi")
local vector = require"vector"
ffi.cdef([[
    typedef void*(__thiscall* get_client_entity_t)(void*, int);
]])

local function vmt_entry(instance, index, type)
    return ffi.cast(type, (ffi.cast("void***", instance)[0])[index])
end
local function vmt_thunk(index, typestring)
    local t = ffi.typeof(typestring)
    return function(instance, ...)
        assert(instance ~= nil)
        if instance then
            return vmt_entry(instance, index, t)(instance, ...)
        end
    end
end
local get_abs_angles = vmt_thunk(11, "float*(__thiscall*)(void*)")
local entitylist = ffi.cast(ffi.typeof("void***"), client.create_interface("client.dll", "VClientEntityList003"));
local get_client_entity = ffi.cast("get_client_entity_t", entitylist[0][3])

local multiselect_target_hitbox = ui.reference("rage", "aimbot", "Target hitbox")
local toggle_shieldbot = ui.new_checkbox("rage", "other", "Avoid shielded players")
local toggle_shieldbot_indicator = ui.new_checkbox("rage", "other", "Feet indicator")
local color_shieldbot_indicator = ui.new_color_picker("rage", "other", "Feet indicator color", 255, 255, 0, 255)
local multiselect_shieldbot_hitboxes = ui.new_multiselect("rage", "Other", "Return hitboxes",
	"Head", "Chest",
	"Stomach", "Arms",
	"Legs", "Feet"
)
local slider_shieldbot_angle_scale = ui.new_slider("rage", "other", "Angle scale", 10, 150, 80, true, "dg") -- idk why ° isn't supported by gs menu but ok

do -- config shit
	local update_ui = function()
		ui.set_visible(multiselect_shieldbot_hitboxes, ui.get(toggle_shieldbot))
		ui.set_visible(slider_shieldbot_angle_scale, ui.get(toggle_shieldbot))
		ui.set_visible(toggle_shieldbot_indicator, ui.get(toggle_shieldbot))
		local list = ui.get(multiselect_shieldbot_hitboxes)
		if #list == 0 then
			ui.set(multiselect_shieldbot_hitboxes, { "Head" })
		end
	end
	client.set_event_callback("post_config_load", update_ui)
	ui.set_callback(multiselect_shieldbot_hitboxes, update_ui)
	ui.set_callback(toggle_shieldbot, update_ui)
	update_ui()
end

local fire_time, shieldbot_target = 0
local timeout = 2

client.set_event_callback("aim_fire", function(e)
	shieldbot_target = e.target
	fire_time = globals.curtime()
end)

client.set_event_callback("player_death", function(e)
	if shieldbot_target and e.userid == entity.get_steam64(shieldbot_target) then
		shieldbot_target = nil
	end
end)

client.set_event_callback("paint", function()
	local curtime = globals.curtime()
	if curtime - fire_time > timeout then
		fire_time = 0
	end
	local local_player = entity.get_local_player()
	if ui.get(toggle_shieldbot) and local_player then
		local local_position = vector(entity.get_origin(local_player))
		local shield
		local player = shieldbot_target
		if fire_time < curtime or not shieldbot_target or not entity.is_alive(shieldbot_target) then
			for i = 1, globals.maxplayers() do
				local esp_data = entity.get_esp_data(i)
				if esp_data and bit.band(esp_data.flags, 2048) ~= 0 then
					player = i
				end
			end
		end
		if player then
			for i = 0, 63 do
				local k = entity.get_prop(player, "m_hMyWeapons", i)
				if k and entity.get_classname(k) == "CWeaponShield" then
					shield = k
					break
				end
			end
			if shield then
				local x, y, z = entity.get_origin(player)
				local position = vector(x,y,z)
				local _, angle_to = position:to(local_position):angles()
				local angle = get_abs_angles(get_client_entity(entitylist, shield))[1]
				local angle_to = (angle - angle_to) % 360
				
				local mult = (ui.get(slider_shieldbot_angle_scale))
				local shield_angles = { 180 - mult, 180 + mult } -- this is braindead
				
				if ui.is_menu_open() then -- ugly as fuck
					local x1,y1 = renderer.world_to_screen(x,y,z)
					local angle_diff = math.rad(angle + shield_angles[1])
					local x2, y2 = renderer.world_to_screen(x+math.cos(angle_diff) * 100,y+math.sin(angle_diff) * 100, z)
					renderer.line(x1,y1,x2,y2, 255, 255, 255, 255)
					angle_diff = math.rad(angle + shield_angles[2])
					x2, y2 = renderer.world_to_screen(x+math.cos(angle_diff) * 100,y+math.sin(angle_diff) * 100, z)
					renderer.line(x1,y1,x2,y2, 255, 255, 255, 255)
				end
				
				if angle_to < shield_angles[1] or angle_to > shield_angles[2] then
					ui.set(multiselect_target_hitbox, ui.get(multiselect_shieldbot_hitboxes))
				else
					ui.set(multiselect_target_hitbox, { "Feet" })
					if ui.get(toggle_shieldbot_indicator) then
						local r,g,b,a = ui.get(color_shieldbot_indicator)
						renderer.indicator(r, g, b, a, "FEET")
						if indicators then
							indicators.bottom(r, g, b, a, "FEET")
						end
					end
				end
			else
				ui.set(multiselect_target_hitbox, ui.get(multiselect_shieldbot_hitboxes))
			end
		end
	end
end)
