AddCSLuaFile()

ENT.Type = "anim"

ENT.Base = "prop_physics"
ENT.PrintName = "Door"
ENT.Category = "Sacrifun"
ENT.Author = "Zet0r"

function ENT:Initialize()
	local door = self:GetMapDoor()
    if IsValid(door) then
		--self:SetModel(door:GetModel())
	end
	self:PhysicsInit(SOLID_VPHYSICS)
	--self:SetMoveType(MOVETYPE_NONE)
	
	local ang = self:GetAngles()
	local hpos = Vector(0,0,0)
	local hpos2 = ang:Right()*5
	
	self.ClosedAng = self:GetAngles()
	
	local zmin, zmax
	if math.random(0,1) == 0 then
		zmin = -90
		zmax = GetConVar("sfun_doors_oneway"):GetBool() and 0 or 90
	else
		zmin = GetConVar("sfun_doors_oneway"):GetBool() and 0 or -90
		zmax = 90
	end
	
	if SERVER then self.Constr = constraint.AdvBallsocket(self, Entity(0), 0, 0, hpos, hpos2, 0, 0, 0, 0, zmin, 0, 0, zmax, 10000, 10000, 1, 1, 1) end
	
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
	end
end

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "MapDoor")
end

function ENT:OnPickedUp(ply, sprint)
	if self.SlamShutTime and CurTime() < self.SlamShutTime then
		return false
	end
	
	self:Open()
	self.Carried = ply
	self.SprintCarry = sprint
	
	return true, 0.25 -- A quater of a second sprint carry duration
end

function ENT:OnDropped(ply)
	self.Carried = nil
	self.LastCarryPos = nil
	
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:SetDamping(1,1)
	end
end

function ENT:Open()
	local door = self:GetMapDoor()
    if IsValid(door) then
		door:Fire("Open")
	end
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(true)
		phys:SetDamping(20,20)
		phys:Wake()
	end
end

function ENT:Close()
	local door = self:GetMapDoor()
    if IsValid(door) then
		door:Fire("Close")
	end
	
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		self:SetAngles(self.ClosedAng)
		phys:SetAngles(self.ClosedAng)
		phys:EnableMotion(false)
		phys:Sleep()
	end
	self.IsInOpenState = nil
	if self.SprintCarry then
		self.SlamShutTime = CurTime() + 1
	end
	self.SprintCarry = nil
end

function ENT:Freeze()
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		--phys:EnableMotion(false)
		--phys:Sleep()
		phys:SetDamping(20,20)
	end
	--self.IsInOpenState = nil
end

function ENT:OnRemove()
	if SERVER and IsValid(self.Constr) then
		self.Constr:Remove()
	end
end

function ENT:PhysicsUpdate(phys)
	if SERVER then
		if !IsValid(self.Carried) or self.SprintCarry then
			local ang = phys:GetAngles()
			local tang = self.ClosedAng
			
			local dot = ang:Forward():Dot(tang:Forward())
			local open = self.IsInOpenState
			
			if open and dot >= 0.995 then
				self:Close()
				self.IsInOpenState = nil
			elseif open and dot < 0.005 or dot > 0.99 then
				self:Freeze()
			else
				self.IsInOpenState = true
			end
		end
	end
end

function ENT:Carry(ply, dist, sprint, phys)
	local pos = ply:GetShootPos() + ply:GetAimVector()*dist
	--local opos = self:GetBonePosition(1)
	local opos = self.LastCarryPos or self:GetBonePosition(1)
	local dir = (pos - opos):GetNormalized()
	local speed = sprint and 400000 or 100000
	
	local force = dir*speed*FrameTime()
	force.z = 0
	
	phys:ApplyForceOffset(force, opos)
	debugoverlay.Line(opos, opos + force)
	
	self.LastCarryPos = pos
end

function ENT:GetPickupDistance(tr)
	return (tr.StartPos - tr.HitPos):Length()
end

function ENT:Use()
end

local mat = Material("Models/effects/comball_tape")
function ENT:Draw()
	
	self:DrawModel()
	render.MaterialOverride(mat)
	self:DrawModel()
	render.MaterialOverride(nil)

end