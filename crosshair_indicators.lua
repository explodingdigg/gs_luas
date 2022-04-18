local pos_data = {
	top = 0,
	bottom = 0
}

local function contains(tbl, val)
	for i = 1, #tbl do
		if tbl[i] == val then return true end
	end
	return false
end

local function get_crosshair_offset()
	local gap = cvar.cl_crosshairgap
	local size = cvar.cl_crosshairsize 
	return gap:get_int() + 4 + size:get_int() * 2
end


local indicator_manager = {
	top = function(r,g,b,a,...) end,
	bottom = function(r,g,b,a,...) end,
}

indicator_manager.top = function(r, g, b, a, ...)
	local w, h = client.screen_size()
	pos_data.top = pos_data.top + 1
	local offset = get_crosshair_offset()+8*pos_data.top
	renderer.text(w/2, h/2-offset, r, g, b, a, "-c", 99, ...)
end

indicator_manager.bottom = function(r, g, b, a, ...)
	local w, h = client.screen_size()
	pos_data.bottom = pos_data.bottom + 1
	local offset = get_crosshair_offset()+8*pos_data.bottom
	renderer.text(w/2, h/2+offset, r, g, b, a, "-c", 99, ...)
end

local function get_min_dmg_text(n)
	if n > 100 then
		return string.format("hp+%d", n-100)
	elseif n <= 0 then
		return "auto"
	else
		return string.format("%dhp", n)
	end
end

local slider_min_dmg = ui.reference("RAGE", "Aimbot", "Minimum damage")
local slider_min_hitchance = ui.reference("RAGE", "Aimbot", "Minimum hit chance")
local keybind_fake_duck = ui.reference("RAGE", "Other", "Duck peek assist")
local keybind_double_tap = ui.reference("RAGE", "Other", "Double tap") + 1

local multiselect_indicators = ui.new_multiselect("LUA", "A", "Crosshair indicators",
	{"Double tap", "Minimum damage",
	"Fake duck", "Velocity",
	"Minimum hit chance", "Frames per second",
	"Health", "Ammo",
	}
)
client.set_event_callback("paint_ui", function()
	pos_data.top = 0
	pos_data.bottom = 0
end)

local fps = 80
client.set_event_callback("paint", function()
	local local_player = entity.get_local_player()
	
	if local_player and entity.is_alive(local_player) then
		local w, h = client.screen_size()
		local values = ui.get(multiselect_indicators)
		if contains(values, "Minimum damage") then
			indicator_manager.top(255, 255, 255, 255, get_min_dmg_text(ui.get(slider_min_dmg)))
		end
		if contains(values, "Minimum hit chance") then
			indicator_manager.top(255, 255, 255, 255, ui.get(slider_min_hitchance), "%")
		end
		if contains(values, "Health") then
			indicator_manager.bottom(200, 15, 100, 255, "+"..entity.get_prop(local_player, "m_iHealth"))
		end
		if contains(values, "Ammo") then
			local weapon = entity.get_prop(local_player, "m_hActiveWeapon")
			local ammo = entity.get_prop(weapon, "m_iClip1")
			local reserve = entity.get_prop(weapon, "m_iPrimaryReserveAmmoCount")

			indicator_manager.bottom(255, 200, 80, 255, string.format("%d/%d", ammo, reserve))
		end
		if contains(values, "Velocity") then
			local velox = math.ceil(math.abs(entity.get_prop(local_player, 'm_vecVelocity')))
			local veloy = math.ceil(math.abs(entity.get_prop(local_player, 'm_vecVelocity[1]')))
			local velo = tostring(math.floor(math.sqrt(velox^2+veloy^2))) .. " u/s"
			
			indicator_manager.bottom(255, 255, 255, 255, velo)
		end
		if contains(values, "Fake duck") then
			if ui.get(keybind_fake_duck) then
				indicator_manager.bottom(100, 100, 255, 255, "DUCK")
			end
		end
		if contains(values, "Double tap") then
			if ui.get(keybind_double_tap) then
				indicator_manager.bottom(255, 125, 100, 255, "DT")
			end
		end
		if contains(values, "Frames per second") then
			fps = (1 / globals.frametime() + fps * 40) / 41
			indicator_manager.bottom(255, 255, 255, 255, math.floor(fps).."f/s")
		end
	end
end)

return indicator_manager
