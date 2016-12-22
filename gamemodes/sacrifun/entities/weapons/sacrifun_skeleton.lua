if SERVER then
	AddCSLuaFile()
	SWEP.Weight			= 5
	SWEP.AutoSwitchTo	= false
	SWEP.AutoSwitchFrom	= true
end

if CLIENT then

	SWEP.PrintName     	    = "Bones"			
	SWEP.Slot				= 1
	SWEP.SlotPos			= 1
	SWEP.DrawAmmo			= false
	SWEP.DrawCrosshair		= true

end


SWEP.Author			= "Zet0r"
SWEP.Contact		= "youtube.com/Zet0r"
SWEP.Purpose		= "Fancy Viewmodel Animations"
SWEP.Instructions	= "Let the gamemode give you it"

SWEP.Base			= "sacrifun_runner"

SWEP.Spawnable			= false
SWEP.AdminSpawnable		= false

SWEP.CanTacklePlayers = false
SWEP.CanPushPlayers = false
SWEP.CanHeal = false
SWEP.CanBlind = false
SWEP.CanSense = false

function SWEP:ValidPickups(ent, sprint, tr)
	if ent:IsPlayer() then return false end -- No players!
	
	local allow, time
	if ent.OnPickedUp then allow, time = ent:OnPickedUp(self.Owner, issprinting) else allow = true end
	return allow, time
end

function SWEP:Reload()
	-- No taunts for skeletons!
end