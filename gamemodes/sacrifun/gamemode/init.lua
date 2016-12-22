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

function GM:GetFallDamage(ply, speed)
	return speed/10
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

--function GM:PlayerDeathThink(ply)
	
--end

function GM:CanPlayerSuicide(ply)
	if ply:IsSkeleton() then
		if IsValid(ply.BonePile) then
			ply.BonePile:Remove() -- Apparently doesn't remove it? :(
			ply:Spawn()
		end
		ply:Stun()
		return false
	else
		return true
	end
end