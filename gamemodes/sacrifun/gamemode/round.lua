
if SERVER then
	local runnercount = 1
	function RoundRestart()
		game.CleanUpMap()
		
		local tbl = {}
		local total = 0
		for k,v in pairs(player.GetAll()) do
			local weight = v.KillerWeight or 1
			tbl[v] = weight
			total = total + weight
		end
		
		-- Weighted random, every time you're not a killer your weight increases by 1
		local cur = 0
		local killer = false
		local ran = math.random(0,total)
		runnercount = 0
		for k,v in pairs(tbl) do
			cur = cur + v
			if cur >= ran and not killer then
				k:SetKiller()
				k.KillerWeight = 1
				killer = true
			else
				k:SetRunner()
				runnercount = runnercount + 1
				k.KillerWeight = k.KillerWeight and k.KillerWeight + 1 or 1
			end
			
			k:Spawn()
		end
		
		BlindPhase(20)
	end

	local isblind
	util.AddNetworkString("sfun_Round")
	function BlindPhase(time)
		isblind = true
		net.Start("sfun_Round")
			net.WriteUInt(time, 10)
		net.Broadcast()
		
		for k,v in pairs(team.GetPlayers(2)) do
			v:Freeze(true)
		end
		for k,v in pairs(team.GetPlayers(1)) do
			v:RestockProps()
		end
		
		local time = CurTime() + time
		hook.Add("Think", "sfun_killerfreeze", function()
			if CurTime() > time then
				for k,v in pairs(team.GetPlayers(2)) do
					v:Freeze(false)
				end
				for k,v in pairs(team.GetPlayers(1)) do
					v:RemoveProps()
				end
				hook.Remove("Think", "sfun_killerfreeze")
				isblind = false
			end
		end)
	end
	
	function IsInBlindPhase()
		return isblind
	end
	
	local function UpdatePlayerStatus()
		local num = team.NumPlayers(1)
		local min = runnercount > 1 and 1 or 0
		if num <= min then
			local ply = team.GetPlayers(1)[1]
			if IsValid(ply) then
				PrintMessage(HUD_PRINTTALK, ply:Nick() .. " wins!")
			else
				PrintMessage(HUD_PRINTTALK, "No winners :(")
			end
			
			local time = CurTime() + 5
			hook.Add("Think", "sfun_roundover", function()
				if CurTime() > time then
					--RoundRestart()
					hook.Remove("Think", "sfun_roundover")
				end
			end)
		end
	end
	hook.Add("OnPlayerChangedTeam", "sfun_teamstatus", UpdatePlayerStatus)
	hook.Add("sfun_UpdateTeamStatus", "sfun_teamstatus", UpdatePlayerStatus)
	hook.Add("EntityRemoved", "sfun_teamstatus", function(ent)
		if ent:IsPlayer() then UpdatePlayerStatus() end
	end)
else

	local blindtime = 0
	net.Receive("sfun_Round", function()
		blindtime = CurTime() + net.ReadUInt(10)
	end)
	
	hook.Add("RenderScreenspaceEffects", "sacrifun_blindphasehud", function()
		local diff = blindtime - CurTime()
		if diff >= 0 then
			local w, h = ScrW(),ScrH()
			if LocalPlayer():IsKiller() then
				surface.SetDrawColor(0,0,0)
				surface.DrawRect(-1,-1,w+1,h+1)
			end
			
			draw.SimpleTextOutlined("Blind Phase: "..string.ToMinutesSeconds(diff), "DermaLarge", w/2, h/5*4, nil, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
		end
	end)
	
	function IsInBlindPhase()
		return blindtime > CurTime()
	end
end