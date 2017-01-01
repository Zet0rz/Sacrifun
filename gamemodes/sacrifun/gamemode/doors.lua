
local cvar = CreateConVar("sfun_doors_rotate", 0, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Sets whether doors rotate freely on a hinge. If disabled, doors will open like normal, with the exception of speed modifiers")
CreateConVar("sfun_doors_oneway", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "If enabled, doors can only rotate 90 degrees in one direction. If disabled, can rotate 90 degrees in both. Only applies to freely rotating doors.")

local doors = {
	["prop_door_rotating"] = true,
	["func_door"] = true,
	["func_door_rotating"] = true,
}

hook.Add("OnEntityCreated", "sacrifun_replacedoors", function(ent)
	if SERVER and doors[ent:GetClass()] then
		timer.Simple(0, function()
			ent.OriginalDoorSpeed = ent:GetKeyValues().speed
			
			if cvar:GetBool() then
				local door = ents.Create("sacrifun_door")
				door:SetMapDoor(ent)
				door:SetPos(ent:GetPos())
				door:SetAngles(ent:GetAngles())
				door:SetModel(ent:GetModel())
				door:Spawn()
				
				ent:SetSolid(SOLID_NONE)
				ent:Fire("Open")
				ent:SetParent(door)
				ent:AddEffects(EF_BONEMERGE)
				
				door:SetNoDraw(true)
				
				ent:SetKeyValue("speed", "10000")
			end
		end)
	end
end)

hook.Add("FindUseEntity", "sacrifun_doorreset", function(ply, ent)
	if IsValid(ent) and doors[ent:GetClass()] then
		if cvar:GetBool() or (ent.SlamShutTime and ent.SlamShutTime > CurTime()) then
			return false
		else
			if ply:KeyPressed(IN_USE) then
				local wep = ply:GetActiveWeapon()
				if IsValid(wep) and not IsValid(wep.CarriedObject) then
					wep:SecondaryAttack()
					return false
				else
					ent:SetKeyValue("speed", ent.OriginalDoorSpeed or "100")
				end
			end
		end
	end
end)