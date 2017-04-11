AddCSLuaFile()

ENT.Type = "anim"

ENT.PrintName = "Bonepile"
ENT.Category = "Sacrifun"
ENT.Author = "Zet0r"

local bonemodels = {
	"models/skeleton/skeleton_arm.mdl",
	"models/skeleton/skeleton_arm_l.mdl",
	"models/skeleton/skeleton_leg.mdl",
	"models/skeleton/skeleton_leg_l.mdl",
	"models/skeleton/skeleton_torso.mdl",
}

local bonepos = {
	{ -- Right arm
		--[0] = {pos = Vector(0,7,47), ang = Angle(0,0,0)},
		[1] = {pos = Vector(-1,5,55), ang = Angle(110,90,0)},
		--[2] = Vector(0,13,27)
	},
	{ -- Left arm
		--[0] = Vector(0,-13,47),
		[1] = {pos = Vector(-1,-5,55), ang = Angle(70,90,0)},
		--[2] = Vector(0,-13,27)
	},
	{ -- Right leg
		--[0] = Vector(0,13,17),
		[1] = {pos = Vector(0,5,35), ang = Angle(90,90,0)}
		--[2] = Vector(0,0,0)
	},
	{ -- Left leg
		--[0] = Vector(0,-13,17),
		[1] = {pos = Vector(0,-5,35), ang = Angle(90,90,0)}
		--[2] = Vector(0,0,0)
	},
	{ -- Torso
		--[0] = {pos = Vector(0, 0, 40), ang = Angle(0,0,0)}
		--[1] = {pos = Vector(0, 0, 65), ang = Angle(0,90,0)}
		--[2] = {pos = Vector(0, 0, 65), ang = Angle(0,90,0)}
		--[3] = {pos = Vector(0, 0, 65), ang = Angle(0,90,0)}
		--[4] = {pos = Vector(0, 0, 65), ang = Angle(0,90,0)}
		[5] = {pos = Vector(0, 0, 62), ang = Angle(-90,90,0)}
	},
}

local bonespawnpos = {
	Vector(0,13,47), Vector(0,-13,47), Vector(0,13,17), Vector(0,-13,17), Vector(0, 0, 40)
}

function ENT:PreBonePosAng(pos, ang)
	self.BoneSpawnPos = pos
	self.BoneSpawnAng = ang
end

function ENT:Initialize()
	self:SetModel("models/skeleton/skeleton_torso.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetNoDraw(true)
	
	if not self.BoneDropDelay then self:DropBones() end
end

function ENT:DropBones()
	if SERVER then
		self.Bones = {}
		self.BoneDropDelay = nil
		
		for k,v in ipairs(bonemodels) do
			local b = ents.Create("prop_ragdoll")
			b:SetModel(v)
			
			local tpos, tang
			
			if self.BonePositions and self.BonePositions[k] then
				tpos = self.BonePositions[k].pos
				tang = self.BonePositions[k].ang
			else			
				local pos = bonespawnpos[k]
				local ang = self.BoneSpawnAng or self:GetAngles()
				local bppos = self.BoneSpawnPos or self:GetPos()
				
				tpos = bppos + ang:Forward()*pos.x+ang:Right()*pos.y+ang:Up()*pos.z
				tang = ang
			end
			
			b:SetPos(tpos)
			b:SetAngles(tang)
			
			b:Spawn()
			b:SetCollisionGroup(COLLISION_GROUP_WEAPON)
			--b:SetMoveType(MOVETYPE_NONE)
			
			local phys = b:GetPhysicsObject()
			if IsValid(phys) then
				phys:SetPos(tpos)
				phys:SetAngles(tang)
				if self.BoneForce then
					phys:ApplyForceCenter(self.BoneForce)
				end
			end
			
			self.Bones[k] = b
		end
		
		--PrintTable(self.Bones)
	end
end

function ENT:BoneSetupForce(force)
	self.BoneForce = force
end

function ENT:BoneSetupPositions(tbl)
	self.BonePositions = tbl
end

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "Player")
end

function ENT:OnRemove()
	if SERVER then
		if self.Bones then
			for k,v in pairs(self.Bones) do
				if IsValid(v) then
					v:Remove()
				end
			end
		end
	end
end

function ENT:SetRebuildDelay(time)
	self.RebuildDelay = time and CurTime() + time or nil
end

function ENT:SetBoneDropDelay(time)
	self.BoneDropDelay = time and CurTime() + time or nil
end

function ENT:Rebuild()
	local pos = self:GetPos()
	local ang = self:GetAngles()
	
	self.RebuildDelay = nil
	
	if not self.Bones then self:DropBones() end
	for k,v in pairs(self.Bones) do
		if IsValid(v) then
			v:SetNotSolid(true)
			v.BeginPos = {}
			v.EndPos = {}
			v.BeginAng = {}
			v.EndAng = {}
			
			for k2,v2 in pairs(bonepos[k]) do
				local phys = v:GetPhysicsObjectNum(k2)
				if IsValid(phys) then
					phys:Wake()
					phys:EnableCollisions(false)
					phys:SetDamping(100,100)
					
					local tpos = v2.pos
					local targetpos = pos + ang:Forward()*tpos.x+ang:Right()*tpos.y+ang:Up()*tpos.z			
							
					v.BeginPos[k2] = phys:GetPos()
					v.EndPos[k2] = targetpos
					v.BeginAng[k2] = phys:GetAngles()
					v.EndAng[k2] = v2.ang + ang
				end
			end
		end
	end
	self.Rebuilding = CurTime()
end

local rebuildtime = 3
function ENT:Think()
	if self.Rebuilding then
		local diff = (CurTime()-self.Rebuilding)/rebuildtime
		--print(diff)
		if diff >= 1 then
			self.Rebuilding = nil
			local ply = self:GetPlayer()
			if IsValid(ply) then
				if not ply:IsSkeleton() then -- Converted for the first time
					local rew = ply:GetResponsibleRunner()
					print(rew)
					if IsValid(rew) and rew:IsRunner() then
						rew:GiveClone() -- Give reward
						rew:AddFrags(1)
					end
					ply:SetSkeleton()
				end
				ply.ConvertingToSkeleton = nil
				ply:Spawn()
				self:Remove()
			else
				self:Remove()
			end
			for k,v in pairs(self.Bones) do
				for k2,v2 in pairs(v.EndPos) do
					local phys = v:GetPhysicsObjectNum(k2)
					if IsValid(phys) then
						local tpos = v2
				
						phys:SetPos(tpos)
						--phys:Sleep()
						phys:EnableMotion(false)
					end
				end
				v:RagdollSolve()
			end
		else
			local ang = self:GetAngles()
			for k,v in pairs(self.Bones) do				
				for k2,v2 in pairs(v.EndPos) do
					local phys = v:GetPhysicsObjectNum(k2)
					if IsValid(phys) then
						local tpos = LerpVector(diff, v.BeginPos[k2], v2)
						local tang = LerpAngle(diff, v.BeginAng[k2], v.EndAng[k2])
				
						phys:SetPos(tpos)
						phys:SetAngles(tang)
					end
				end
			end
			self:NextThink(CurTime()+0.01)
			return true
		end
	end
	if self.RebuildDelay and self.RebuildDelay < CurTime() then
		self:Rebuild()
	end
	if self.BoneDropDelay and self.BoneDropDelay < CurTime() and not self.Rebuilding then
		self:DropBones()
	end
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