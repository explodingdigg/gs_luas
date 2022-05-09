local keys = { w=0x57,a=0x41,s=0x53,d=0x44 } -- dumb hack to make it work on my keyboard
if database.read("colemak") then
	keys = { w=0x57,a=0x41,s=0x52,d=0x53 }
end
-- we can't use the setup_command to check directional movement,
-- so we have to use this instead

local function key_states(...)
	local keys = {...}
	for i = 1, #keys do
		keys[i] = client.key_state(keys[i])
	end
	return table.unpack(keys)
end

local toggle_exoboost = ui.new_checkbox("misc", "movement", "Exo jump speed hack")
local keybind_exoboost = ui.new_hotkey("misc", "movement", "Exo boost", true)

local ref = {
	air_strafe = ui.reference("misc", "movement", "air strafe"),
	strafe_direction = ui.reference("misc", "movement", "air strafe direction"),
	bunny_hop = ui.reference("misc", "movement", "bunny hop"),
	anti_aim = ui.reference("aa", "anti-aimbot angles", "enabled"),
	old_anti_aim = nil -- idk where else to put this.
}

local jump_time = 0
client.set_event_callback("setup_command", function(cmd) -- all logic located here
	if not ui.get(toggle_exoboost) then return end
	
	local local_player = entity.get_local_player()
	if not local_player then return end
	
	local x, y, z = entity.get_origin(local_player)
	local vel_z = entity.get_prop(local_player, "m_vecVelocity[2]")
	local on_ground = bit.band(entity.get_prop(local_player, "m_fFlags"), 1) == 1
	local rappeling = entity.get_prop(local_player, "m_bIsSpawnRappelling") == 1 -- avoid auto strafe with spawn rappel
	local in_water = entity.get_prop(local_player, "m_nWaterLevel") ~= 0 -- avoid auto strafe in water because it reduces speed
	
	ui.set(ref.air_strafe, not rappeling and not in_water)
	
	if not ui.get(keybind_exoboost) then return end
	
	if ref.old_anti_aim == nil then
		ref.old_anti_aim = ui.get(ref.anti_aim)
	end
	if jump_time < globals.curtime() then
		if ref.old_anti_aim ~= nil then -- enable anti aim after jumping so it jumps straight
			ui.set(ref.anti_aim, ref.old_anti_aim)
			ref.old_anti_aim = nil
		end
	else
		ui.set(ref.anti_aim, false)
	end
	ui.set(ref.air_strafe, not on_ground and not rappeling and not in_water)
	
	cmd.in_jump = ui.get(keybind_exoboost)
	cmd.in_duck = vel_z < 10 and not client.visible(x, y, z - 90) and not in_water -- crouching gives extra speed when landing
	
	if on_ground then
		jump_time = globals.curtime()
		if ref.old_anti_aim ~= nil then
			ui.set(ref.anti_aim, ref.old_anti_aim)
		end
		
		local strafe_directions = ui.get(ref.strafe_direction)
		local dir_x, dir_y = 0, 0
		
		for i, v in next, strafe_directions do -- i don't wanna use table_contains
			strafe_directions[v] = i
		end
		
		if strafe_directions["View angles"] then dir_y = 1 end
		if strafe_directions["Movement keys"] then
			local w, a, s, d = key_states(keys.w, keys.a, keys.s, keys.d) -- why doesn't key_state work like this? so much better
			if w or a or s or d then
				dir_y = 0 -- remaining true to the logic of having both on
				if w then dir_y = dir_y + 1 end
				if s then dir_y = dir_y - 1 end
				if a then dir_x = dir_x - 1 end
				if d then dir_x = dir_x + 1 end -- ugly but whatever
			end
		end
		
		local angle = (math.deg(math.atan2(dir_y, dir_x)) - 90) % 360
		local _, forward_yaw = client.camera_angles()
		
		cmd.yaw = forward_yaw + 140 + angle
		cmd.in_moveleft  = 0 -- for some reason these are really important for this to work
		cmd.in_moveright = 0
		cmd.forwardmove  = 0
		cmd.sidemove     = 0
	end
end)
