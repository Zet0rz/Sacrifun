
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
		local clone = self.Clone
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
		self.Clone = clone
		
		net.Start("sfun_cloneoverlay")
			net.WriteBool(true)
		net.Send(self)
	end
	
	function meta:EndClone(replace)
		local clone = self.Clone
		if not replace then
			self:SetPos(clone:GetPos())
			self:SetEyeAngles(clone.PlayerEyeAngles)
		end
		clone:Remove()
		self.Clone = nil
		
		local clonenum = self:GetCloneNumber()
		if self:GetAdrenaline() <= 0 and clonenum > 0 then
			self:SetCloneNumber(clonenum - 1)
			if clonenum > 1 then
				self:SetAdrenaline(100)
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