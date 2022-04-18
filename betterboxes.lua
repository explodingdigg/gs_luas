-- some constants for flags comparing shit
local CROUCH = 3
local GROUND = 1
local old_boundingboxes = entity.get_bounding_box
local betterboxes = {
	get_bounding_box = function(ent) end,
}
local last_positions = {}
function betterboxes.get_bounding_box(ent, y, z, accuracy) -- i allowed x,y,z to be inputted because i can't be assed to make functioning dormant esp.
	local worldToScreens = accuracy or 7 -- random value I thought looked the best compared to everything else
	-- if I were to rework the way the surrounding points are arranged I could lower this value to 4 and it would look the same
	-- and run better
	-- but I'm too lazy to do that
	local currentAngle = 0
	local totalRotations = math.pi * 2
	local min = 9999 -- holding empty values just so that we can tell if there is a finished return value for the end
	local max = 0
	local miny = 9999
	local maxy = 0
   local _, _, _, _, t
   if ent and not y then 
      _, _, _, _, t = old_boundingboxes(ent)
      -- if entity.is_dormant(ent) then
      --    print(t)
      -- end
   end
	local flags
	if not y then
		flags = entity.get_prop(ent, "m_fFlags") -- to check if they are crouching
		-- I could have used the head position but I like the static look a bit more
	end
   local origin_x, origin_y, origin_z = entity.get_origin(ent)
   if origin_x and origin_y and origin_z then
      last_positions[ent] = {x, y, z}
   elseif last_positions[ent] then
      origin_x, origin_y, origin_z = unpack(last_positions[ent])
   end
	for i = 1, worldToScreens do
		local x, y, z
		if not y then
			x, y, z = origin_x, origin_y, origin_z -- if only one input is provided then it will find the position from the entity index
		else
			x = ent -- otherwise it will just use the first input
		end
		-- if not z then
		--    min, miny, max, maxy = old_boundingboxes(ent)
		--    skip = true
		-- end
		if z then
			if flags and bit.band(CROUCH, flags) ~= 1 and bit.band(GROUND, flags) == 1 then
				z = z + 18 -- this is the only way I could find out if someone is crouching, I'm new to csgo lua so if there's a better way please let me know
			else
				z = z + 36 -- when standing
			end
		end
		currentAngle = currentAngle + totalRotations / worldToScreens -- rotating an amount depending on the accuracy value
		-- this makes a little circle around each player for finding mins and maxes.
		-- i think this looks better than precise and static boxes.
		if x then
			x = x + math.cos(currentAngle) * 18
			y = y + math.sin(currentAngle) * 18
			x, y = renderer.world_to_screen(x, y, z) -- might as well just re use x and y
		end
		if x then
			if x < min then
				min = x
			end
			if x > max then
				max = x
			end
			if y < miny then
				miny = y
			end
			if y > maxy then
				maxy = y
			end
		end
		-- renderer.circle(x, y, 255, 255, 255, 255, 4, 0, 1)
	end

	for i = 0, 1 do
		local x, y, z = origin_x, origin_y, origin_z
		if x and y and z then
			if i == 1 then
				if flags and bit.band(CROUCH, flags) ~= 1 and bit.band(GROUND, flags) == 1 then
					z = z + 55 -- this is the only way i could find out if someone is crouching, I'm new to csgo lua so if there's a better way please let me know
				else
					z = z + 72 -- when standing
				end
			else
				z = z - 5 -- move the origin point a bit downwards becuase it looks better
			end
			x, y = renderer.world_to_screen(x, y, z) -- might as well just re use x and y
			if x then
				if x < min then
					min = x
				end
				if x > max then
					max = x
				end
				if y < miny then
					miny = y
				end
				if y > maxy then
					maxy = y
				end
				-- renderer.circle(x, y, 255, 255, 255, 255, 4, 0, 1)
			end
		end
	end
	if miny ~= 9999 and minx ~= 9999 and max ~= 0 and maxy ~= 0 then -- if there is a position then return :)
		return min, miny, max, maxy, t
	end
	return nil
end
entity.get_bounding_box = betterboxes.get_bounding_box
return betterboxes
