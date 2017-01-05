DEFINE_BASECLASS( "player_default" )

local runspeed = 280
local walkspeed = 200

local killerrun = 300
local killerwalk = 210

local PLAYER_RUNNER = {}

function PLAYER_RUNNER:SetupDataTables()
	
	self.Player:NetworkVar("Int", 0, "Adrenaline")
	self.Player:NetworkVar("Int", 1, "CloneNumber")
	self.Player:NetworkVar("Entity", 0, "CarryingPlayer")
	self.Player:NetworkVar("Entity", 1, "CarriedObject")
	self.Player:NetworkVar("Entity", 2, "CloneController")
	self.Player:NetworkVar("Bool", 0, "IsSensing")
	self.Player:NetworkVar("Bool", 1, "NoCollidePlayers")
	
	-- Setting starting variables here as these NetworkVars aren't created when the player is initially spawning
	if SERVER then
		self.Player:SetCarriedObject(nil)
		self.Player:SetCarryingPlayer(nil)
		self.Player:SetCloneController(nil)
		self.Player:SetAdrenaline(0)
		self.Player:SetCloneNumber(0)
		self.Player:SetIsSensing(false)
		self.Player:SetNoCollidePlayers(false)
	end

end

function PLAYER_RUNNER:Loadout()
	self.Player:Give("sacrifun_runner")
end

function PLAYER_RUNNER:Init()
	self.Player:SetRunSpeed(runspeed)
	self.Player:SetWalkSpeed(walkspeed)
	if CLIENT then sfun_SetTeamHUD(1) end
end

local playermodels = {
	"models/player/group01/female_01.mdl",
	"models/player/group01/female_02.mdl",
	"models/player/group01/female_03.mdl",
	"models/player/group01/female_04.mdl",
	"models/player/group01/female_05.mdl",
	"models/player/group01/female_06.mdl",
	"models/player/group01/male_01.mdl",
	"models/player/group01/male_02.mdl",
	"models/player/group01/male_03.mdl",
	"models/player/group01/male_04.mdl",
	"models/player/group01/male_05.mdl",
	"models/player/group01/male_06.mdl",
	"models/player/group01/male_07.mdl",
	"models/player/group01/male_08.mdl",
	"models/player/group01/male_09.mdl"
}

function PLAYER_RUNNER:SetModel()
	self.Player:SetModel( playermodels[math.random(table.Count(playermodels))] )
	self.Player:SetPlayerColor(Vector(0,0.2,1))
end

function PLAYER_RUNNER:Move(mv)
	local ply = self.Player
	local cply = ply:GetCarryingPlayer()
	
	local ct = CurTime()
	
	if ply.StunTime and ply.StunTime > ct then
		mv:SetForwardSpeed(0)
		mv:SetSideSpeed(0)
		mv:SetButtons(0)
	end
	
	if IsValid(cply) then
		local ang = mv:GetMoveAngles()
		local pos = mv:GetOrigin()
		local vel = mv:GetVelocity()
		
		local tpos = cply:GetPos() + cply:GetAimVector()*75
		
		if tpos:DistToSqr(pos) >= 20000 then
			cply:GetActiveWeapon():ReleaseObject()
		end		
		local dir = tpos - pos
		
		vel = dir*FrameTime()*5000
		
		debugoverlay.Cross(tpos, 5)
		debugoverlay.Line(pos, pos + vel)
		
		mv:SetVelocity(vel)
		--mv:SetOrigin(pos + vel)
	elseif ply.SpeedModTime and ply.SpeedModTime < ct then
		ply:SetRunSpeed(runspeed)
		ply:SetWalkSpeed(walkspeed)
		ply.SpeedModTime = nil
		if ply.SprintBurstNoCollide then
			ply:CollideWhenPossible()
		end
	end
end

player_manager.RegisterClass( "sfun_playerclass_runner", PLAYER_RUNNER, "player_default" )

local PLAYER_KILLER = {}

function PLAYER_KILLER:SetupDataTables()

	self.Player:NetworkVar("Int", 0, "Adrenaline")
	self.Player:NetworkVar("Int", 1, "CloneNumber")
	self.Player:NetworkVar("Entity", 0, "CarryingPlayer")
	self.Player:NetworkVar("Entity", 1, "CarriedObject")
	self.Player:NetworkVar("Entity", 2, "CloneController")
	self.Player:NetworkVar("Bool", 0, "IsSensing")
	self.Player:NetworkVar("Bool", 1, "NoCollidePlayers")
	
	if SERVER then
		self.Player:SetCarriedObject(nil)
		self.Player:SetCarryingPlayer(nil)
		self.Player:SetCloneController(nil)
		self.Player:SetAdrenaline(0)
		self.Player:SetCloneNumber(0)
		self.Player:SetIsSensing(false)
		self.Player:SetNoCollidePlayers(false)
	end

end

function PLAYER_KILLER:SetModel()
	self.Player:SetModel( playermodels[math.random(table.Count(playermodels))] )
	self.Player:SetPlayerColor(Vector(1,0,0))
end

function PLAYER_KILLER:Loadout()
	self.Player:Give("sacrifun_killer")
end

function PLAYER_KILLER:Init()
	self.Player:SetRunSpeed(killerrun)
	self.Player:SetWalkSpeed(killerwalk)
	if CLIENT then sfun_SetTeamHUD(2) end
end

local maxjumps = 2
function PLAYER_KILLER:Move(mv)
	local ply = self.Player
	
	if IsValid(ply:GetCarriedObject()) then
		local vel = mv:GetVelocity()
		mv:SetVelocity(vel*0.5)
	end
	
	if ply.SpeedModTime and ply.SpeedModTime < CurTime() then
		ply:SetRunSpeed(killerrun)
		ply:SetWalkSpeed(killerwalk)
		ply.SpeedModTime = nil
		ply.SprintNoCollide = nil
		if ply.SprintBurstNoCollide then
			ply:CollideWhenPossible()
		end
	end
	
	if mv:KeyPressed(IN_JUMP) then
		if IsFirstTimePredicted() then ply.JumpCount = ply.JumpCount and ply.JumpCount + 1 or 1 end
		if ply.JumpCount <= maxjumps and not ply:IsOnGround() then
			local vel = mv:GetVelocity()
			vel.z = ply:GetJumpPower()*2
			mv:SetVelocity(vel)
		end
	elseif ply:IsOnGround() and (not ply.JumpCount or ply.JumpCount > 0) then
		ply.JumpCount = 0
	end
end

player_manager.RegisterClass( "sfun_playerclass_killer", PLAYER_KILLER, "player_default" )

local PLAYER_SKELETON = {}

function PLAYER_SKELETON:SetupDataTables()

	self.Player:NetworkVar("Int", 0, "Adrenaline")
	self.Player:NetworkVar("Int", 1, "CloneNumber")
	self.Player:NetworkVar("Entity", 0, "CarryingPlayer")
	self.Player:NetworkVar("Entity", 1, "CarriedObject")
	self.Player:NetworkVar("Entity", 2, "CloneController")
	self.Player:NetworkVar("Bool", 0, "IsSensing")
	self.Player:NetworkVar("Bool", 1, "NoCollidePlayers")
	
	if SERVER then
		self.Player:SetCarriedObject(nil)
		self.Player:SetCarryingPlayer(nil)
		self.Player:SetCloneController(nil)
		self.Player:SetAdrenaline(0)
		self.Player:SetCloneNumber(0)
		self.Player:SetIsSensing(false)
		self.Player:SetNoCollidePlayers(false)
	end

end

function PLAYER_SKELETON:Loadout()
	self.Player:Give("sacrifun_skeleton")
end

function PLAYER_SKELETON:Move(mv)
	local ply = self.Player
	local cply = ply:GetCarryingPlayer()
	if IsValid(cply) then
		local ang = mv:GetMoveAngles()
		local pos = mv:GetOrigin()
		local vel = mv:GetVelocity()
		
		local tpos = cply:GetPos() + cply:GetAimVector()*75
		local dir = tpos - pos
		
		vel = dir*FrameTime()*5000
		
		debugoverlay.Cross(tpos, 5)
		debugoverlay.Line(pos, pos + vel)
		
		mv:SetVelocity(vel)
		--mv:SetOrigin(pos + vel)
	elseif ply.SpeedModTime and ply.SpeedModTime < CurTime() then
		ply:SetRunSpeed(runspeed)
		ply:SetWalkSpeed(walkspeed)
		ply.SpeedModTime = nil
		ply.SprintNoCollide = nil
		if ply.SprintBurstNoCollide then
			ply:CollideWhenPossible()
		end
	end
end

function PLAYER_SKELETON:Init()
	self.Player:SetRunSpeed(runspeed)
	self.Player:SetWalkSpeed(walkspeed)
	if CLIENT then sfun_SetTeamHUD(3) end
end

function PLAYER_SKELETON:SetModel()
	self.Player:SetModel( "models/player/skeleton.mdl" )
end

function PLAYER_SKELETON:GetHandsModel()
	--return { model = "models/player/vengeance/skeleton_with_hands/c_arms_skully.mdl", skin = 0, body = "0000000" }
end

player_manager.RegisterClass( "sfun_playerclass_skeleton", PLAYER_SKELETON, "player_default" )