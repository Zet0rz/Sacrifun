AddCSLuaFile()

ENT.Base = "base_nextbot"
ENT.PrintName = "Player Clone Controller"
ENT.Category = "Sacrifun"
ENT.Author = "Zet0r"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

local clonetime = 20 -- Time for each clone life
local clonetickdelay = clonetime/100

function ENT:Initialize()
    --change those after creation
    --self:SetModel( "models/player/kleiner.mdl" )
	self.NextCloneTick = CurTime() + clonetickdelay
	self:SetCustomCollisionCheck(true)
	
	self:SetColor(Color(255,255,255,50))
	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	
	self:SetHealth(10000)
end

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "PlayerOwner")
end

function ENT:SetCloneOwner(ply)
	if IsValid(ply) then
		self:SetModel(ply:GetModel())
		self:SetPlayerOwner(ply)
		self:CollisionRulesChanged()
	end
end

function ENT:Think()
	if SERVER then
		if self.NextCloneTick < CurTime() then
			local owner = self:GetPlayerOwner()
			if IsValid(owner) then
				local target = owner:GetAdrenaline() - 1
				owner:SetAdrenaline(target)
				if target <= 0 then
					owner:EndClone()
				end
			end
			self.NextCloneTick = CurTime() + clonetickdelay
		end
	end
end

function ENT:BodyUpdate()
    if self:GetActivity() != ACT_HL2MP_IDLE_CROUCH_MAGIC then self:StartActivity( ACT_HL2MP_IDLE_CROUCH_MAGIC ) end
end

function ENT:RunBehaviour()
	while (true) do
        coroutine.wait(60)
    end
end

--[[local mat = Material("Models/effects/comball_tape")
function ENT:Draw()
	
	self:DrawModel()
	--render.MaterialOverride(mat)
	--self:DrawModel()
	--render.MaterialOverride(nil)

end]]

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

function ENT:OnTakeDamage(dmginfo)
	local dmg = dmginfo:GetDamage()
	local ply = self:GetPlayerOwner()
	
	--print(ply:Health(), dmg)
	
	if IsValid(ply) and dmg > ply:Health() then
		ply:SetPos(self:GetPos())
		ply:SetEyeAngles(self:GetAngles())
		self:Remove()
	end
	
	ply.CLONEDMG = true
	ply:TakeDamageInfo(dmginfo)
	ply.CLONEDMG = nil
end

function ENT:OnRemove()
	local ply = self:GetPlayerOwner()
	if IsValid(ply) and SERVER then
		net.Start("sfun_cloneoverlay")
			net.WriteBool(false)
		net.Send(ply)
	end
end