
--local sensekey = MOUSE_MIDDLE

local cooldownspeed = 0.4
local cooldownspeedslow = 0.01

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
			local sensecooldown = v.SenseCooldown or 0
			if v:GetIsSensing() then
				if sensecooldown <= 0 then
					v.SenseCooldown = 1
					v:SensePing()
					--v:AttemptHealthSteal()
				end
				if sensecooldown > 0 then
					v.SenseCooldown = math.Clamp(sensecooldown - cooldownspeed*FrameTime(), 0, 1)
				end
			else
				if sensecooldown > 0 then
					v.SenseCooldown = math.Clamp(sensecooldown - cooldownspeedslow*FrameTime(), 0, 1)
				end
			end
		end
	end)
	
	local meta = FindMetaTable("Player")
	
	function meta:StartSensing()
		self:SetIsSensing(true)
	end
	
	function meta:EndSensing()
		self:SetIsSensing(false)
	end
	
	util.AddNetworkString("sfun_SensePing")
	function meta:SensePing(target, nokiller)
		net.Start("sfun_SensePing")
			if IsValid(target) then
				net.WriteBool(true)
				net.WriteEntity(target)
			else
				net.WriteBool(false)
			end
		net.Send(self)
		
		if not nokiller then
			net.Start("sfun_SensePing")
				net.WriteBool(true)
				net.WriteEntity(self)
			net.Send(team.GetPlayers(2))
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
	
	net.Receive("sfun_SensePing", function()
		LocalPlayer().SenseCooldown = 1
		local tbl
		if net.ReadBool() then
			tbl = {net.ReadEntity()}
		else
			tbl = team.GetPlayers(1)
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
						senseplys[mdl] = {ply = v, time = CurTime() + sensetime + time}
					end
				end)
			end
		end
	end)
	
	hook.Add("PostDrawOpaqueRenderables", "sacrifun_senseping", function(ply)
		local ct = CurTime()
		
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
		
		render.ModelMaterialOverride()
		render.SetBlend(1)
		render.SetColorModulation(1,1,1)
		render.SuppressEngineLighting( false )
		cam.IgnoreZ(false)
	end)
end