
local actions = {}

function RegisterAction(id, tbl)
	actions[id] = tbl
end

function GetActions()
	return actions
end

RegisterAction("doorslam", {
	{ang = Angle(0,180,10), time = 0.2},
	{ang = Angle(0,180,10), time = 0.1},
	{time = 0.2},
})

RegisterAction("stun", {
	{ang = Angle(90,0,0), time = 0.5},
	{ang = Angle(90,30,0), time = 0.3},
	{ang = Angle(90,-30,0), time = 0.3},
	{ang = Angle(90,0,0), time = 0.2},
	{ang = Angle(-90,0,0), time = 1},
})

local meta = FindMetaTable("Player")

function meta:ExecuteAction(id)
	if !self.ExecutingAction then
		self:InitiateAction(id)
		self.ExecutingAction = id
	end
end
	
function meta:InitiateAction(id)
	local ctime = CurTime()
	local ct = CurTime()
	local cid = 1
	
	local target = actions[id][cid]
	local prev = actions[id][cid-1]
	if !prev then prev = {} end
	
	local targettime = target.time
	
	local ang = self:EyeAngles()
	local dir = Angle(0,ang[2],0)
	local targetang = target.ang or ang-dir
	local prevang = prev.ang or ang-dir
	
	local speed = target.pos and target.pos/target.time
	
	if CLIENT then
		hook.Add("CalcView", "sacrifun_actioncam", function(ply, pos, angles, fov)
			local tdiff = math.Clamp((ct - ctime)/targettime, 0, 1)
			local lang = LerpAngle(tdiff, prevang, targetang)
			
			--print(dir+lang, "Calc", dir)
			
			if !target and tdiff == 1 then
				hook.Remove("CalcView", "sacrifun_actioncam")
				return
			end
			
			local view = {}
			view.origin = pos
			view.angles = dir + lang
			ply:SetEyeAngles(dir+lang)
			view.fov = fov
			view.drawviewer = false

			return view
		end)
	end
	
	hook.Add("SetupMove", "sacrifun_actionmove", function(ply, mv, cmd)
		ct = CurTime()
		local tdiff = math.Clamp((ct - ctime)/targettime, 0, 1.1)
		--local lang = LerpAngle(tdiff, prevang, targetang)
		
		--print(tdiff, "Move")
		
		if tdiff > 1 then
			cid = cid + 1
			--local endang = target.ang + dir
			target = actions[id][cid]
			if !target then
				--self:SetEyeAngles(endang)
				hook.Remove("SetupMove", "sacrifun_actionmove")
				--hook.Remove("CalcView", "sacrifun_actioncam")
				self.ExecutingAction = nil
				return
			end
			ctime = CurTime()
			prev = actions[id][cid-1]
			targettime = target.time
			targetang = target.ang or ang-dir
			prevang = prev.ang or Angle(0,0,0)
			
			speed = target.move and target.move/target.time
		end
		
		mv:SetMoveAngles(dir)
		
		if speed then
			cmd:ClearMovement()
			
			mv:SetForwardSpeed(speed.x)
			mv:SetSideSpeed(speed.y)
			mv:SetUpSpeed(speed.z)
			cmd:SetForwardMove(speed.x)
			cmd:SetSideMove(speed.y)
			cmd:SetUpMove(speed.z)
		end
		
		--mv:SetAngles(dir + lang)
		--ply:SetEyeAngles(dir + lang)

	end)
end