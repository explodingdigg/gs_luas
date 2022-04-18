local entity = entity or nil;
local client = client or nil;
local tools = require "debug_tools"
local gametype = cvar.game_type
local thing = function()
   if gametype:get_int() == 6 then
      local local_player = entity.get_local_player()
      local_num = entity.get_prop(local_player, "m_nSurvivalTeam")
      
      local players = entity.get_players()
      for i = 1, #players do
         local ent = players[i]
         local num = entity.get_prop(ent, "m_nSurvivalTeam");
         
         local fix = num == local_num and num or 2; 
         entity.set_prop(ent, "m_iTeamNum", fix);
      end
   end
end
client.set_event_callback("paint",thing)
--[[
[gamesense] -1 Schweinehai
[gamesense] 3 alastor
[gamesense] 3 dddd
[gamesense] 7 BİZE GELİŞİ BU HAYATIM
[gamesense] 5 бебрик
[gamesense] 2 Donald Duck
[gamesense] 4 `𝕔𝕙𝕖𝕔𝕙𝕖𝕟´
[gamesense] 4 Yeti
[gamesense] 1 laurilan бeкoни
[gamesense] 7 🅱🅾🆃🅰🅽141
[gamesense] 1 kitten <3
[gamesense] 6 KryptoN
[gamesense] 1
[gamesense] 2 𝓝𝓘𝓝𝓙𝓐
[gamesense] 5 stari
[gamesense] 0 bartekVIP
[gamesense] 6 vova
[gamesense] -1 Schweinehai
[gamesense] 3 alastor
[gamesense] 3 dddd
[gamesense] 7 BİZE GELİŞİ BU HAYATIM
[gamesense] 5 бебрик
[gamesense] 2 Donald Duck
[gamesense] 4 `𝕔𝕙𝕖𝕔𝕙𝕖𝕟´
[gamesense] 4 Yeti
[gamesense] 1 laurilan бeкoни
[gamesense] 7 🅱🅾🆃🅰🅽141
[gamesense] 1 kitten <3
[gamesense] 6 KryptoN
[gamesense] 1
[gamesense] 2 𝓝𝓘𝓝𝓙𝓐
[gamesense] 5 stari
[gamesense] 0 bartekVIP
[gamesense] 6 vova
[gamesense] -1 Schweinehai
[gamesense] 3 alastor
[gamesense] 3 dddd
[gamesense] 7 BİZE GELİŞİ BU HAYATIM
[gamesense] 5 бебрик
[gamesense] 2 Donald Duck
[gamesense] 4 `𝕔𝕙𝕖𝕔𝕙𝕖𝕟´
[gamesense] 4 Yeti
[gamesense] 1 laurilan бeкoни
[gamesense] 7 🅱🅾🆃🅰🅽141
[gamesense] 1 kitten <3
[gamesense] 6 KryptoN
[gamesense] 1
[gamesense] 2 𝓝𝓘𝓝𝓙𝓐
[gamesense] 5 stari
[gamesense] 0 bartekVIP
[gamesense] 6 vova
[gamesense] -1 Schweinehai
[gamesense] 3 alastor
[gamesense] 3 dddd
[gamesense] 7 BİZE GELİŞİ BU HAYATIM
[gamesense] 5 бебрик
[gamesense] 2 Donald Duck
[gamesense] 4 `𝕔𝕙𝕖𝕔𝕙𝕖𝕟´
[gamesense] 4 Yeti
[gamesense] 1 laurilan бeкoни
[gamesense] 7 🅱🅾🆃🅰🅽141
[gamesense] 1 kitten <3
[gamesense] 6 KryptoN
]]