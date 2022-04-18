local vector = require"vector"
local deliveries = {}

function disp_time(time)
  local minutes = math.floor(time % 3600/60)
  local seconds = math.floor(time % 60)
  return string.format("%02d:%02d",minutes,seconds)
end

client.set_event_callback("drone_dispatched", function(e)
	-- short userid, short priority, short drone_dispatched
	local target = client.userid_to_entindex(e.userid)
	local drone = e.drone_dispatched
	print(target, " ", entity.get_player_name(target), " with drone #", drone)
	local drone_pos = vector(entity.get_origin(drone))
	drone_pos.z = 0
	local drone_speed = vector(entity.get_prop(drone, "m_vecVelocity")):length()
	local dist = drone_pos:dist(vector(entity.get_origin(target)))

	print(dist, " ", drone_speed, " ", dist/drone_speed)
	if target == entity.get_local_player() then
		print('drone')
		deliveries[drone] = true
	end
end)
client.set_event_callback("drone_cargo_detached", function(e)
	local drone = e.drone_dispatched
	if deliveries[drone] then deliveries[drone] = nil end -- end the delivery
end)

client.set_event_callback("paint", function()
	local local_player = entity.get_local_player()
	if not local_player then return end
	local local_pos = vector(entity.get_origin(local_player))
	local_pos.z = 0
	local off = 0
	local drones = entity.get_all("CDrone")
	local tablet
	for i = 0, 63 do
		local k = entity.get_prop(local_player, "m_hMyWeapons", i)
		if k and entity.get_classname(k) == "CTablet" then
			tablet = k
			break
		end
	end
	
	if not tablet then return end
	
	for i = 1, #drones do
		local drone = drones[i]
		if entity.get_prop(drone, "m_hMoveToThisEntity") == tablet then
			local drone_pos = vector(entity.get_origin(drone))
			drone_pos.z = 0
			local drone_speed = vector(entity.get_prop(drone, "m_vecVelocity")):length()
			local dist = drone_pos:dist(local_pos)
			
			renderer.text(500, 20 + off, 255, 255, 255, 255, "", nil, math.ceil(dist/drone_speed), " seconds until delivered ", dist, "/", drone_speed)
			off = off + 20
		end
	end
end)
