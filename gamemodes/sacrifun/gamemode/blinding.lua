
local blindtime = 5 -- Time you stay blinded
local blindbuild = 0.65 -- Time it takes to fully blind
local blindrecover = 0.5 -- Time after you stop getting flashed to recover

if SERVER then
	local meta = FindMetaTable("Player")
	
	util.AddNetworkString("sfun_playerblind")
	
	function meta:Blind(time)
		if self.FullyBlind or self:IsKiller() then return end
		
		self.Blindtime = CurTime() + (time or blindrecover)
	end
	
	hook.Add("Think", "sacrifun_blind", function()
		local ct = CurTime()
		for k,v in pairs(player.GetAll()) do
			local blindrec = v.Blindtime or 0
			local blind = v.CurBlind or 0
			if v.FullyBlind then -- Fully blind (immune to further blinding)
				if blindrec < ct then -- Time has passed
					if v.IsBeingBlinded then -- Let the player know
						net.Start("sfun_playerblind")
							net.WriteBool(false)
						net.Send(v)
						v.IsBeingBlinded = false
					end
					if blind > 0 then
						v.CurBlind = math.Clamp(blind - FrameTime()/blindbuild, 0, 1)
					else
						v.FullyBlind = false
					end
				end
			else
				if blindrec > ct then -- Still being blinded
					if not v.IsBeingBlinded then
						net.Start("sfun_playerblind")
							net.WriteBool(true)
						net.Send(v)
						v.IsBeingBlinded = true
					end
					if blind < 1 then -- Build it up
						v.CurBlind = math.Clamp(blind + FrameTime()/blindbuild, 0, 1)
					else -- Fully blind here
						v.FullyBlind = true
						v.Blindtime = ct + blindtime -- Blind them for this long
					end
				elseif v.IsBeingBlinded then -- Let the player know
					net.Start("sfun_playerblind")
						net.WriteBool(false)
					net.Send(v)
					v.IsBeingBlinded = false
				end
			end
		end
	end)
else
	local curblind = 0
	local nextrecover = 0
	local blindimmune
	
	local isblinded
	
	net.Receive("sfun_playerblind", function()
		local bool = net.ReadBool()
		isblinded = bool
	end)
	
	local blindtbl = {
		["$pp_colour_addr"] = 0,
		["$pp_colour_addg"] = 0,
		["$pp_colour_addb"] = 0,
		["$pp_colour_brightness"] = 0,
		["$pp_colour_contrast"] = 1,
		["$pp_colour_colour"] = 1,
		["$pp_colour_mulr"] = 0,
		["$pp_colour_mulg"] = 0,
		["$pp_colour_mulb"] = 0
	}
	
	hook.Add("RenderScreenspaceEffects", "sfun_playerblind", function()
		if isblinded then
			curblind = math.Clamp(curblind + FrameTime()/blindbuild, 0, 1)
		elseif curblind > 0 then
			curblind = math.Clamp(curblind - FrameTime()/blindbuild, 0, 1)
		end
		
		blindtbl["$pp_colour_brightness"] = curblind
		DrawColorModify(blindtbl)		
		
	end)
	
end