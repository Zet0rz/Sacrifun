GM.Name = "base"
GM.Author = "Zet0r"
GM.Email = "N/A"
GM.Website = "https://youtube.com/Zet0r"

team.SetUp(1, "Runners", Color(100,125,255), true)
team.SetUp(2, "Killer", Color(255,75,75), true)
team.SetUp(3, "Skeletons", Color(255,150,150), true)

function GM:PlayerSwitchFlashlight(ply, SwitchOn)
     return true
end

function GM:PlayerInitialSpawn(ply)

	ply:SetRunner()
	ply:SetCustomCollisionCheck(true)
	
end

function GM:PlayerSpawn(ply)

	ply:StripWeapons()
	player_manager.RunClass(ply, "Loadout")
	
end

local soundthres = 40
function GM:EntityTakeDamage(ply, dmginfo)
	if not ply:IsPlayer() then return end
	local pteam = ply:Team()
	if pteam == 2 then return true end -- Only runner damage!
	
	if dmginfo:GetDamageType() == DMG_CRUSH then dmginfo:ScaleDamage(0.01) end
	
	local dmg = dmginfo:GetDamage()
	if pteam == 1 then
		if IsValid(ply.Clone) and not ply.CLONEDMG then
			ply:EndClone()
			return true
		elseif dmg > soundthres then
			if dmg >= ply:Health() and not ply.ConvertingToSkeleton then
				ply:ConvertToSkeleton()
			else
				ply.NextMoanSound = CurTime() + math.Rand(10,15)
				ply:Scream()
			end
		end
	elseif pteam == 3 then
		if dmg > ply:Health() then
			ply:Stun()
			return true
		end
	end
end

hook.Add("ShouldCollide", "sacrifun_clonecollide", function(e1, e2)
	if e1:GetClass() == "sacrifun_clone" and e1:GetPlayerOwner() == e2 then
		return false
	end
	if e2:GetClass() == "sacrifun_clone" and e2:GetPlayerOwner() == e1 then
		return false
	end
	
	if (e1.GetCarriedObject and e1:GetCarriedObject() == e2) or (e2.GetCarriedObject and e2:GetCarriedObject() == e1) then
		return false
	end
end)

function GM:PlayerPostThink(ply)
	if ply:IsRunner() and ply:IsInjured() then
		if not ply.NextMoanSound or ply.NextMoanSound < CurTime() then
			ply:Moan()			
			ply.NextMoanSound = CurTime() + math.Rand(10,15)
		end
	end
end

local function NoClipTest( ply )
	return false
end
hook.Add( "PlayerNoClip", "NoClipTest", NoClipTest )

hook.Add("UpdateAnimation", "sfun_weaponposing", function(ply, vel, max)
	local wep = ply:GetViewModel()
	if IsValid(wep) then
		local param = ply:GetPoseParameter("move_x")
		local param2 = ply:GetPoseParameter("move_y")
		
		if CLIENT then
			param = param*2 - 1
			param2 = param2*2 - 1
		end
		
		wep:SetPoseParameter("move_x", param)
		wep:SetPoseParameter("move_y", param2)
	end
end)

function GM:PlayerFootstep(ply, pos, foot, sound, volume, filter)
	-- Maybe add killer heavy footsteps
	-- Maybe increase volume of player footstep if sprinting?
end