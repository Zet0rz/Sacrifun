if SERVER then
	AddCSLuaFile()
	SWEP.Weight			= 5
	SWEP.AutoSwitchTo	= false
	SWEP.AutoSwitchFrom	= true
end

if CLIENT then

	SWEP.PrintName     	    = "Crowbar"			
	SWEP.Slot				= 1
	SWEP.SlotPos			= 1
	SWEP.DrawAmmo			= false
	SWEP.DrawCrosshair		= true

end


SWEP.Author			= "Zet0r"
SWEP.Contact		= "youtube.com/Zet0r"
SWEP.Purpose		= "Kill those runners!"
SWEP.Instructions	= "Let the gamemode give you it"
SWEP.Base			= "sacrifun_runner"

SWEP.Spawnable			= false
SWEP.AdminSpawnable		= false

SWEP.HoldType = "melee"

SWEP.ViewModel	= "models/weapons/c_crowbar.mdl"
SWEP.WorldModel	= "models/weapons/w_crowbar.mdl"
SWEP.UseHands = true

SWEP.CanPush = false
SWEP.CanTackle = false
SWEP.CanHeal = false
SWEP.CanBlind = false
SWEP.CanCarry = true
SWEP.CanSprintCarry = false
SWEP.CanTacklePlayers = false
SWEP.CanPushPlayers = false
SWEP.CanSense = false

function SWEP:DrawWorldModel()
	self:DrawModel()
end

function SWEP:Initialize()

	if SERVER then self:SetHoldType(self.HoldType) end
	self.NextIdleTime = 0
	--self.WipeTime = 0
	
end

local hitdmg = 55
local swingsound = Sound( "Weapon_Crowbar.Single" )
local hitsound = Sound( "Weapon_Crowbar.Melee_Hit" )
function SWEP:PrimaryAttack()
	local ply = self.Owner
	ply:LagCompensation(true)
	
	local tr = util.TraceHull({
		start = ply:GetShootPos(),
		endpos = ply:GetShootPos() + ply:GetAimVector()*100,
		filter = ply,
		mins = Vector( -5, -5, -5 ),
		maxs = Vector( 5, 5, 5 ),
		mask = MASK_SHOT
	})
	
	if tr.Hit then
		local ent = tr.Entity
		
		if SERVER then
			self.WipeTime = CurTime() + 1
			
			local d = DamageInfo()
			d:SetAttacker(ply)
			d:SetInflictor(ply)
			d:SetDamage(hitdmg)
			
			if IsValid(ent) and ent:IsPlayer() then
				if ent:IsRunner() then
					ent:SprintBurst(3)
					self.Owner:SlowDown(3)
					ent:TakeDamageInfo(d)
				else
					ent:Stun()
					self.Owner:SlowDown(1)
				end
			elseif ent:GetClass() == "sacrifun_clone" then
				ent:OnTakeDamage(d)
				self.Owner:SlowDown(3)
			else
			
			end
		end
		
		self:SendWeaponAnim(ACT_VM_HITCENTER)
		self.Owner:SetAnimation(PLAYER_ATTACK1)
		
		self:SetNextPrimaryFire(CurTime() + 3)
		self:EmitSound(hitsound)
	else
		self:SendWeaponAnim(ACT_VM_MISSCENTER)
		self.Owner:SetAnimation(PLAYER_ATTACK1)
		
		self:SetNextPrimaryFire(CurTime() + 1)
		self:EmitSound(swingsound)
		
		if SERVER then
			self.Owner:SlowDown(1)
		end
	end
	
	ply:LagCompensation(false)
	
end

local secondaryacts = {
	["prop_door_rotating"] = function(ply, ent, sprint)
		if ent.SlamShutTime and ent.SlamShutTime > CurTime() then return end
		ent:Use(ply, ply, SIMPLE_USE, 1)
		ent:SetKeyValue("speed", ent.OriginalDoorSpeed or "100")
	end,
	["func_door_rotating"] = function(ply, ent, sprint)
		if ent.SlamShutTime and ent.SlamShutTime > CurTime() then return end
		ent:SetKeyValue("speed", ent.OriginalDoorSpeed or "100")
		ent:Use(ply, ply, SIMPLE_USE, 1)
		ent:SetKeyValue("speed", ent.OriginalDoorSpeed or "100")
	end,
	["func_door"] = function(ply, ent, sprint)
		if ent.SlamShutTime and ent.SlamShutTime > CurTime() then return end
		ent:SetKeyValue("speed", ent.OriginalDoorSpeed or "100")
		ent:Use(ply, ply, SIMPLE_USE, 1)
		ent:SetKeyValue("speed", ent.OriginalDoorSpeed or "100")
	end,
}

function SWEP:SecondaryAttack()
	if self:GetActionLocked() or CLIENT then return end
	
	local ply = self.Owner
	if !IsValid(self.CarriedObject) then
		local sprint = ply:KeyDown(IN_SPEED) --and ply:GetVelocity():Length2D() > 100
		local tr
		self.Owner:LagCompensation(true)
		if sprint then
			tr = util.TraceHull( {
				start = ply:GetShootPos(),
				endpos = ply:GetShootPos() + ply:GetAimVector()*200,
				filter = ply,
				mins = Vector( -5, -5, -5 ),
				maxs = Vector( 5, 5, 5 ),
				mask = MASK_SHOT
			} )
		else
			tr = util.QuickTrace(ply:EyePos(), ply:GetAimVector()*(sprint and 200 or 100), ply)
		end
		self.Owner:LagCompensation(true)
		if IsValid(tr.Entity) then
			if secondaryacts[tr.Entity:GetClass()] then
				secondaryacts[tr.Entity:GetClass()](ply, tr.Entity, sprint)
			else
				self:PickupObject(tr.Entity, sprint, tr)
			end
		end
	end
	
end

local maxdist = 125^2
function SWEP:Think()
	local ct = CurTime()
	
	if self.WipeTime and ct > self.WipeTime then
		self:SendWeaponAnim(ACT_VM_DRAW)
		self.Owner:GetViewModel():SetPlaybackRate(0.5)
		self.WipeTime = nil
	end
	
	if IsValid(self.CarriedObject) then
		if not self.Owner:KeyDown(IN_ATTACK2) then
			self:ReleaseObject()
			return
		elseif not self.NextDistCheck or self.NextDistCheck < ct then
			if self.Owner:GetShootPos():DistToSqr(self.CarriedObject:GetPos()) > maxdist then
				self:ReleaseObject()
				return
			else
				self.NextDistCheck = ct + 1
			end
		end
		
		if self.CarriedObject.Carry then
			self.CarriedObject:Carry(self.Owner, self.CarryDist, self.SprintCarry, self.CarriedPhys)
			return
		else
			if IsValid(self.CarriedPhys) then
				local pos = self.Owner:GetShootPos() + self.Owner:GetAimVector()*self.CarryDist
				
				--[[if self.CarryShadow then
					local ang = self.Owner:GetAngles() --+ self.CarryAng
					self.CarriedPhys:UpdateShadow(pos, ang, FrameTime())]]
				if IsValid(self.CarryHack) then
					self.CarryHack:SetPos(pos)
					self.CarryHack:SetAngles(self.Owner:GetAngles())
				else
					local opos = self.CarriedObject:GetBonePosition(1)
					local dir = (pos - opos):GetNormalized()
					local speed = self.SprintCarry and 200000 or 100000
					
					local force = dir*speed*FrameTime()
					self.CarriedPhys:ApplyForceOffset(force, opos)
					debugoverlay.Line(opos, opos + force)
					return
				end
			end
		end
	elseif self.CarriedObject then
		self:ReleaseObject()
	end
	
	if self.NextDrop and ct > self.NextDrop then
		self:ReleaseObject()
		self.NextDrop = nil
	end
end

-- Non-sprinting (normal pickup)
local validpicks = {
	["prop_physics"] = true,
	["sacrifun_door"] = true,
}
local nonshadows = {
	["sacrifun_door"] = true,
}

-- From right click, sprint is true if sprinting action
function SWEP:PickupObject(ent, sprint, tr)
	if self:GetActionLocked() or IsValid(self.CarriedObject) then return end
	
	if IsValid(ent) then
		if validpicks[ent:GetClass()] then
			local allow, time, forcenonsprint = self:ValidPickups(ent, sprint, tr)
			local phys = ent:GetPhysicsObject()
			
			if allow then
				time = time or 0.5
				if IsValid(ent.CarryingWep) then
					ent.CarryingWep:ReleaseObject() -- Steal from the other player
				end
			
				phys:AddGameFlag(FVPHYSICS_PLAYER_HELD)
				if not ent.OldMass then ent.OldMass = phys:GetMass() end
				phys:SetMass(0.1)
				self.CarriedPhys = phys
				
				-- Using TTT's CarryHack
				local hack = ents.Create("prop_physics")
				if IsValid(hack) then
					hack:SetPos(tr.HitPos)
					hack:SetAngles(self.Owner:GetAngles())
					hack:SetModel("models/weapons/w_bugbait.mdl")
					hack:SetNoDraw(true)
					hack:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
					hack:SetNotSolid(true)
					hack:SetOwner(self.Owner)
					hack:Spawn()
					
					local hphys = hack:GetPhysicsObject()
					if IsValid(hphys) then
						hphys:SetMass(200)
						hphys:SetDamping(0, 1000)
						hphys:EnableGravity(false)
						hphys:EnableCollisions(false)
						hphys:EnableMotion(false)
						hphys:AddGameFlag(FVPHYSICS_PLAYER_HELD)
					end
					
					self.CarryHack = hack
					self.Constr = constraint.Weld(self.CarryHack, ent, 0, 0, 0, true)
				else
					return -- Back out, we failed!
				end
				
				self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
				self.NextIdleTime = nil
				
				local dist = ent.GetPickupDistance and ent:GetPickupDistance(tr)
				if not dist then
					dist = math.Clamp((self.Owner:GetShootPos() - tr.HitPos):Length(), 50, 100)
				end
				
				self.CarryDist = dist or 75
				self.CarriedObject = ent
				ent.CarryingWep = self
				self:SetActionLocked(true)
				
				self.Owner:SetRunSpeed(75)
				self.Owner:SetWalkSpeed(75)
			end
		end
	end
end

function SWEP:ReleaseObject()
	if CLIENT then return end
	local ent = self.CarriedObject
	if IsValid(ent) then
		local phys = ent:GetPhysicsObject()
		if self.CarryShadow then
			ent:PhysicsInit(SOLID_VPHYSICS)
			phys = ent:GetPhysicsObject()
		end
		
		self.Owner:DropObject()
		ent:GetPhysicsObject():ClearGameFlag(FVPHYSICS_PLAYER_HELD)
		ent.CarryingWep = nil
		self.Owner:SetCarriedObject(nil)
		self.Owner:CollisionRulesChanged()
		
		if IsValid(phys) then
			phys:Wake()
			timer.Simple(0, function() if IsValid(ent) and IsValid(phys) and ent.OldMass then phys:SetMass(ent.OldMass) end end)
		end
		
		if ent.OnDropped then ent:OnDropped(self.Owner) end
		self.CarriedObject = nil
		self.CarriedPhys = nil
		self.CarryDist = nil
		self.CarryShadow = nil
	end
	if IsValid(self.CarryHack) then self.CarryHack:Remove() end
	if IsValid(self.Constr) then self.Constr:Remove() end
	
	self.NextIdleTime = 0
	self:SetActionLocked(false)
	
	self.Owner:SetRunSpeed(350)
	self.Owner:SetWalkSpeed(225)
end