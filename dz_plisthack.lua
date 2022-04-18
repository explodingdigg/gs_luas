local gametype = cvar.game_type
client.set_event_callback("paint", function()
   if gametype:get_int() == 6 then
      local local_player = entity.get_local_player()
      local local_team = entity.get_prop(local_player, "m_nSurvivalTeam")
      
      local players = entity.get_players()
      for i = 1, #players do
         local ent = players[i]
         local team = entity.get_prop(ent, "m_nSurvivalTeam")
         
         local team_num = team == local_team and num or 2;
         entity.set_prop(ent, "m_iTeamNum", team_num)
      end
   end
end)
