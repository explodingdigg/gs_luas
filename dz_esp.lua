local function file_exists(file_name)
	local found = false
	for k, searcher in next, package.searchers do
		found = found or searcher(file_name)
	end
	return found
end

local csgo_weapons = require("gamesense/csgo_weapons")
local better_boxes = entity -- in case you don't have the betterboxes module.
if file_exists("betterboxes.lua") then
	better_boxes = require("betterboxes")
end
local vector = require("vector")
local flag_names = {
	"H", -- text which will be displayed
	"K",
	"HK",
	"ZOOM",
	"BLIND",
	"RELOAD",
	"C4",
	"VIP",
	"DEFUSE",
	"FD",
	"PIN",
	"HIT",
	"HIDDEN",
	"CHEAT",
	"DT",
}
local flag_bits = {
	[1] = { text = "H", r = 30, g = 88, b = 222 }, -- text which will be displayed
	[2] = { text = "K", r = 30, g = 88, b = 222 },
	[4] = { text = "HK", r = 64, g = 94, b = 247 },
	[8] = { text = "ZOOM", r = 255, g = 255, b = 255 },
	[16] = { text = "BLIND", r = 255, g = 255, b = 255 },
	[32] = { text = "REL", r = 255, g = 200, b = 0 },
	[64] = { text = "C4", r = 255, g = 255, b = 255 },
	[128] = { text = "VIP", r = 255, g = 255, b = 255 },
	[256] = { text = "DEFUSE", r = 255, g = 255, b = 255 },
	[512] = { text = "FD", r = 255, g = 255, b = 255 },
	[1024] = { text = "PIN", r = 255, g = 255, b = 255 },
	[2048] = { text = "HIT", r = 198, g = 7, b = 29 },
	[4096] = { text = "HIDDEN", r = 255, g = 255, b = 255 },
	[8192] = { text = "CHEAT", r = 255, g = 255, b = 255 },
	[131072] = { text = "DT", r = 255, g = 255, b = 255 },
}
for k, v in next, flag_bits do
	if type(k) == "number" then
		flag_bits[v.text] = k
	end
end


local toggle_boxes = ui.new_checkbox("lua", "A", "Bounding boxes")
local color_boxes = ui.new_color_picker("lua", "A", "Bounding boxes", 255, 255, 255, 255)
local toggle_dz_color = ui.new_checkbox("lua", "A", "Danger zone team color")
local toggle_name = ui.new_checkbox("lua", "A", "Name")
local toggle_hp = ui.new_checkbox("lua", "A", "Health bar")
local color_hp = ui.new_color_picker("lua", "A", "Health bar", 255, 255, 255, 255)
ui.new_label("lua", "A", "Bottom color")
local color_hp1 = ui.new_color_picker("lua", "A", "Bottom color", 0, 255, 0, 255)
local toggle_weapon = ui.new_checkbox("lua", "A", "Weapon")
local toggle_flags = ui.new_checkbox("lua", "A", "Flags")
local toggle_declutter = ui.new_checkbox("lua", "a", "Declutter screen")
local hotkey_declutter = ui.new_hotkey("lua", "a", "declutter screen keybind", true)
local multiselect_flags = ui.new_multiselect("lua", "A", "Exclude flags", flag_names)
ui.set_visible(multiselect_flags, ui.get(toggle_flags))

local toggle_dz_traps = ui.new_checkbox("lua", "A", "Breach charge warning")
local toggle_dz_breachcharge = ui.new_checkbox("lua", "a", "Show breach charge items")
local color_dz_breachcharge = ui.new_color_picker("lua", "a", "Show breach charge color")
local toggle_dz_ammo = ui.new_checkbox("lua", "A", "Ammo boxes")
local color_dz_ammo = ui.new_color_picker("lua", "A", "Danger zone ammo", 200, 127, 59, 255)
local toggle_dz_medishot = ui.new_checkbox("lua", "a", "Health shots")
local color_dz_medishot = ui.reference("visuals", "Other ESP", "Dropped weapons") + 1
local toggle_arrows = ui.new_checkbox("lua", "a", "Arrow indicators")
local multiselect_arrows = ui.new_multiselect("lua", "a", "\narrow_settings", "Render on screen", "Always render closest", "Name", "Flags", "Distance based size", "Distance based opacity", "Bump flag")
local color_arrows = ui.new_color_picker("lua", "a", "Arrow color")
local slider_arrows_size = ui.new_slider("lua", "a", "\narrow_size", 1, 100, 20, true, "px")
local slider_arrows_radius = ui.new_slider("lua", "a", "\narrow_radius", 1, 100, 30, true, "%")
local slider_arrows_pulse = ui.new_slider("lua", "a", "Pulse", 0, 100, 0, true, "%", 1, {[0] = "Off"})

local dz_team_colors = {
	{ 255, 85, 94 },
	{ 255, 155, 1 },
	{ 100, 0, 189 },
	{ 139, 241, 139 },
	{ 122, 222, 255 },
	{ 155, 110, 243 },
	{ 228, 217, 0 },
	{ 222, 23, 75 },
	{ 255, 170, 255 },
	{ 255, 255, 180 },
}

local max_hp = nil
local dz = false
local team_sizes
local game_type = cvar.game_type

function update_max_hp()
	team_sizes = {}
	dz = game_type:get_int() == 6
	if dz then
		max_hp = 120
	else
		max_hp = 100
	end
end

client.set_event_callback("player_connect_full", update_max_hp)

local function triangle(x, y, s, r, g, b, a)
	local tri_points = {}
	for i = 1, 3 do
		table.insert(tri_points, math.floor(x + math.sin(i / 3 * math.pi * 2) * s))
		table.insert(tri_points, math.floor(y - math.cos(i / 3 * math.pi * 2) * s))
	end
	renderer.triangle(unpack(tri_points), r, g, b, a)
end

local contains = function(t, val)
	for k, v in next, t do
		if v == val then
			return true
		end
	end
end

local clamp = function(a, low, high)
	if a > high then
		return high
	elseif a < low then
		return low
	end
	return a
end

local function rotate_around_c(angle, center, point, point_)
	local s = math.sin(angle)
	local c = math.cos(angle)
	
	point.x = point.x-center.x
	point.y = point.y-center.y
	point_.x = point_.x-center.x
	point_.y = point_.y-center.y
	
	local xn, yn = point.x * c - point.y * s, point.x * s + point.y * c
	local x_n, y_n = point_.x * c - point_.y * s, point_.x * s + point_.y * c
	
	return xn+center.x, yn+center.y, x_n+center.x, y_n+center.y
end

local ignored_weapons = {["Bare Hands"]=1,Tablet=1,}
local weapon_replacements = {["Dual Berettas"] = "Dualies", ["Glock-18"] = "Glonk", ["CZ75-Auto"] = "CZ75", ["Five-SeveN"] = "FiveSeven", }
local player_respawn_times = {}
local team_respawn_times = {}
local arrow_times = {}
local dz_respawns = true
client.set_event_callback("survival_no_respawns_final", function() dz_respawns = false end)
local function reset_respawn_times()
	dz_respawns = true
	player_respawn_times = {}
	team_respawn_times = {} -- reset respawn info for new games
end

client.set_event_callback("round_start", reset_respawn_times)
client.set_event_callback("player_connect_full", reset_respawn_times)

client.set_event_callback("player_death", function(e)
	local victim = client.userid_to_entindex(e.userid)
	local team = entity.get_prop(victim, "m_nSurvivalTeam")
	
	if player_respawn_times[victim] then
		player_respawn_times[victim] = player_respawn_times[victim] + 10
	else	
		player_respawn_times[victim] = 10
	end
	
	if team then
		team_respawn_times[team] = globals.curtime() + player_respawn_times[victim]
	end
end)

local function render_flags(x, y, t, flags, show, render_all_info, a)
	t = t or 1
	a = a or 255
	local oy = 8
	for i = 1, #flags do
		local f = flags[i]
		if show or render_all_info or f.override then -- f.override is overriding the show and hsit yk
			if f.text then
				renderer.text(x + 2, y - 11 + oy, f.r, f.g, f.b, a * t, "-", 0, f.text)
				oy = oy + 8
			else
				local ox = 0
				for j = 1, #f do -- multicolored flags, really shit code tho
					local new_f = f[j]
					renderer.text(x+2 + ox, y-11 + oy, new_f.r, new_f.g, new_f.b, a * t, "-", 0, new_f.text)
					ox = ox + renderer.measure_text("-", new_f.text)
				end
				oy = oy + 8
			end
		end
	end
end

client.set_event_callback("paint", function()
	if not max_hp then
		update_max_hp()
	end
	local local_player = entity.get_local_player()
	local total = 0
	local new_team_sizes = {}
	local warmup = entity.get_prop(game_rules, "m_bWarmupPeriod") == 0
	local local_position, local_velocity, speed
	local width, height = client.screen_size()
	if local_player then
		local_position = vector(entity.get_origin(local_player))
		local width, height = client.screen_size()
		local local_health = entity.get_prop(local_player, "m_iHealth")

		local velox = math.ceil(math.abs(entity.get_prop(local_player, "m_vecVelocity")))
		local veloy = math.ceil(math.abs(entity.get_prop(local_player, "m_vecVelocity[1]")))
		local_velocity = vector(velox, veloy)
		speed = local_velocity:length()

		if ui.get(toggle_dz_ammo) then
			local entities = entity.get_all("CPhysPropAmmoBox")
			local smallest_distance = 100000^2
			for i = 1, #entities do
				local ent = entities[i]
				local x, y, z = entity.get_origin(ent)
				local position = vector(x, y, z)
				local maxdist = smallest_distance
				local dist = (position - local_position):lengthsqr(local_position)
				if dist < smallest_distance then
					smallest_distance = dist
				end
				local alpha = 255 * (1 - (dist + maxdist / 2) / maxdist)
				if dist < maxdist * 2 then
					local x, y = renderer.world_to_screen(x, y, z)
					if x and y then
						-- renderer.rectangle(x, y, 10, 10, 255, 255, 255, 255)
						local r, g, b, a = ui.get(color_dz_ammo)
						renderer.text(x, y, r, g, b, a, "c-", nil, "AMMO")
					end
				end
			end

			--CBaseWeaponWorldModel
		end
		--[[if ui.get(toggle_debug) then
			local entities = entity.get_all()
			for i = 1, #entities do
				local ent = entities[i]
				local x, y, z = entity.get_origin(ent)
				local position = vector(x, y, z)
				local x, y = renderer.world_to_screen(x, y, z)

				if x and y then
					local n_y = y
					local i = 1
					while debug_text_positions[n_y] ~= nil and debug_text_positions[n_y][x] ~= nil and i < 5 do
						n_y = n_y + 8
						i = i + 1
					end
					if not debug_text_positions[n_y] then debug_text_positions[n_y] = {} end
					debug_text_positions[n_y][x] = true
					-- renderer.rectangle(x, y, 10, 10, 255, 255, 255, 255)
					local r, g, b, a = 255, 255, 255, 255
					renderer.text(x, n_y, r, g, b, a, "c-", nil, string.upper(entity.get_classname(ent)))
					if entity.get_classname(ent) == "CBreachCharge" then 
						-- print"FUCK" -- not sure what this is for?
					end
				end
			end
		end]]
		if ui.get(toggle_dz_breachcharge) then
			local entities = entity.get_all("CBreachCharge")

			for i = 1, #entities do
				local ent = entities[i]
				local x, y, z = entity.get_origin(ent)
				local x, y = renderer.world_to_screen(x,y,z)
				if x and y then
					local r, g, b, a = ui.get(color_dz_breachcharge)
					renderer.text(x, y, r, g, b, a, "c-", nil, "BREACH CHARGES")
				end
			end
		end
		if ui.get(toggle_dz_traps) then
			local entities = entity.get_all("CBreachChargeProjectile") --CBreachChargeProjectile

			for i = 1, #entities do
				local ent = entities[i]
				local x, y, z = entity.get_origin(ent)
				local position = vector(x, y, z)
				local x, y = renderer.world_to_screen(x, y, z)
				local should_explode = entity.get_prop(ent, "m_bShouldExplode") ~= 0
				local s = 50 * (1 - position:dist(local_position) / 800)

				s = math.max(should_explode and 20 or 0, s)
				if x and y then
					-- x, y, s = 150, 150,(math.sin(globals.curtime()/10)+1) * 50 + 20
					triangle(x, y, s * 1.1, 0, 0, 0, 255)
					triangle(x, y, s, 222, 202, 0, 255)
					if should_explode and globals.curtime() % 0.2 > 0.1 then
						triangle(x, y, s, 200, 50, 50, 255)
					end
					-- local rx =
					-- renderer.rectangle(rx, ry, rx1, ry1, 0, 0, 0, 255)
					-- local rx = x - (s / 10)2
					-- local ry = y - (s * 0.5)
					-- local rx1 = s / 5
					-- local ry1 = s * 0.5
					-- renderer.triangle(rx, ry, rx+rx1, ry, rx+rx1/2, ry+ry1, 0, 0, 0, 255)
					local rx = x - (s / 10)
					local ry = y - (s * 0.5)
					local rx1 = s / 5
					local ry1 = s * 0.5
					renderer.triangle(rx, ry, rx + rx1, ry, rx + rx1 / 2, ry + ry1, 255, 255, 255, 255)
					renderer.circle(x, y + s * 0.2, 255, 255, 255, 255, math.ceil(s / 20 * 2), 0, 100)
					-- renderer.rectangle(x - 5, y - 5, 10, 10, 255, 0, 0, 255)
				end
			end
			-- renderer.rectangle(x-5, y-5, 10, 10, 255, 0, 0, 255)
		end
		--[[if ui.get(toggle_dz_exojump) then
			local entities = entity.get_all("CPhysPropWeaponUpgrade") --CBreachChargeProjectile

			for i = 1, #entities do
				local ent = entities[i]
				if entity.get_prop(ent, "m_nModelIndex") == 1070 then
					local x, y, z = entity.get_origin(ent)
					local x, y = renderer.world_to_screen(x, y, z)
					if x and y then
						local r, g, b, a = ui.get(color_dz_exojump)
						renderer.text(x, y, r, g, b, a, "c-", nil, "EXOJUMP")
					end
				end
			end
			-- renderer.rectangle(x-5, y-5, 10, 10, 255, 0, 0, 255)
		end]]
		if ui.get(toggle_dz_medishot) then
			local entities = entity.get_all()
			for i = 1, #entities do
				local ent = entities[i]
				local idx = entity.get_prop(ent, "m_iItemDefinitionIndex")
				local weapon = csgo_weapons[idx]

				if weapon and weapon.name == "Medi-Shot" and not entity.get_prop(ent, "m_hOwnerEntity") then
					local x, y, z = entity.get_origin(ent)
					local len2 = (vector(x, y, z) - local_position):lengthsqr()
					local x, y = renderer.world_to_screen(x, y, z)
					local criteria = (len2 < 2000000) or (local_health < 100)
					if x and y then
						local r, g, b, a = ui.get(color_dz_medishot)
						if criteria and math.sin(globals.curtime()*16) > -0.5 then -- dumb way to make it flash but it works i guess
							renderer.rectangle(x-20, y, 42, 1, 255, 10, 10, 200)
							renderer.rectangle(x-21, y, 1, 11, 255, 10, 10, 200)
							renderer.rectangle(x+22, y, 1, 11, 255, 10, 10, 200)
							renderer.rectangle(x-20, y+10, 42, 1, 255, 10, 10, 200)
							renderer.text(x-1, y, 255, 10, 10, 200, "c-", nil, "+") -- little indicators making the health-shots easier to see ig
							renderer.text(x-1, y+10, 255, 10, 10, 200, "c-", nil, "+")
						end
						renderer.text(x-1, y+5, r, g, b, a, "c-", nil, string.upper(weapon.name))
					end
				end
			end
		end
	end
	local vis = 0
	local players = 0
	local closest_player
	local closest_player_dist = math.huge
	local local_team = entity.get_prop(local_player, "m_nSurvivalTeam")

	for i = 1, globals.maxplayers() do -- getting team sizes
		local team = entity.get_prop(i, "m_nSurvivalTeam")
		if local_player and team ~= local_team and entity.is_alive(i) then
			local local_position = vector(entity.get_origin(local_player))
			local position = vector(entity.get_origin(i))
			local dist = position:dist(local_position)
			if dist < closest_player_dist then
				closest_player_dist = dist
				closest_player = i
			end
		end
		if team then
			players = players + 1
			if new_team_sizes[team] then
				new_team_sizes[team] = new_team_sizes[team] + 1 or 1
			else
				new_team_sizes[team] = 1
			end
			total = total + 1
			local x, y, w, h, t = better_boxes.get_bounding_box(i)
			vis = x and vis+1 or vis
		end
	end

	for i = -2, #new_team_sizes do -- updating team sizes -- yes this system is super shit i"ll figure it out later
		if not team_sizes[i] and new_team_sizes[i] then
			team_sizes[i] = new_team_sizes[i]
		end
		if team_sizes[i] and new_team_sizes[i] and new_team_sizes[i] > team_sizes[i] then
			team_sizes[i] = new_team_sizes[i]
		end
	end
	local render_all_info = players < 5
	if render_all_info and ui.get(toggle_declutter) and ui.get(hotkey_declutter) then -- declutter screen
		if vis > 5 then
			render_all_info = false
		end
	end
	local view_x, view_y = client.camera_angles()
	if not view_x then return end
	local arrow_toggles = ui.get(multiselect_arrows)
	local arrow_radius = ui.get(slider_arrows_radius) / 200 * height
	local arrow_pulse = ui.get(slider_arrows_pulse)
	local arrow_size = ui.get(slider_arrows_size)
	local r, g, b, a = ui.get(color_arrows)
	for i = 1, #arrow_toggles do
		arrow_toggles[arrow_toggles[i]] = true
	end
	for i = 1, globals.maxplayers() do
		local ent = i
		local team = entity.get_prop(ent, "m_nSurvivalTeam")
		local flags = {}
		local position = vector(entity.get_origin(ent))
		if ent ~= local_player and entity.is_alive(ent) and entity.is_enemy(ent) and (position.x ~= 0 or position.y ~= 0) then
			if dz and ui.get(toggle_dz_color) then
				r, g, b = unpack(dz_team_colors[team + 2])
				if team_sizes[team] == 1 then
					r, g, b = 255, 0, 255
				end
			end
			local esp_data = entity.get_esp_data(ent)
			local show = esp_data and (bit.band(esp_data.flags, flag_bits.HIT) ~= 0) or false
			local x, y, w, h, t = better_boxes.get_bounding_box(ent)
			local team = entity.get_prop(ent, "m_nSurvivalTeam")
			local health = entity.get_prop(ent, "m_iHealth")

			if ui.get(toggle_flags) then
				local esp_data = entity.get_esp_data(ent)
				if dz and not warmup then -- above regular flags
					if entity.get_prop(local_player, "m_hSurvivalAssassinationTarget") == ent then
						table.insert(flags, { text = "TRGT", r = 255, g = 0, b = 255 })
						plist.set(ent, "High Priority", true)
					end
					if team_respawn_times[team] ~= nil and team_respawn_times[team] > globals.curtime() or
							(new_team_sizes[team] and team_sizes[team] and (new_team_sizes[team] <= 1 or team_sizes[team] <= 1)) then --the or is for in case you load the lua mid game? idfk
						local time = math.ceil((team_respawn_times[team] or 0) - globals.curtime())
						if time <= 0 then time = "" end
						table.insert(flags, {{ text = "LST ", r = 255, g = 150, b = 150}, {text = time, r = 255, g = 255, b = 255}, override = true}) -- shows the time left for respawn :)))
					end
				end
				
				for i = 0, 63 do
					local k = entity.get_prop(ent, "m_hMyWeapons", i)
					if k and entity.get_classname(k) == "CWeaponShield" then
						table.insert(flags, { text = "SHLD", r = 100, g = 255, b = 255 })
					end
				end
				
				for i = 1, #flag_names do
					local c = bit.band(esp_data.flags, bit.lshift(1, i - 1))
					if c ~= 0 and not contains(ui.get(multiselect_flags), flag_bits[c].text) then
						table.insert(flags, flag_bits[c])
					end
				end
			end

			if x then
				local dist = position:dist(local_position)
				if x > width/2 - width/16 and w < width/2 + width/16 then
					if y > height/2 - height/8 and h < height/2 + height/8 then
						show = true -- for declutter screen shit
					end
				end
				show = show or dist < 5000 -- just to stop shit from not rendering if they"re too close
				local r, g, b, a = ui.get(color_boxes)
				if ui.get(toggle_boxes) then
					r, g, b, a = ui.get(color_boxes)
					if dz and ui.get(toggle_dz_color) and dz_team_colors[team + 2] then
						r, g, b = unpack(dz_team_colors[team + 2])
						if team_sizes[team] == 1 then
							r, g, b = 255, 0, 255
						end
						renderer.rectangle(x, y, w - x, h - y, r, g, b, ((show or render_all_info) and 50 or 25))
					end
					--outline]] --[[
					renderer.rectangle(x - 1, y - 1, w - x, 3, 0, 0, 0, a * t)
					renderer.rectangle(x - 1, y, 3, h - y, 0, 0, 0, a * t)
					renderer.rectangle(x - 1, h, w - x, 3, 0, 0, 0, a * t)
					renderer.rectangle(w - 1, y - 1, 3, h - y + 4, 0, 0, 0, a * t)
					--box
					renderer.rectangle(x, y, w - x, 1, r, g, b, a * t)
					renderer.rectangle(x, y + 1, 1, h - y, r, g, b, a * t)
					renderer.rectangle(x, h + 1, w - x, 1, r, g, b, a * t)
					renderer.rectangle(w, y, 1, h - y + 2, r, g, b, a * t)
				end
				
				if ui.get(toggle_hp) then
					r2, g2, b2, a2 = r, g, b, a
					a = 150
					if not dz then
						r, g, b, a = ui.get(color_hp)
						r2, g2, b2, a2 = ui.get(color_hp1)
					end

					local height = h - y + 2
					local width = w - x
					local leftside = x - 6
					local pos = height * clamp(health, 0, max_hp) / max_hp
					renderer.rectangle(leftside - 1, y - 1, 4, height + 2, 20, 20, 20, a * t)
					renderer.gradient(leftside, y, 2, height, r, g, b, a * t, r2, g2, b2, a2 * t, false)
					renderer.rectangle(leftside - 1, y - 1, 4, height - pos, 20, 20, 20, 220)
					if show or render_all_info then
						renderer.text(leftside - 4, h - clamp(pos + 3, 8, height + 4), 255, 255, 255, a * t, "-rd", 0, health)
					end
				end

				if ui.get(toggle_flags) then
					render_flags(w, y, t, flags, show, render_all_info)
				end

				if show or render_all_info then
					if ui.get(toggle_name) then
						renderer.text((x + w) / 2, y - 7, 255, 255, 255, 255 * t, "c", 0, entity.get_player_name(ent))
					end
					if ui.get(toggle_weapon) then
						local weapon_ent = entity.get_player_weapon(ent)
						local weapon = csgo_weapons(weapon_ent)
						if weapon then
							local weapon_name = weapon.name
							if ignored_weapons[weapon_name] ~= 1 then
								local weapon_name = weapon_replacements[weapon_name] or weapon_name
								renderer.text((x + w) / 2, h + 7, 255, 255, 255, 255 * t, "c-", 0, string.upper(weapon_name))
							end
						end
					end
				end
			end
			if ui.get(toggle_arrows) and (not entity.is_dormant(ent)) then
				local mult_a = 1
				if arrow_pulse ~= 0 then
					mult_a = mult_a * ((math.sin(globals.curtime() * arrow_pulse * 0.1) + 1)/2)
				end
				local text_a = 1
				local size = arrow_size
				local rad = arrow_radius
				local _, angle = local_position:to(position):angles()
				local dist = position:dist(local_position)
				local dist_limit = 2500
				local dist_sc = math.min(dist_limit, dist)/dist_limit

				if arrow_toggles["Distance based opacity"] then
					mult_a = (1-dist_sc)
					text_a = mult_a
				end
				if arrow_toggles["Distance based size"] then
					size = size*(1-dist_sc)
					size = math.max(size, 0)
					text_a = a*(1-dist_sc*2)/125 + 1
					if text_a > 1 then text_a = 1 end
					if text_a < 0 then text_a = 0 end
					if (arrow_toggles["Always render closest"] and ent == closest_player) then
						if size < arrow_size / 3 then size = arrow_size / 3 end
					end
				end
				if not x or arrow_toggles["Render on screen"] then
					angle = math.rad(270 - angle + view_y)
					local point = vector(math.floor(width/2+math.cos(angle)*arrow_radius), math.floor(height/2+math.sin(angle)*arrow_radius))
					local point1, point2 = vector(point.x-1 * size, point.y-2 * size), vector(point.x+1 * size, point.y-2 * size)
					local px, py = point.x, point.y
					local x, y, x1, y1 = rotate_around_c(angle-math.pi/2, point, point1, point2)
					renderer.triangle(point.x, point.y, x, y, x1, y1, r, g, b, a * mult_a)
					
					local min_x, min_y, max_x, max_y = math.min(x,x1,px),math.min(y,y1,py),math.max(x,x1,px),math.max(y,y1,py)
					
					if arrow_toggles.Name then
						renderer.text((min_x + max_x)/2, min_y, 255, 255, 255, 255 * text_a, "c", nil, entity.get_player_name(ent))
					end
					if arrow_toggles.Flags then
						render_flags(max_x, min_y+8, t, flags, true, true, 255 * text_a)
					end
				end
			end
		end
	end
end)

do -- config stuff
	local update_ui = function()
		ui.set_visible(multiselect_flags, ui.get(toggle_flags))
		ui.set_visible(multiselect_arrows, ui.get(toggle_arrows))
		ui.set_visible(slider_arrows_size, ui.get(toggle_arrows))
		ui.set_visible(slider_arrows_radius, ui.get(toggle_arrows))--
		ui.set_visible(slider_arrows_pulse, ui.get(toggle_arrows))
		ui.set_visible(color_arrows, ui.get(toggle_arrows))
	end
	client.set_event_callback("post_config_load", update_ui)
	ui.set_callback(toggle_flags, update_ui)
	ui.set_callback(toggle_arrows, update_ui)
	update_ui()
end -- config stuff end
