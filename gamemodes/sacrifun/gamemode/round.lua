
if SERVER then
	local cvar_sense = CreateConVar("sfun_forced_sense_timer", 180, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Sets how long time without a kill for the Runners to get forced to sense fast. Set to 0 to disable.")
	local cvar_round = CreateConVar("sfun_killer_failed_time", 360, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Sets how long without a kill will cause the remaining Runners to win. Set to 0 to disable.")
	
	local runnercount = 1
	local roundrestarttime = 5
	--local afkkillertime = 30 -- Timer after which an AFK killer will restart the round
	
	local forcetime
	local roundovertime
	local roundover
	
	function RoundRestart()
		game.CleanUpMap()
		
		local tbl = {}
		local total = 0
		for k,v in pairs(player.GetAll()) do
			local weight = v.KillerWeight or 1
			tbl[v] = weight
			total = total + weight
			
			v:SetForcedSensing(false) -- Reset this on round restart
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
		
		forcetime = nil -- Disable it during the blindphase
		roundovertime = nil -- Prevent accidental round overs during the blindphase
		roundover = false
		BlindPhase(20)
	end

	local isblind
	
	local function UpdateRoundTimes()
		local ftime = cvar_sense:GetInt()
		if ftime > 0 then
			forcetime = CurTime() + ftime
		else
			forcetime = nil
		end
		
		local rtime = cvar_round:GetInt()
		if rtime > 0 then
			roundovertime = CurTime() + rtime
		else
			roundovertime = nil
		end
	end
	
	local function UpdatePlayerStatus()
		if roundover then return end
		if team.NumPlayers(2) < 1 then
			roundovertime = nil
			forcetime = nil
			
			for k,v in pairs(team.GetPlayers(1)) do
				v:Cheer()
			end
			PrintMessage(HUD_PRINTTALK, "The Killer rage quit! Everyone wins!")
			roundover = true
			
			local time = CurTime() + roundrestarttime
			hook.Add("Think", "sfun_roundover", function()
				if CurTime() > time then
					RoundRestart()
					hook.Remove("Think", "sfun_roundover")
				end
			end)
		else
			local num = team.NumPlayers(1)
			local min = runnercount > 1 and 1 or 0
			if num <= min then
				roundovertime = nil
				forcetime = nil
				
				local ply = team.GetPlayers(1)[1]
				if IsValid(ply) and not ply.ConvertingToSkeleton then
					PrintMessage(HUD_PRINTTALK, ply:Nick() .. " was the last alive!")
					ply:Cheer()
				else
					PrintMessage(HUD_PRINTTALK, "The Killer killed everyone! There were no winners!")
				end
				roundover = true
				
				local time = CurTime() + roundrestarttime
				hook.Add("Think", "sfun_roundover", function()
					if CurTime() > time then
						RoundRestart()
						hook.Remove("Think", "sfun_roundover")
					end
				end)
			end
		end
	end
	
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
					local wep = v:GetActiveWeapon()
					if IsValid(wep) then wep.WipeTime = 0 end
				end
				for k,v in pairs(team.GetPlayers(1)) do
					v:RemoveProps()
				end
				hook.Remove("Think", "sfun_killerfreeze")
				isblind = false
				
				UpdateRoundTimes()
				UpdatePlayerStatus()
			end
		end)
	end
	
	function IsInBlindPhase()
		return isblind
	end
	
	hook.Add("OnPlayerChangedTeam", "sfun_teamstatus", UpdatePlayerStatus)
	hook.Add("sfun_UpdateTeamStatus", "sfun_teamstatus", UpdatePlayerStatus)
	hook.Add("EntityRemoved", "sfun_teamstatus", function(ent)
		if ent:IsPlayer() then
			if IsValid(ent.BonePile) then
				ent.BonePile:Remove()
			end
			UpdatePlayerStatus()
		end
	end)
	
	hook.Add("Think", "sfun_forcesensetimer", function()
		local ct = CurTime()
		if forcetime and forcetime < ct then
			for k,v in pairs(team.GetPlayers(1)) do
				v:SetForcedSensing(true)
			end
			forcetime = nil
			PrintMessage(HUD_PRINTTALK, "The Killer is too slow! Runners are now forced to sense!")
		end
		if roundovertime and roundovertime < ct then
			roundovertime = nil
			forcetime = nil
			
			for k,v in pairs(team.GetPlayers(1)) do
				v:Cheer()
			end
			PrintMessage(HUD_PRINTTALK, "The Killer failed to kill any more! The remaining Runners win!")
			roundover = true
			
			local time = CurTime() + roundrestarttime
			hook.Add("Think", "sfun_roundover", function()
				if CurTime() > time then
					RoundRestart()
					hook.Remove("Think", "sfun_roundover")
				end
			end)
		end
	end)
	
	hook.Add("Sacrifun_KillerKilledRunner", "sfun_forcedsensetimedelay", function(killer, runner)
		-- Every kill the killer gets while the timer is running resets it
		UpdateRoundTimes()			
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