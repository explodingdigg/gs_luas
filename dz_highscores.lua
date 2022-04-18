local indent = 0
client.set_event_callback('paint_ui', function()
   indent = 0
end)
text = function(...)
   renderer.text(250, 50 + indent * 14, 255, 255, 255, 255, "", nil, ...)
   indent = indent + 1
end
local scores = { -- i know this formatting is bullshit. i was high when i made this and i don't care about refactoring it.
	{"money", "m_iAccount", ">"},
	{"kills", "m_iNumRoundKills", ">"},
	{"headshot kills", "m_iNumRoundKillsHeadshots", ">"},
	{"damage dealt", "m_unTotalRoundDamageDealt", ">"},
}
for i = 1, #scores do
	if not database.read("highscore_" .. scores[i][1]) then
		database.write("highscore_" .. scores[i][1], scores[i][3] and -math.huge or math.huge)
	end
end

local game_type = cvar.game_type
client.set_event_callback("paint_ui", function()
	local player = entity.get_local_player()
	local game_rules = entity.get_game_rules()
	local warmup = entity.get_prop(game_rules, "m_bWarmupPeriod") == 1
	if game_type:get_int() == 6 then
		text("danger zone high scores :")
		for i = 1, #scores do
			if scores[i] then
				local highscore = database.read("highscore_" .. scores[i][1])
				if player then
					local stat = scores[i][2]
					if type(stat) == "string" then
						stat = entity.get_prop(player, scores[i][2])
					else
						stat = stat()
					end
					if not warmup then
						if stat and stat > highscore then
							database.write("highscore_" .. scores[i][1], stat)
						end
					end
				end
				text(string.format("\t%s: %d", scores[i][1], highscore or -1))
			end
		end
	end
end)
