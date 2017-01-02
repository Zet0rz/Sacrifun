GM.Name = "Sacrifun"
GM.Author = "Zet0r"
GM.Email = "N/A"
GM.Website = "https://youtube.com/Zet0r"

team.SetUp(1, "Runners", Color(100,125,255), true)
team.SetUp(2, "Killer", Color(255,75,75), true)
team.SetUp(3, "Skeletons", Color(255,150,150), true)

function GM:PlayerSwitchFlashlight(ply, SwitchOn)
     return true
end

local soundthres = 40
function GM:EntityTakeDamage(ply, dmginfo)
	if not ply:IsPlayer() then return end
	local pteam = ply:Team()
	if pteam == 2 then return true end -- Only runner damage!
	
	local attacker = dmginfo:GetAttacker()
	
	if dmginfo:GetDamageType() == DMG_CRUSH then dmginfo:ScaleDamage(0.01) end
	
	local dmg = dmginfo:GetDamage()
	if pteam == 1 then
		if IsValid(ply.Clone) and not ply.CLONEDMG then
			ply:EndClone(nil, true)
			return true
		elseif dmg >= ply:Health() and not ply.ConvertingToSkeleton then 
			ply:ConvertToSkeleton()
			if IsValid(attacker) and attacker:IsPlayer() then
				attacker:AddFrags(1)
			end
		elseif dmg > soundthres then
			ply.NextMoanSound = CurTime() + math.Rand(10,15)
			ply:Scream()
		end
		
		if ply.StunTime and ply.StunTime > CurTime() then
			ply:Stun(0) -- Resets clientsided
			ply.StunTime = 0 -- Resets serversided
		end
		
		local wep = ply:GetActiveWeapon()
		if IsValid(wep) and wep.Healing then
			wep:EndHeal()
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
	
	if (e1.GetNoCollidePlayers and e1:GetNoCollidePlayers()) or (e2.GetNoCollidePlayers and e2:GetNoCollidePlayers()) then
		return false
	end
	
	return true
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
	return GetConVar("sv_cheats"):GetBool()
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

local anims = {
	[1] = {ACT_HL2MP_RUN_FIST, true}, -- Push
	[2] = {ACT_HL2MP_RUN_PANICKED, true}, -- Tackle
	[3] = {ACT_GMOD_GESTURE_ITEM_DROP, true}, -- Drop
	[4] = {ACT_GMOD_GESTURE_RANGE_ZOMBIE_SPECIAL, true}, -- Quickgrab
}
hook.Add("DoAnimationEvent", "sacrifun_customanims", function(ply, event, data)
	if event == PLAYERANIMEVENT_CUSTOM_GESTURE then
		if data == 0 then
			ply:AnimResetGestureSlot(GESTURE_SLOT_ATTACK_AND_RELOAD)
		elseif anims[data] then
			local tbl = anims[data]
			local act = tbl[1]
			local kill = tbl[2]
			ply:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, act, kill)
			
			return ACT_INVALID
		end
	end
end)

-- 407	zombie_run_upperbody_layer
--[[local replacements = {
	[ACT_MP_WALK] = ACT_HL2MP_RUN_SCARED,
	[ACT_MP_RUN] = ACT_HL2MP_RUN_SCARED,
}
local function InjuredPlayerAnims(ply, act)
	if ply:IsInjured() and replacements[act] then
	
		--ply.CalcIdeal = replacements[ply.CalcIdeal]
		
		--return replacements[act]
	end
end
hook.Add("TranslateActivity", "sacrifun_injuredanim", InjuredPlayerAnims)]]

--[[local function InjuredPlayerAnims2(ply, act)
	if CLIENT then return end
	if ply:IsInjured() and not ply.InjAnim then
		ply.InjAnim = ply:AddLayeredSequence(256, 1, false)
		ply:SetLayerPlaybackRate(ply.InjAnim, 1)
		ply:SetLayerCycle(ply.InjAnim, 0.5)
		print("Here", ply.InjAnim, ply:IsValidLayer(ply.InjAnim), ply:GetLayerWeight(ply.InjAnim))
	elseif not ply:IsInjured() and ply.InjAnim then
		ply:RemoveAllGestures()
		ply.InjAnim = nil
		print("Removed")
	end
end]]
local function InjuredPlayerAnims2(ply, act)
	if ply:IsInjured() then
		ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_CUSTOM, ply:LookupSequence("gesture_bow_base_layer"), 0.5, false)
		if not ply.InjAnim then ply.InjAnim = true end
	elseif not ply:IsInjured() and ply.InjAnim then
		ply:AnimResetGestureSlot(GESTURE_SLOT_VCD)
		ply:AnimResetGestureSlot(GESTURE_SLOT_CUSTOM)
		ply.InjAnim = nil
	end
end
hook.Add("CalcMainActivity", "sacrifun_injuredanim", InjuredPlayerAnims2)