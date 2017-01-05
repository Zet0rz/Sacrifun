
local clonekey = MOUSE_MIDDLE

local meta = FindMetaTable("Player")

if SERVER then
	hook.Add("PlayerButtonDown", "sacrifun_sense", function(ply, key)
		if key == clonekey then
			if ply.Props and ply.Props[1] then -- If we have props (only in prep phase unless lua hacked in)
				ply:CreateProp()
			else
				ply:ToggleClone()
			end
		end
	end)
	
	util.AddNetworkString("sfun_cloneoverlay")
	
	function meta:ToggleClone(replace)
		local clone = self:GetCloneController()
		if IsValid(clone) then
			self:EndClone(replace)
		else
			if not self:IsRunner() then return end
			local clonenum = self:GetCloneNumber()
			if self:GetAdrenaline() <= 0 and clonenum > 1 then
				self:SetCloneNumber(clonenum - 1)
				self:SetAdrenaline(100)
			end
			self:StartClone()
		end
	end
	
	function meta:StartClone()
		if self:GetAdrenaline() <= 0 or not self:IsRunner() then return end
		if not self:Alive() then return end
		local clone = ents.Create("sacrifun_clone")
		clone:SetPos(self:GetPos())
		clone.PlayerEyeAngles = self:EyeAngles()
		clone:SetAngles(Angle(0, clone.PlayerEyeAngles[2], 0))
		clone:SetCloneOwner(self)
		clone:Spawn()
		--self:SetCloneController(clone)
		
		net.Start("sfun_cloneoverlay")
			net.WriteBool(true)
		net.Send(self)
	end
	
	function meta:EndClone(replace, kill)
		local clone = self:GetCloneController()
		
		if kill then
			local e = EffectData()
			e:SetOrigin(self:GetPos() + Vector(0,0,40))
			util.Effect("cball_explode", e, true, true)
		end
		
		if not replace then
			local pos = clone:GetPos()
			local ang = clone.PlayerEyeAngles
			timer.Simple(0, function()
				if IsValid(self) then
					self:SetPos(pos)
					self:SetEyeAngles(ang)
				end
			end)
		end
		clone:Remove()
		self:SetCloneController(nil)
		
		local clonenum = self:GetCloneNumber()
		if (kill or self:GetAdrenaline() <= 0) and clonenum > 0 then
			self:SetCloneNumber(clonenum - 1)
			if clonenum > 1 then
				self:SetAdrenaline(100)
			else
				self:SetAdrenaline(0)
			end
		end
	end
	
	function meta:GiveClone(num)
		local num = num or 1
		local clonenum = self:GetCloneNumber()
		if clonenum <= 0 then
			self:SetAdrenaline(100)
		end
		self:SetCloneNumber(clonenum + num)
		
		local e = EffectData()
		e:SetEntity(self)
		util.Effect("sacrifun_cloneget", e, true, true)
	end
	
else
	local isclone = false
	net.Receive("sfun_cloneoverlay", function()
		isclone = net.ReadBool()
	end)
	
	local mat = Model("models/shadertest/shader4")
	local function DrawCloneOverlay()
		if isclone then
			DrawMaterialOverlay(mat, 0.03)
		end
	end
	hook.Add("RenderScreenspaceEffects", "sacrifun_cloneoverlay", DrawCloneOverlay )
end