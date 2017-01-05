AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("playerclass.lua")
AddCSLuaFile("player.lua")
AddCSLuaFile("sensing.lua")
AddCSLuaFile("player_clones.lua")
--AddCSLuaFile("actions.lua")
AddCSLuaFile("round.lua")
AddCSLuaFile("blinding.lua")
AddCSLuaFile("blindphase_props.lua")

include("shared.lua")
include("playerclass.lua")
include("player.lua")
include("sensing.lua")
include("player_clones.lua")
--include("actions.lua")
include("doors.lua")
include("round.lua")
include("blinding.lua")
include("blindphase_props.lua")
include("anti_stuck.lua")
include("health_stealing.lua")

function GM:GetFallDamage(ply, speed)
	if IsValid(ply:GetCarryingPlayer()) or ply.GrabImmunity > CurTime() then
		return 0
	else
		return speed/15
	end
end

function GM:PlayerInitialSpawn(ply)

	ply:AutoAssignTeam()
	ply:SetCustomCollisionCheck(true)
	
end

function GM:PlayerSpawn(ply)
	ply:SetupHands()
	
	if ply:Team() == 3 then
		--[[net.Start("sfun_PlayerSkeleton")
			net.WriteEntity(ply)
			net.WriteBool(false)
		net.Broadcast()]]
		ply:SetNoDraw(false)
		
		if IsValid(ply.BonePile) then
			ply:SetPos(ply.BonePile:GetPos())
			ply:SetEyeAngles(ply.BonePile:GetAngles())
			ply.BonePile:Remove()
		end
	end
	
	if ply.PlayerSetUp then
		player_manager.RunClass(ply, "Loadout")
	end
	
	ply.GrabImmunity = CurTime() + 1
	ply.StunImmunity = CurTime() + 3
	ply.HealthStealImmunity = CurTime() + 3
	
	-- Reset variables
	ply:SetCarriedObject(nil)
	ply:SetCarryingPlayer(nil)
	ply:SetAdrenaline(100)
	ply:SetCloneNumber(1)
	ply:SetIsSensing(false)
	ply.SenseCooldown = 1
	ply:SensePing(nil, true) -- Don't show killer
	ply.ConvertingToSkeleton = nil
end

function GM:PlayerSetHandsModel( ply, ent )

	local info = player_manager.RunClass( ply, "GetHandsModel" )
	if not info then
		local playermodel = player_manager.TranslateToPlayerModelName( ply:GetModel() )
		info = player_manager.TranslatePlayerHands( playermodel )
	end
	
	if ( info ) then
		ent:SetModel( info.model )
		ent:SetSkin( info.skin )
		ent:SetBodyGroups( info.body )
	end

end

function GM:PlayerDeathThink(ply)
	if ply:IsKiller() then
		local ct = CurTime()
		if not ply.NextSpawnTime then ply.NextSpawnTime = ct + 3 end
		
		if ply.NextSpawnTime < ct and (ply:KeyDown(IN_ATTACK) or ply:KeyDown(IN_JUMP)) then 
			ply:Spawn()
		end
	end
end

function GM:CanPlayerSuicide(ply)
	if ply:IsSkeleton() then
		if IsValid(ply.BonePile) then
			local pile = ply.BonePile
			ply.BonePile = nil
			ply:Spawn()
			ply.BonePile = pile
		end
		ply:Stun()
		return false
	elseif ply:IsRunner() then
		ply:ConvertToSkeleton()
		return false
	else
		return true
	end
end

function GM:DoPlayerDeath(ply, attacker, dmginfo)
	ply:AddDeaths(1)
	
	if IsValid(attacker) and attacker:IsPlayer() then
		if ( attacker == ply ) then
			attacker:AddFrags(-1)
		else
			attacker:AddFrags(1)
		end
	end
	
	if not ply:IsSkeleton() then
		if not ply.ConvertingToSkeleton then -- Fallback, sometimes you don't convert
			ply:ConvertToSkeleton()
		end
		ply:CreateRagdoll()
	end
end

resource.AddWorkshop("821019109")