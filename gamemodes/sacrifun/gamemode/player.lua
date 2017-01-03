local meta = FindMetaTable("Player")

if SERVER then
	function meta:SetRunner()
		self:SetTeam(1)
		self:StripWeapons()
		player_manager.SetPlayerClass( self, "sfun_playerclass_runner" )
		player_manager.RunClass(self, "SetModel")
		player_manager.RunClass(self, "Loadout")
		--hook.Run("sfun_UpdateTeamStatus")
		self.PlayerSetUp = true
		self.ConvertingToSkeleton = nil
	end
	
	function meta:SetKiller()
		self:SetTeam(2)
		self:StripWeapons()
		player_manager.SetPlayerClass( self, "sfun_playerclass_killer" )
		player_manager.RunClass(self, "SetModel")
		player_manager.RunClass(self, "Loadout")
		--hook.Run("sfun_UpdateTeamStatus")
		self.PlayerSetUp = true
	end
	
	function meta:SetSkeleton()
		self:SetTeam(3)
		self:StripWeapons()
		player_manager.SetPlayerClass( self, "sfun_playerclass_skeleton" )
		player_manager.RunClass(self, "SetModel")
		player_manager.RunClass(self, "Loadout")
		self:SetModel("models/player/skeleton.mdl")
		hook.Run("sfun_UpdateTeamStatus")
		self.PlayerSetUp = true
	end
	
	local sprintspeed = 450
	function meta:SprintBurst(time, collide)
		time = time or 3
		
		-- Handled in the player's move class
		if not self.SpeedModTime or self.SpeedModTime - CurTime() < time then
			self.SpeedModTime = CurTime() + time
			self:SetRunSpeed(sprintspeed)
		end
		if not collide then
			self.SprintBurstNoCollide = true
			self:SetNoCollidePlayers(true)
			self:CollisionRulesChanged()
		else
			self.SprintBurstNoCollide = nil
		end
	end
	
	local slowspeed = 100
	function meta:SlowDown(time)
		time = time or 3
		
		-- Handled in the player's move class
		if not self.SpeedModTime or self.SpeedModTime - CurTime() < time then
			self.SpeedModTime = CurTime() + time
			self:SetRunSpeed(slowspeed)
			self:SetWalkSpeed(slowspeed)
		end
	end
	
	util.AddNetworkString("sfun_PlayerSkeleton")
	util.PrecacheModel("models/player/skeleton.mdl")
	function meta:ConvertToSkeleton()
		--if self:Alive() then self:Kill() end
		
		self.ConvertingToSkeleton = true
		if IsValid(self.BonePile) then self.BonePile:Remove() end
		
		local vel = self:GetVelocity()*0.45
		
		local d = DamageInfo()
		d:SetDamage(self:Health())
		d:SetAttacker(self)
		d:SetDamageType(DMG_DISSOLVE)

		self:TakeDamageInfo(d)
		self:Shout()
		
		-- Triggers the skeleton dissolve effect clientside
		--[[timer.Simple(0.1, function()
			net.Start("sfun_PlayerSkeleton")
				net.WriteEntity(self)
				net.WriteBool(true)
			net.Broadcast()
		end)]]
		
		local bp = ents.Create("sacrifun_bonepile")
		bp:SetPos(self:GetPos())
		bp:SetAngles(self:GetAngles())
		local tr = util.TraceLine({
			start = self:GetPos(),
			endpos = self:GetPos() + vel + Vector(0,0,15),
			filter = self
		})
		bp:PreBonePosAng(tr.Hit and tr.HitPos or self:GetPos() + vel + Vector(0,0,15), self:GetAngles())
		bp:SetRebuildDelay(5)
		bp:SetBoneDropDelay(2)
		bp:Spawn()
		bp:SetPlayer(self)
		bp:BoneSetupForce(self:GetAimVector()*100)
		--self.ConvertingToSkeleton = nil
		self.BonePile = bp
	end
	
	util.AddNetworkString("sfun_PlayerStun")
	function meta:Stun(time)
		if self:IsSkeleton() then
			local bp = ents.Create("sacrifun_bonepile")
			bp:SetPos(self:GetPos())
			bp:SetAngles(self:GetAngles())
			bp:Spawn()
			bp:SetPlayer(self)
			bp:SetRebuildDelay(5)
			self.BonePile = bp
			self:Kill()
		elseif self:IsRunner() then -- Killers can't be stunned
			local ct = CurTime()
			time = time or 0.75
			-- Handled in the player's move class
			if not self.StunTime or self.StunTime - ct < time then
				self.StunTime = ct + time
				self.StunImmunity = self.StunTime + 3
			end
			
			net.Start("sfun_PlayerStun")
				net.WriteFloat(time)
			net.Send(self)
			
			local wep = self:GetActiveWeapon()
			if IsValid(wep) and wep.Stun then
				wep:Stun(time)
			end
		end
	end
	
	function meta:GetResponsibleRunner()
		local mindist = math.huge
		local ply
		for k,v in pairs(team.GetPlayers(1)) do
			if v != self then
				local dist = v:GetPos():DistToSqr(self:GetPos())
				if dist < mindist then
					mindist = dist
					ply = v
				end
			end
		end
		
		return ply
	end
	
	function meta:AutoAssignTeam()
		if team.NumPlayers(2) < 1 then -- No killers
			RoundRestart()
		elseif IsInBlindPhase() then
			self:SetRunner()
		else
			self:SetSkeleton()
		end
	end
	
	util.AddNetworkString("sfun_PlayerAnims")
	function meta:SendAnimationEvent(data)
		net.Start("sfun_PlayerAnims")
			net.WriteUInt(data, 4)
			net.WriteEntity(self)
		net.Broadcast()
	end
	
else

	--models/skeleton/skeleton_whole.mdl
	--models/skeleton/skeleton_whole_noskins.mdl
	--models/player/skeleton.mdl

	net.Receive("sfun_PlayerSkeleton", function()
		local ply = net.ReadEntity()
		local create = net.ReadBool()
		
		if IsValid(ply.SkeletonRag) then ply.SkeletonRag:Remove() end
		
		if create then
			local rag = ply:GetRagdollEntity()
			
			local skel = ClientsideRagdoll("models/player/skeleton.mdl")
			skel:SetPos(rag:GetPos())
			skel:SetAngles(rag:GetAngles())
			--skel:SetModelScale(0.8)
			--skel:SetNoDraw( false )
			--skel:DrawShadow( true )
			
			local phys = skel:GetPhysicsObject()
			if IsValid(phys) then
				phys:SetPos(rag:GetPos())
				phys:EnableMotion(false)
			end
			
			skel:SetParent(rag)
			skel:AddEffects(EF_BONEMERGE)
			ply.SkeletonRag = skel
			
			--[[local bone = 20
			local physc = 14
			
			for i = 0, skel:GetBoneCount() do
				print(i, skel:GetBoneName(i))
			end
			
			local col = Color(255,0,0)
			hook.Add("PostDrawOpaqueRenderables", skel, function()
				local pos, ang = skel:GetBonePosition(bone)
				render.SetMaterial(Material("color"))
				render.DrawSphere(pos, 10, 10, 10, col)
				render.DrawLine(pos, pos+ang:Forward()*20, col)
				
				local phys2 = skel:GetPhysicsObjectNum(physc)
				local pos = phys2:GetPos()
				local ang = phys2:GetAngles()
				render.DrawSphere(pos, 10, 10, 10, col)
				render.DrawLine(pos, pos+ang:Forward()*20, col)
			end)]]
			
			-- This lists all bones which are tied to each physics object
			-- We get the position of these bones and apply them to the physics object with that key
			local bones = {3, 9, 14, 15, 10, 11, 16, 18, 19, 6, 22, 23, 24, 20}
			bones[0] = 0
			
			timer.Simple(1.8, function()
				if not IsValid(skel) then return end
				local tbl = {}
				for k,v in pairs(bones) do
					local pos, ang = skel:GetBonePosition(v)
					tbl[k] = {pos = pos, ang = ang}
				end
			
				skel:SetParent(nil)
				skel:RemoveEffects(EF_BONEMERGE)
				skel:SetupBones()
				skel:SetNoDraw( false )
				
				if IsValid(phys) then
					phys:EnableMotion(true)
					phys:SetPos(tbl[0].pos)
				end
				
				for k,v in pairs(tbl) do
					local phys = skel:GetPhysicsObjectNum(k)
					phys:SetPos(v.pos)
					phys:SetAngles(v.ang)
					phys:EnableMotion(true)
				end
			end)
			
			timer.Simple(2, function()
				if not IsValid(skel) then return end
				skel:Remove()
			end)
		end
	end)

	
	net.Receive("sfun_PlayerStun", function()
		local time = net.ReadFloat()
		local ply = LocalPlayer()
		
		local ctime = CurTime()
		ply.StunTime = ctime + time
		
		local dir = Angle(0,EyeAngles()[2],0)
		
		local ang1, ang2 = Angle(0,0,0), Angle(-45,0,20)
		local ttime = 0.1
		
		local r = 20
		local fade = -10
		local back = false
		
		hook.Add("CalcView", "sacrifun_actioncam", function(ply, pos, angles, fov)
			local ct = CurTime()
			local diff = ct - ctime
			local tdiff = math.Clamp(diff/ttime, 0, 1)
			local lang
			
			if tdiff < 1 then
				lang = LerpAngle(tdiff, ang1, ang2)
			else
				if back then
					hook.Remove("CalcView", "sacrifun_actioncam")
					return
				end
				
				lang = Angle(-45,0,r)
				r = r + fade*FrameTime()
				if math.abs(r) >= 20 then fade = fade*-1 end
				
				if diff > time then
					ctime = ct
					ang1 = lang
					ang2 = Angle(0,0,0)
					back = true
				end
			end
			
			local view = {}
			view.origin = pos
			view.angles = dir + lang
			ply:SetEyeAngles(dir+lang)
			view.fov = fov
			view.drawviewer = false

			return view
		end)
	end)
	
	net.Receive("sfun_PlayerAnims", function()
		local anim = net.ReadUInt(4)
		local ply = net.ReadEntity()
		
		if IsValid(ply) then
			ply:DoAnimationEvent(anim)
		end
	end)
end

function meta:IsRunner()
	return self:Team() == 1
end

function meta:IsInjured()
	return self:IsRunner() and self:Health() <= 55
end

function meta:IsKiller()
	return self:Team() == 2
end

function meta:IsSkeleton()
	return self:Team() == 3
end

-- Sound thingies

-- Used to determine sound, based on player model
function meta:IsFemale()
	local fe = (string.find(self:GetModel(), "female"))
	return fe ~= nil
end

function meta:Moan()
	if self:IsFemale() then
		self:EmitSound("vo/npc/female01/moan0"..math.random(1,5)..".wav", 75, math.random(95,105))
	else
		self:EmitSound("vo/npc/male01/moan0"..math.random(1,5)..".wav", 40, math.random(95,105))
	end
end

function meta:Scream(loud) -- True = loud screams, false = low screams, nil = all - Doesn't affect females (no loud sounds)
	local fe = self:IsFemale() and "fe" or ""
	local start = loud and 7 or 1
	local notloud = loud == false and 6 or 9
	self:EmitSound("vo/npc/"..fe.."male01/pain0"..math.random(start,notloud)..".wav", 75, math.random(95,105))
end

function meta:Cheer()
	if self:IsFemale() then
		self:EmitSound("vo/coast/odessa/female01/nlo_cheer0"..math.random(1,3)..".wav", 100, math.random(95,105))
	else
		self:EmitSound("vo/coast/odessa/male01/nlo_cheer0"..math.random(1,4)..".wav", 100, math.random(95,105))
	end
end

function meta:Shout()
	local fe = self:IsFemale() and "fe" or ""
	if math.random(0,1) == 0 then
		self:EmitSound("vo/coast/odessa/"..fe.."male01/nlo_cubdeath0"..math.random(1,2)..".wav", 75, 100)
	else
		self:EmitSound("vo/npc/"..fe.."male01/no0"..math.random(1,2)..".wav", 75, 100)
	end
end

local taunts = {
	{ -- Male
		"answer01",
		"answer02",
		"answer03",
		"answer04",
		"answer09",
		"answer10",
		"answer11",
		"answer14",
		"answer16",
		"answer17",
		"answer20",
		"answer21",
		"answer23",
		"answer25",
		"answer28",
		"answer31",
		"answer35",
		"answer36",
		"answer40",
		"evenodds",
		"gordead_ans02",
		"gordead_ans07",
		"gordead_ans09",
		"gordead_ans10",
		"gordead_ans16",
		"gordead_ans18",
		"gordead_ans20",
		"gordead_ques11",
		"gordead_ques17",
		"hi01",
		"hi02",
		"holddownspot01",
		"holddownspot02",
		"imstickinghere01",
		"likethat",
		"nice",
		"ohno",
		"oneforme",
		"outofyourway02",
		"pardonme01",
		"pardonme02",
		"question02",
		"question04",
		"question05",
		"question06",
		"question11",
		"question12",
		"question13",
		"question14",
		"question16",
		"question17",
		"question18",
		"question21",
		"question23",
		"question25",
		"question29",
		"question30",
		"sorry01",
		"sorry02",
		"sorry03",
		"uhoh",
		"vanswer01",
		"vanswer02",
		"vanswer03",
		"vanswer04",
		"vanswer05",
		"vanswer07",
		"vanswer08",
		"vanswer09",
		"vanswer10",
		"vquestion01",
		"vquestion03",
		"whoops01",
	},
	{ -- Female
		"answer01",
		"answer02",
		"answer03",
		"answer04",
		"answer09",
		"answer10",
		"answer11",
		"answer14",
		"answer16",
		"answer17",
		"answer20",
		"answer21",
		"answer23",
		"answer25",
		"answer28",
		"answer31",
		"answer35",
		"answer36",
		"answer40",
		"gordead_ans02",
		"gordead_ans07",
		"gordead_ans09",
		"gordead_ans10",
		"gordead_ans16",
		"gordead_ans18",
		"gordead_ans20",
		"gordead_ques11",
		"gordead_ques17",
		"hi01",
		"hi02",
		"holddownspot01",
		"holddownspot02",
		"imstickinghere01",
		"likethat",
		"nice01",
		"nice02",
		"ohno",
		"outofyourway02",
		"pardonme01",
		"pardonme02",
		"question02",
		"question04",
		"question05",
		"question06",
		"question11",
		"question12",
		"question13",
		"question14",
		"question16",
		"question17",
		"question18",
		"question21",
		"question23",
		"question25",
		"question29",
		"question30",
		"sorry01",
		"sorry02",
		"sorry03",
		"vanswer01",
		"vanswer03",
		"vanswer04",
		"vanswer05",
		"vanswer07",
		"vanswer08",
		"vanswer09",
		"vanswer10",
		"vquestion01",
		"vquestion03",
		"whoops01",
	},
}

function meta:Taunt(event)
	local fe = self:IsFemale()
	local index = fe and 2 or 1
	fe = fe and "fe" or ""	
	local sound = "vo/npc/"..fe.."male01/"..table.Random(taunts[index])..".wav"
	
	self:EmitSound(sound, 75, 100)
	return SoundDuration(sound)
end