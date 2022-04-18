local vector = require("vector")
local damages = {}

local toggle_damages = ui.new_checkbox("visuals", "other esp", "Damage markers")
local color_damages = ui.new_color_picker("visuals", "other esp", "Damage markers color")
local function create_damage(e)
	local_player = entity.get_local_player()
	if client.userid_to_entindex(e.attacker) ~= local_player then return end
	local damage = {}
	local player = client.userid_to_entindex(e.userid)
	local hitgroup = e.hitgroup
	damage.time = 2
	damage.lifetime = globals.curtime() + damage.time
	damage.position = vector(entity.hitbox_position(player, hitgroup))
	damage.offset = 0
	damage.value = e.dmg_health
	damage.flags = e.health <= 0 and "c+" or "c"
	table.insert(damages, damage)
end

client.set_event_callback("player_hurt", create_damage)
client.set_event_callback("player_connect_full", function() damages = {} end)
client.set_event_callback("paint", function()
	local time = globals.curtime()
	if not ui.get(toggle_damages) then return end
	local r, g, b, a = ui.get(color_damages)
	for i = 1, #damages do
		local damage = damages[i]
		if damage.lifetime > time then
			local alpha = (damage.lifetime - time)/damage.time
			local zoffset = 40 * (1-alpha)
			damage.offset = damage.offset + math.sin(globals.curtime() * 10) / 10
			local offset = damage.offset
			local x, y = renderer.world_to_screen((damage.position + vector(0,0,zoffset)):unpack())

			if x and y then
				renderer.text(x + offset + 1, y - zoffset + 1, 0, 0, 0, a * (alpha)/2, damage.flags, nil, "-", damage.value)
				renderer.text(x + offset - 1, y - zoffset - 1, 0, 0, 0, a * (alpha)/2, damage.flags, nil, "-", damage.value)
				renderer.text(x + offset, y - zoffset, r, g, b, a * (alpha+1), damage.flags, nil, "-", damage.value)
			end
		end
	end
end)
