
--local sensekey = MOUSE_MIDDLE

local cooldownspeed = 1/3 -- 1 every 3 seconds
local cooldownspeedslow = 1/40 -- 1 ever 60 seconds

if SERVER then	
	--[[hook.Add("PlayerButtonDown", "sacrifun_sense", function(ply, key)
		if key == sensekey and not ply:GetIsSensing() and ply:GetAdrenaline() > 0 then
			ply:StartSensing()
		end
	end)
	hook.Add("PlayerButtonUp", "sacrifun_sense", function(ply, key)
		if key == sensekey and ply:GetIsSensing() then
			ply:EndSensing()
		end
	end)]]

	hook.Add("Think", "sacrifun_sense", function()
		for k,v in pairs(player.GetAll()) do
			if v:IsRunner() then
				local sensecooldown = v.SenseCooldown or 0
				
				-- Forced sensing
				if sensecooldown <= 0 then
					v.SenseCooldown = 1
					v:SensePing()
				end
				
				if v:GetIsSensing() then
					-- Only sensing on command
					--[[if sensecooldown <= 0 then
						v.SenseCooldown = 1
						v:SensePing()
						--v:AttemptHealthSteal()
					end]]
					if sensecooldown > 0 then
						v.SenseCooldown = math.Clamp(sensecooldown - cooldownspeed*FrameTime(), 0, 1)
					end
				else
					if sensecooldown > 0 then
						v.SenseCooldown = math.Clamp(sensecooldown - cooldownspeedslow*FrameTime(), 0, 1)
					end
				end
			end
		end
	end)
	
	local meta = FindMetaTable("Player")
	
	function meta:StartSensing()
		if self.SetIsSensing then  self:SetIsSensing(true) end
	end
	
	function meta:EndSensing()
		if self.SetIsSensing and not self.ForcedSensing then self:SetIsSensing(false) end
	end
	
	util.AddNetworkString("sfun_SensePing")
	function meta:SensePing(target, nokiller, showkillers)
		net.Start("sfun_SensePing")
			if IsValid(target) then
				net.WriteBool(true)
				net.WriteEntity(target)
			else
				net.WriteBool(false)
				showkillers = showkillers or IsInBlindPhase()
				net.WriteBool(showkillers) -- If true, also sense killers
			end
		net.Send(self)
		
		if not nokiller then
			net.Start("sfun_SensePing")
				net.WriteBool(true)
				net.WriteEntity(self)
			net.Send(team.GetPlayers(2))
		end
	end
	
	function meta:SetForcedSensing(bool)
		if not self.ForcedSensing and bool then
			self:StartSensing()
			self.ForcedSensing = true
		elseif not bool then
			self.ForcedSensing = false
			local wep = self:GetActiveWeapon()
			if not IsValid(wep) or not wep.Sensing then
				self:EndSensing()
			end
		end
	end
else
	hook.Add("HUDPaint", "sacrifun_sense", function()
		local v = LocalPlayer()
		local sensecooldown = v.SenseCooldown or 0
		if v:GetIsSensing() then
			if sensecooldown > 0 then
				v.SenseCooldown = math.Clamp(sensecooldown - cooldownspeed*FrameTime(), 0, 1)
			end
		else
			if sensecooldown > 0 then
				v.SenseCooldown = math.Clamp(sensecooldown - cooldownspeedslow*FrameTime(), 0, 1)
			end
		end
	end)
	
	local mat = Material( "models/shiny" )
	local ccSense = {
		["$pp_colour_addr"] = 0,
		["$pp_colour_addg"] = 0,
		["$pp_colour_addb"] = 0,
		["$pp_colour_brightness"] = -0.05,
		["$pp_colour_contrast"] = 1,
		["$pp_colour_colour"] = 1,
		["$pp_colour_mulr"] = 0.1,
		["$pp_colour_mulg"] = 0.1,
		["$pp_colour_mulb"] = 0.1
	}
	
	function GM:RenderScreenspaceEffects()
		if LocalPlayer():GetIsSensing() then
			DrawColorModify(ccSense)
			--DrawMaterialOverlay( "models/props_c17/fisheyelens", -0.06 )
		end
	end
	
	local senseplys = {}
	local sensetime = 5
	
	local clonecontrollers = {}
	
	net.Receive("sfun_SensePing", function()
		LocalPlayer().SenseCooldown = 1
		local tbl
		if net.ReadBool() then
			tbl = {net.ReadEntity()}
		else
			tbl = team.GetPlayers(1)
			if net.ReadBool() then
				table.Add(tbl, team.GetPlayers(2))
			end
		end
		for k,v in pairs(tbl) do
			if v != LocalPlayer() then
				local dist = v:GetPos():Distance(LocalPlayer():GetPos())
				local time = dist/10000
				timer.Simple(time, function()
					if IsValid(v) then
						local mdl = ClientsideModel(v:GetModel())
						mdl:SetPos(v:GetPos())
						mdl:SetAngles(Angle(0, v:EyeAngles()[2], 0))
						mdl:SetSequence(v:GetSequence())
						mdl:SetCycle(v:GetCycle())
						mdl:SetPoseParameter("move_x", v:GetPoseParameter("move_x"))
						mdl:SetPoseParameter("move_y", v:GetPoseParameter("move_y"))
						mdl:SetPoseParameter("aim_yaw", v:GetPoseParameter("aim_yaw"))
						mdl:SetNoDraw(true)
						if v:Team() == 2 then
							mdl:SetModelScale(1.2)
						end
						senseplys[mdl] = {ply = v, time = CurTime() + sensetime + time}
					end
				end)
			end
		end
	end)
	
	net.Receive("sfun_PlayerCloneCreated", function()
		if net.ReadBool() then
			for k,v in pairs(clonecontrollers) do
				if !IsValid(v) then
					table.remove(clonecontrollers, k)
				end
			end
		else
			local ent = net.ReadEntity()
			table.insert(clonecontrollers, ent)
		end
	end)
	
	hook.Add("PostDrawOpaqueRenderables", "sacrifun_senseping", function(ply)
		local ct = CurTime()
		local ply = LocalPlayer()
		
		cam.IgnoreZ(true)
		render.SuppressEngineLighting( true )
		render.SetColorModulation(0, 1, 0)
		render.ModelMaterialOverride( mat )
		
		for k,v in pairs(senseplys) do
			render.SetBlend((v.time-ct)/sensetime)
			k:DrawModel()
			if v.time < ct then
				senseplys[k] = nil
				k:Remove()
			end
		end
		
		render.SetBlend(1)
		if ply.GetCloneController and IsValid(ply:GetCloneController()) then
			render.SetColorModulation(0, 0, 0.5)
			ply:GetCloneController():DrawModel()
		end
		
		render.ModelMaterialOverride()
		render.SetColorModulation(1,1,1)
		render.SuppressEngineLighting( false )
		cam.IgnoreZ(false)
	end)
end