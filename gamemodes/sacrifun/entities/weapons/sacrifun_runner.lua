if SERVER then
	AddCSLuaFile()
	SWEP.Weight			= 5
	SWEP.AutoSwitchTo	= false
	SWEP.AutoSwitchFrom	= true
end

if CLIENT then

	SWEP.PrintName     	    = "Hands"			
	SWEP.Slot				= 1
	SWEP.SlotPos			= 1
	SWEP.DrawAmmo			= false
	SWEP.DrawCrosshair		= true

end


SWEP.Author			= "Zet0r"
SWEP.Contact		= "youtube.com/Zet0r"
SWEP.Purpose		= "Fancy Viewmodel Animations"
SWEP.Instructions	= "Let the gamemode give you it"

SWEP.Spawnable			= false
SWEP.AdminSpawnable		= false

SWEP.HoldType = "normal"

SWEP.ViewModel	= "models/weapons/c_sacrifun_arms.mdl"
SWEP.WorldModel	= "models/weapons/w_crowbar.mdl"
SWEP.UseHands = true
--SWEP.vModel = true

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

SWEP.CanPush = true
SWEP.CanTackle = true
SWEP.CanHeal = true
SWEP.CanBlind = true
SWEP.CanCarry = true
SWEP.CanSprintCarry = true
SWEP.CanTacklePlayers = true
SWEP.CanPushPlayers = true
SWEP.CanSense = true

local AC_LMB = 0
local AC_LMB_SPRINT = 1
local AC_RMB = 2
local AC_RMB_SPRINT = 3

local actions = {
	["player"] = {
		
	},
	["prop_physics"] = {
		[AC_RMB] = "Pickup/Drop",
		[AC_RMB_SPRINT] = "Pull behind",
	}
}

function SWEP:Initialize()

	if SERVER then self:SetHoldType(self.HoldType) end
	self.NextIdleTime = 0

end

function SWEP:SetupDataTables()
	self:NetworkVar("Bool", 0, "ActionLocked")
end

function SWEP:Deploy()
	if IsValid(self.Owner:GetViewModel()) then self.Owner:SetupHands() end
	if IsValid(self.Owner:GetViewModel()) then
		self.Owner:GetViewModel():SetNoDraw(false)
	end
end

local primaryacts = {

}
function SWEP:PrimaryAttack()	
	if self:GetActionLocked() then return end
	local ply = self.Owner
	
	if self.Owner:KeyDown(IN_WALK) and not self.Sprinting and self.CanBlind then
		-- Flashlight blinding
		self:StartFlash()
		return
	end
	
	local sprint = ply:KeyDown(IN_SPEED) --and ply:GetVelocity():Length2D() > 100
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
	
	if IsValid(tr.Entity) and primaryacts[tr.Entity:GetClass()] then
		primaryacts[tr.Entity:GetClass()](ply, tr.Entity, sprint)
	else
		if sprint then self:Tackle(tr.Entity, tr) else self:Push(tr.Entity, tr) end
	end
	
end

local secondaryacts = {
	["prop_door_rotating"] = function(ply, ent, sprint)
		if ent.SlamShutTime and ent.SlamShutTime > CurTime() then return end
		ent:Use(ply, ply, SIMPLE_USE, 1)
		if sprint then
			ent:SetKeyValue("speed", "1000")
			ent.SlamShutTime = CurTime() + 0.5 -- Won't be openable for this amount of time!
			ply:SetCarriedObject(ent)
			ply:CollisionRulesChanged()
			timer.Simple(1, function()
				if IsValid(ply) then
					ply:SetCarriedObject(nil)
					ply:CollisionRulesChanged()
				end
			end)
		else
			ent:SetKeyValue("speed", ent.OriginalDoorSpeed or "100")
		end
	end,
	["func_door_rotating"] = function(ply, ent, sprint)
		if ent.SlamShutTime and ent.SlamShutTime > CurTime() then return end
		if sprint then
			ent:SetKeyValue("speed", "1000")
		else
			ent:SetKeyValue("speed", ent.OriginalDoorSpeed or "100")
		end
		ent:Use(ply, ply, SIMPLE_USE, 1)
		if sprint then
			
			ent.SlamShutTime = CurTime() + 0.5 -- Won't be openable for this amount of time!
			ply:SetCarriedObject(ent)
			ply:CollisionRulesChanged()
			timer.Simple(1, function()
				if IsValid(ply) then
					ply:SetCarriedObject(nil)
					ply:CollisionRulesChanged()
				end
			end)
		else
			ent:SetKeyValue("speed", ent.OriginalDoorSpeed or "100")
		end
	end,
	["func_door"] = function(ply, ent, sprint)
		if ent.SlamShutTime and ent.SlamShutTime > CurTime() then return end
		if sprint then
			ent:SetKeyValue("speed", "300")
		else
			ent:SetKeyValue("speed", ent.OriginalDoorSpeed or "100")
		end
		ent:Use(ply, ply, SIMPLE_USE, 1)
		if sprint then
			
			ent.SlamShutTime = CurTime() + 0.5 -- Won't be openable for this amount of time!
			ply:SetCarriedObject(ent)
			ply:CollisionRulesChanged()
			timer.Simple(1, function()
				if IsValid(ply) then
					ply:SetCarriedObject(nil)
					ply:CollisionRulesChanged()
				end
			end)
		else
			ent:SetKeyValue("speed", ent.OriginalDoorSpeed or "100")
		end
	end,
}

function SWEP:SecondaryAttack()
	if self:GetActionLocked() then return end
	--[[if !self.NextIdleTime then
		self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
		self.NextIdleTime = CurTime() + 0.5
		self.UsingAction = true
	end
	self.UsingAction = CurTime() + 0.1]]
	
	if self.Owner:KeyDown(IN_WALK) and not self.Sprinting and self.CanHeal then
		self:StartHeal()
		return
	end
	
	if CLIENT then return end
	
	local ply = self.Owner
	if not IsValid(self.CarriedObject) then
		local sprint = ply:KeyDown(IN_SPEED) --and ply:GetVelocity():Length2D() > 100
		local tr
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
local healfreq = 0.3

local healsounds = {
	"sacrifun/heal/bat_draw.wav",
	"sacrifun/heal/bat_draw_swoosh1.wav",
	"sacrifun/heal/draw_default.wav",
	"sacrifun/heal/draw_melee.wav",
	"sacrifun/heal/draw_primary.wav",
}
function SWEP:Think()
	local ct = CurTime()
	
	if self.NextIdleTime and ct > self.NextIdleTime then
		self:SendWeaponAnim(ACT_VM_IDLE)
		self.NextIdleTime = nil
		self.Sprinting = false
		self:SetActionLocked(false)
	end
	
	if self.HealTime and ct > self.HealTime then
		if not self.Owner:KeyDown(IN_ATTACK2) or not self.Owner:KeyDown(IN_WALK) or self.Owner:KeyDown(IN_SPEED) or self.Owner:Health() >= self.Owner:GetMaxHealth() then
			self:EndHeal()
			return
		end
		if not self.Healing then
			self:SendWeaponAnim(ACT_VM_DEPLOYED_IDLE)
			self.Healing = true
		end
		
		if not self.NextHealSound or ct > self.NextHealSound then
			local sound = table.Random(healsounds)
			self.Owner:EmitSound(sound)
			self.NextHealSound = ct + math.Rand(0.5,1)
		end
		
		self.Owner:SetHealth(self.Owner:Health()+1)
		self.HealTime = ct + healfreq
		return
	end
	
	if self.FlashOn then
		if not self.Owner:KeyDown(IN_ATTACK) or not self.Owner:KeyDown(IN_WALK) or self.Owner:KeyDown(IN_SPEED) then
			self:EndFlash()
		elseif SERVER and (not self.NextBlind or self.NextBlind < ct) then
			local shootpos = self.Owner:GetShootPos()
			local aim = self.Owner:GetAimVector()
			local tr = util.TraceLine({
				start = shootpos,
				endpos = shootpos + aim*500,
				filter = self.Owner
			})
			local ent = tr.Entity
			if IsValid(ent) and ent:IsPlayer() and tr.HitGroup == HITGROUP_HEAD then
				local aim2 = ent:GetAimVector()
				if aim:Dot(aim2) <= -0.6 then
					ent:Blind()
				end
			end
			self.NextBlind = ct + 0.4
		elseif CLIENT and IsValid(self.FlashTexture) then
			self.FlashTexture:SetPos(EyePos())
			self.FlashTexture:SetAngles(EyeAngles())
			self.FlashTexture:Update()
		end
		return
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
	
	if not self:GetActionLocked() and not self.NextIdleTime then
		local vel = self.Owner:GetVelocity():Length2D()
		if self.Owner:KeyDown(IN_SPEED) then
			if vel > 100 then
				if not self.Sprinting then
					self:SendWeaponAnim(ACT_VM_SPRINT_IDLE)
					self.Sprinting = true
				end
			elseif self.Sprinting then
				self:SendWeaponAnim(ACT_VM_IDLE)
				self.Sprinting = false
			end
			if SERVER and self.CanSense then
				if self.Owner:KeyDown(IN_WALK) then
					if not self.Sensing then
						self.Owner:StartSensing()
						self.Sensing = true
						self.NextSenseSteal = ct + 0.2
					end
				elseif self.Sensing then
					self.Owner:EndSensing()
					self.Sensing = false
				end
			end
		else
			if self.Sprinting then
				self:SendWeaponAnim(ACT_VM_IDLE)
				self.Sprinting = false
			end
			if SERVER and self.Sensing then
				self.Owner:EndSensing()
				self.Sensing = false
			end
		end
	end
	
	if IsFirstTimePredicted() and self.Sensing and self.NextSenseSteal < ct then
		self.Owner:AttemptHealthSteal()
		self.NextSenseSteal = ct + 0.5
	end
end

function SWEP:PostDrawViewModel()
	
end

function SWEP:DrawWorldModel()
	
end

function SWEP:GetViewModelPosition(pos, ang)
	return pos + ang:Up()*5, ang
end

function SWEP:OnRemove()
	self:ReleaseObject()
	if SERVER then self.Owner:EndSensing() end
end

function SWEP:DrawHUD()
	--[[local ply = LocalPlayer()
	local tr = util.QuickTrace(ply:EyePos(), ply:GetAimVector()*100, ply)
	
	if IsValid(tr.Entity) and actions[tr.Entity:GetClass()] then
		local acts = actions[tr.Entity:GetClass()]
		local txt = ""
		if ply:KeyDown(IN_SPEED) then
			if acts[AC_LMB_SPRINT] then
				txt = txt .. "LMB: "..acts[AC_LMB_SPRINT].." "
			end
			if acts[AC_RMB_SPRINT] then
				txt = txt .. "RMB: "..acts[AC_RMB_SPRINT].." "
			end
		else
			if acts[AC_LMB] then
				txt = txt .. "LMB: "..acts[AC_LMB].." "
			end
			if acts[AC_RMB] then
				txt = txt .. "RMB: "..acts[AC_RMB].." "
			end
		end
		
		draw.SimpleTextOutlined(txt, "DermaLarge", ScrW()/2, ScrH()/2 + 50, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
	end]]
	
end

-- Non-sprinting (normal pickup)
local validpicks = {
	["prop_physics"] = true,
	["prop_physics_multiplayer"] = true,
	["sacrifun_door"] = true,
}
-- Sprinting (nocollided short duration pickup)
local validsprints = {
	["prop_physics"] = true,
	["prop_physics_multiplayer"] = true,
	["player"] = true,
	["sacrifun_door"] = true,
}

local nonshadows = {
	["sacrifun_door"] = true,
}

function SWEP:ValidPickups(ent, sprint, tr)
	local allow, time
	if ent.OnPickedUp then allow, time = ent:OnPickedUp(self.Owner, issprinting) else allow = true end
	return allow, time
end

-- From right click, sprint is true if sprinting action
function SWEP:PickupObject(ent, sprint, tr)
	if self:GetActionLocked() or IsValid(self.CarriedObject) then return end
	
	if IsValid(ent) then
		local issprinting = sprint and validsprints[ent:GetClass()] and self.CanSprintCarry
		if issprinting or (validpicks[ent:GetClass()] and self.CanCarry) then
			
			local allow, time, forcenonsprint = self:ValidPickups(ent, sprint, tr)
			if forcenonsprint then issprinting = false end
			local phys = ent:GetPhysicsObject()
			
			if allow then
				time = time or 0.25
				if ent:IsPlayer() and issprinting and not IsValid(ent:GetCarryingPlayer()) and ent.GrabImmunity < CurTime() then --and ent:GetAimVector():Dot(self.Owner:GetAimVector()) > 0 then
					self.Owner:SetCarriedObject(ent)
					ent:SetCarryingPlayer(self.Owner)
					self.Owner:CollisionRulesChanged()
					self.NextDrop = CurTime() + time
					self:SendWeaponAnim(ACT_VM_PULLBACK)
				else
					if IsValid(ent.CarryingWep) then
						ent.CarryingWep:ReleaseObject() -- Steal from the other player
					end
				
					phys:AddGameFlag(FVPHYSICS_PLAYER_HELD)
					ent.OldMass = phys:GetMass()
					phys:SetMass(1)
					self.CarriedPhys = phys
					
					-- Using Shadow Objects
					
					--[[if !nonshadows[ent:GetClass()] then
						ent:MakePhysicsObjectAShadow(true, true)
						self.CarryShadow = true
					else
						self.CarryShadow = nil
					end
					self.CarryAng = ent:GetAngles() - self.Owner:GetAngles()]]
					
					-- Using TTT's CarryHack
					local hack = ents.Create("prop_physics")
					if IsValid(hack) then
						hack:SetPos(ent:GetPos())
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
					
					if issprinting then -- Nocollides them
						self.Owner:SetCarriedObject(ent)
						self.Owner:CollisionRulesChanged()
						self.NextDrop = CurTime() + time
						self.Owner:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_GMOD_GESTURE_RANGE_ZOMBIE, true)
						self:SendWeaponAnim(ACT_VM_PULLBACK)
						self.Owner:DoAnimationEvent(4)
						self.Owner:SendAnimationEvent(4)
					else
						self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
						self:SetHoldType("grenade")
						self.NextIdleTime = nil
					end
					
					self.SprintCarry = issprinting
				end
				
				local dist = ent.GetPickupDistance and ent:GetPickupDistance(tr)
				if not dist then
					dist = math.Clamp((self.Owner:GetShootPos() - tr.Entity:GetPos()):Length(), 50, 100)
				end
				
				self.CarryDist = dist or 75
				self.CarriedObject = ent
				ent.CarryingWep = self
				self:SetActionLocked(true)
			end
		end
	end
end

function SWEP:ReleaseObject()
	local ent = self.CarriedObject
	if IsValid(ent) then
		if ent:IsPlayer() then
			ent:SetCarryingPlayer(nil)
			ent.GrabImmunity = CurTime() + 1 -- Immune to grab and fall damage for 1 sec!
			
			self.Owner:CollideWhenPossible()
		else
			local phys = ent:GetPhysicsObject()
			if self.CarryShadow then
				ent:PhysicsInit(SOLID_VPHYSICS)
				phys = ent:GetPhysicsObject()
			end
			
			self.Owner:DropObject()
			phys:ClearGameFlag(FVPHYSICS_PLAYER_HELD)
			if self.SprintCarry then phys:SetVelocity(phys:GetVelocity()*0.2) end
			ent.CarryingWep = nil
			self.Owner:CollideWhenPossible()
			
			if IsValid(phys) then
				phys:Wake()
				timer.Simple(0, function() if IsValid(ent) and IsValid(phys) and ent.OldMass then phys:SetMass(ent.OldMass) end end)
			end
			
			if ent.OnDropped then ent:OnDropped(self.Owner) end
		end
	end
	
	self.CarriedObject = nil
	self.CarriedPhys = nil
	self.CarryDist = nil
	self.CarryShadow = nil
	if IsValid(self.CarryHack) then self.CarryHack:Remove() end
	if IsValid(self.Constr) then self.Constr:Remove() end
	
	self.NextIdleTime = 0
	if SERVER then self:SetHoldType(self.HoldType) end
end

function SWEP:Push(ent, tr)
	if self:GetActionLocked() or not self.CanPush then return end
	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	self.NextIdleTime = CurTime() + 0.25
	self:SetActionLocked(true)
	if SERVER then
		self.Owner:DoAnimationEvent(1)
		self.Owner:SendAnimationEvent(1)
	end

	if IsValid(ent) then
		local phys = ent:GetPhysicsObject()
		if IsValid(phys) then
			local pos = tr.HitPos
			local pos2 = self.Owner:GetShootPos()
			
			local force = (pos - pos2):GetNormalized()
			
			if ent:IsPlayer() then
				if not self.CanPushPlayers then return end
				ent:SetGroundEntity(nil)
				ent:SetVelocity(force*100)
			end
			phys:ApplyForceOffset(force*math.Clamp(phys:GetMass(), 1, 1000)*300, pos)
		end
	end
end

function SWEP:Tackle(ent, tr)
	if self:GetActionLocked() or not self.CanTackle then return end
	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK_2)
	self.Owner:ViewPunch(Angle(10,-45,0))
	
	if not (self.Owner:GetGroundEntity() == NULL) then
		local dir = self.Owner:GetAimVector()
		dir.z = 0
		self.Owner:SetVelocity(dir*1000)
	end

	if SERVER then
		self.Owner:DoAnimationEvent(2)
		self.Owner:SendAnimationEvent(2)
		self.Owner:SlowDown(1)
		if IsValid(ent) then
			local class = ent:GetClass()
			if ent:IsPlayer() then
				if self.CanTacklePlayers and not ent:IsKiller() and ent.StunImmunity < CurTime() then
					ent:Stun(3)
				end
			elseif class == "prop_door_rotating" then
				ent:Use(ply, ply, SIMPLE_USE, 1)
				ent:SetKeyValue("speed", "1000")
				ent.SlamShutTime = CurTime() + 0.5 -- Won't be openable for this amount of time!
			elseif class == "func_breakable" then
				ent:Fire("Break")
			else
				local phys = ent:GetPhysicsObject()
				if IsValid(phys) then
					local pos = tr.HitPos
					local pos2 = self.Owner:GetShootPos()
					
					local force = (pos - pos2):GetNormalized()
					phys:ApplyForceOffset(force*math.Clamp(phys:GetMass(), 1, 1000)*300, pos)
				end
			end
		end
	end
	
	self.NextIdleTime = CurTime() + 1
	self:SetActionLocked(true)
end

function SWEP:StartHeal()
	if self:GetActionLocked() or self.Owner:Health() >= self.Owner:GetMaxHealth() then return end
	self:SendWeaponAnim(ACT_VM_DEPLOYED_IN)
	self:SetCycle(0)
	self.HealTime = CurTime() + 0.5
	self:SetActionLocked(true)
	self:SetHoldType("slam")
end

function SWEP:EndHeal()
	self:SendWeaponAnim(ACT_VM_DEPLOYED_OUT)
	self.NextIdleTime = CurTime() + 1
	self.HealTime = nil
	self.Healing = nil
	if SERVER then self:SetHoldType(self.HoldType) end
end

function SWEP:StartFlash()
	if SERVER then
		if self.Owner:FlashlightIsOn() then
			self.FlashWasOn = true
		end
		self.Owner:Flashlight(false)
		self:SetActionLocked(true)
		self:SetHoldType("pistol")
	elseif not IsValid(self.FlashTexture) then
		self.FlashTexture = ProjectedTexture()
		self.FlashTexture:SetEnableShadows(true)
		self.FlashTexture:SetTexture("effects/flashlight001")
		self.FlashTexture:SetFOV(10)
		self.FlashTexture:SetFarZ(500)
		self.FlashTexture:Update()
	end
	
	self.FlashOn = true
	
end

function SWEP:EndFlash()
	if SERVER then
		if self.FlashWasOn then
			self.Owner:Flashlight(true)
			self.FlashWasOn = nil
		else
			self.Owner:Flashlight(false)
		end
		self:SetHoldType(self.HoldType)
	elseif IsValid(self.FlashTexture) then
		self.FlashTexture:Remove()
	end
	
	self.FlashOn = false
	self.NextIdleTime = 0
	
end

function SWEP:Reload()
	local ct = CurTime()
	if not self.NextTaunt or self.NextTaunt < ct then
		local dur = self.Owner:Taunt()
		self.NextTaunt = ct + dur + 0.2
	end
end

function SWEP:Stun(time) -- When you get stunned
	if self.Healing then
		self:EndHeal()
		self:Scream()
	end
	if self.CarriedObject then self:ReleaseObject() end
	if self.FlashOn then self:EndFlash() end
	self:SetActionLocked(true)
	self.NextIdleTime = CurTime() + time
end
