-- WARNING WARNING
-- THIS CODE IS REALLY SHIT. i haven't refactored it since i made it in the first place. you have been warned.
-- WARNING WARNING
local vector = require"vector"
local keys = database.read("colemak") and { 0x57,0x41,0x52,0x53 } or {	0x57,0x41,0x53,0x44 } -- dumb hack to make it work on my keyboard
local SPACE = 0x20
local CTRL = 0x11	
local toggle_exoboost = ui.new_checkbox("MISC", "Movement", "Exo jump speed hack")
local keybind_exoboost = ui.new_hotkey("MISC", "Movement", "Exo boost", true)
local toggle_crouch = ui.new_checkbox("MISC", "Movement", "Crouch on exo boost")
local color_indicators = ui.new_color_picker("misc", "Movement", "Show exo boost indicators", 255, 255, 255, 0)
local toggle_extend_jump = ui.new_checkbox("misc", "movement", "Extend normal first jump")

local jump_time = 0
local speed_enabled, standing, disabled, jumped, crouching, falling
local reference = {
	bhop = ui.reference("MISC", "Movement", "Bunny hop"),
	strafe = ui.reference("MISC", "Movement", "Air strafe"),
	strafe_direction = ui.reference("misc", "movement", "air strafe direction"),
	anti_aim = ui.reference("AA", "Anti-aimbot angles", "Enabled"),
	old_anti_aim = nil
}

local function update_ui()
	local exoboost = ui.get(toggle_exoboost)
	ui.set_visible(toggle_crouch, exoboost)
	ui.set_visible(color_indicators, exoboost)
end

ui.set_callback(toggle_exoboost, update_ui)
client.set_event_callback("post_config_load", update_ui)

local space_pressed, in_water
client.set_event_callback("paint", function()
	if not ui.get(toggle_exoboost) then return end
	local local_player = entity.get_local_player()
	if not local_player then return end
	local wearing_exojump = bit.band(entity.get_prop(local_player, "m_passiveItems", 1), 1) == 1
	if ui.get(toggle_extend_jump) and wearing_exojump then
		local last_space_pressed = space_pressed
		space_pressed = client.key_state(SPACE)
		if space_pressed ~= last_space_pressed and space_pressed then
			ui.set(reference.bhop, false)
			client.delay_call(0.5, ui.set, reference.bhop, true) -- super shit implementation but that's fine for now
		end
	end
	local x, y, z = entity.get_origin(local_player)
	in_water = entity.get_prop(local_player, "m_nWaterLevel") ~= 0
	standing = bit.band(entity.get_prop(local_player, "m_fFlags"), 1) == 1 -- on ground flag
	local rappeling = entity.get_prop(local_player, "m_bIsSpawnRappelling") == 1
	local velocity_z = entity.get_prop(local_player, "m_vecVelocity[2]")
	local floating = client.visible(x, y, z - 70)
	falling = velocity_z < 10 and not floating
	
	if speed_enabled and wearing_exojump then
		ui.set(reference.strafe, not (standing or rappeling))
		ui.set(reference.bhop, true)
		
		local r, g, b, a = ui.get(color_indicators)
		if a > 0 then
			local crouch_alpha = (falling or client.key_state(CTRL)) and a or a/3
			renderer.indicator(r, g, b, a, "BOOST")
			if ui.get(toggle_crouch) then
				renderer.indicator(r, g, b, crouch_alpha, "CROUCH")
			end
		end
	else
		ui.set(reference.strafe, not rappeling and not in_water)
	end
end)
local last_speed_enabled
client.set_event_callback("net_update_end", function()
	speed_enabled = ui.get(toggle_exoboost) and ui.get(keybind_exoboost)
	local local_player = entity.get_local_player()
	if not local_player then return end
	local wearing_exojump = bit.band(entity.get_prop(local_player, "m_passiveItems", 1), 1) == 1
	if last_speed_enabled and not speed_enabled then
		if crouching and not client.key_state(CTRL) then
			client.exec("-duck") -- stop crouching when disabling speed hack unless player holding control
		end
		ui.set(reference.bhop, true) -- enable bhop when disabling speed hack
	end
	
	if speed_enabled then
		ui.set(reference.bhop, true) -- enable bhop when enabling speed hack
		if reference.old_anti_aim == nil then
			reference.old_anti_aim = ui.get(reference.anti_aim)
		end
		if jump_time < globals.curtime() then
			if reference.old_anti_aim ~= nil then -- enable anti aim after jumping so it jumps straight
				ui.set(reference.anti_aim, reference.old_anti_aim)
				reference.old_anti_aim = nil
			end
		else
			ui.set(reference.anti_aim, false)
		end
		if wearing_exojump then
			if falling and not (crouching or in_water) then -- only crouch when on land and dry
				client.exec("+duck")
				crouching = true
			elseif not (falling or client.key_state(CTRL)) and crouching then -- only uncrouch when crouching and not holding ctrl or falling
				client.exec("-duck")
				crouching = false
			end
		end
		if standing then
			client.exec("+jump") -- only jump when on the ground
			jumped = true
			jump_time = globals.curtime()
			if reference.old_anti_aim ~= nil then
				ui.set(reference.anti_aim, reference.old_anti_aim)
			end
		end
	elseif jumped then
		client.exec("-jump")
		jumped = false
		if wearing_exojump then
			if crouching and not client.key_state(CTRL) then
				client.exec("-duck")
				crouching = false
			end
			if reference.old_anti_aim ~= nil then
				ui.set(reference.anti_aim, reference.old_anti_aim)
				reference.old_anti_aim = nil -- set old reference to nil when reference is true to the config
			end
		end
	end
	last_speed_enabled = speed_enabled
end)

client.set_event_callback("setup_command", function(cmd)
	local local_player = entity.get_local_player()
	if speed_enabled and standing then
		local _, forward_yaw = client.camera_angles()
		local strafe_directions = ui.get(reference.strafe_direction)
		local dir_x, dir_y, angle = 0, 0
		for i, v in next, strafe_directions do -- i don't wanna use table_contains
			strafe_directions[v] = i
		end
		if strafe_directions["View angles"] then
			dir_y = 1
		end
		if strafe_directions["Movement keys"] then
			local w, a, s, d = client.key_state(keys[1]), client.key_state(keys[2]), client.key_state(keys[3]), client.key_state(keys[4]) -- this is horrid
			if w or a or s or d then
				dir_y = 0 -- remaining true to the logic of having both on
				if w then dir_y = dir_y + 1 end
				if s then dir_y = dir_y - 1 end
				if a then dir_x = dir_x - 1 end
				if d then dir_x = dir_x + 1 end
			end
		end
		angle = (math.deg(math.atan2(dir_y, dir_x)) - 90) % 360
		
		cmd.yaw = forward_yaw + 140 + angle
		jump_time = globals.curtime()
		cmd.in_moveleft  = 0 -- for some reason these are really important for this to work
		cmd.in_moveright = 0
		cmd.forwardmove  = 0
		cmd.sidemove     = 0
	end
end)
