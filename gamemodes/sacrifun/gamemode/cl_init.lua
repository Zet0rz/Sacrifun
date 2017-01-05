include("shared.lua")
include("playerclass.lua")
include("player.lua")
include("sensing.lua")
include("player_clones.lua")
--include("actions.lua")
include("round.lua")
include("blinding.lua")
include("blindphase_props.lua")

local color_health = Color(255,125,125)
local color_clones = Color(100,220,100)
local color_sense = Color(100,180,220)

local mat_bar = Material("sacrifun/bar.png", "smooth")

local icon_runner = Material("sacrifun/icon_runner.png", "smooth")
local icon_skeleton = Material("sacrifun/icon_skeleton.png", "smooth")
local icon_injured = Material("sacrifun/icon_injured.png", "smooth")
local icon_killer = Material("sacrifun/icon_killer.png", "smooth")
local icon_sense = Material("sacrifun/icon_sense.png", "smooth")
local icon_clones = Material("sacrifun/icon_clones.png", "smooth")

local ab_push = Material("sacrifun/ability_push.png", "smooth")
local ab_tackle = Material("sacrifun/ability_tackle.png", "smooth")
local ab_grab = Material("sacrifun/ability_grab.png", "smooth")
local ab_pull = Material("sacrifun/ability_quickgrab.png", "smooth")
local ab_heal = Material("sacrifun/ability_heal.png", "smooth")
local ab_blind = Material("sacrifun/ability_blind.png", "smooth")

local m1 = Material("sacrifun/mouse_lmb.png", "smooth")
local m2 = Material("sacrifun/mouse_rmb.png", "smooth")
local m3 = Material("sacrifun/mouse_mmb.png", "smooth")

local ks = Material("sacrifun/key_shift.png", "smooth")
local ka = Material("sacrifun/key_alt.png", "smooth")

local huds = {
	[1] = function()
		local ply = LocalPlayer()
		local health = ply:Health()
		local adrenaline = ply:GetAdrenaline()/100
		local sense = ply.SenseCooldown or 0
		local sh = ScrH()
		local sw = ScrW()
		
		local numclones = ply:GetCloneNumber()
		
		local healthpct = health/100
		
		surface.SetDrawColor(50,50,50,150)
		surface.SetMaterial(mat_bar)
		surface.DrawTexturedRectUV(165, sh - 85, 420, 20, 0, 0, 1, 1)
		surface.DrawTexturedRectUV(315, sh - 115, 250, 15, 0, 1, 1, 0)
		
		surface.SetDrawColor(255,125,125)
		surface.DrawTexturedRectUV(161, sh - 83, 420*healthpct, 16, 1-healthpct, 0.1, 1, 0.9)
		surface.SetDrawColor(125,220,125)
		surface.DrawTexturedRectUV(311, sh - 113, 250*adrenaline, 11, 1-adrenaline, 0.9, 1, 0.1)
		
		
		draw.RoundedBox(16, 50, sh - 170, 120, 120, color_health)
		draw.RoundedBox(16, 260, sh - 150, 60, 60, color_clones)
		draw.RoundedBox(16, 180, sh - 160, 70, 70, color_sense)
		
		surface.SetDrawColor(255,255,255)
		
		if ply:IsInjured() then
			surface.SetMaterial(icon_injured)
		else
			surface.SetMaterial(icon_runner)
		end
		surface.DrawTexturedRect(50, sh - 170, 120, 120)
		
		surface.SetMaterial(icon_clones)
		surface.DrawTexturedRect(260, sh - 150, 60, 60)
		
		surface.SetMaterial(icon_sense)
		surface.DrawTexturedRect(182, sh - 158, 66, 66)
		surface.SetDrawColor(255,0,0,200)
		surface.DrawTexturedRectUV(182, sh - 92 - 66*sense, 66, 66*sense, 0, 1-sense, 1, 1)
		
		draw.SimpleTextOutlined("x"..numclones, "DermaLarge", 310, sh-100, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)

		--draw.SimpleTextOutlined("M3", "TargetID", 325, sh-125, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 2, color_black)
		--draw.SimpleTextOutlined("⇑+ALT", "TargetID", 215, sh-95, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
		
		draw.RoundedBox(16, sw - 170, sh - 170, 120, 120, color_clones)
		draw.RoundedBox(16, sw - 280, sh - 140, 90, 90, color_clones)
		draw.RoundedBox(16, sw - 390, sh - 140, 90, 90, color_clones)
		draw.RoundedBox(16, sw - 515, sh - 140, 80, 80, color_sense)
		
		surface.SetDrawColor(255,255,255)
		
		local shift, alt = ply:KeyDown(IN_SPEED), ply:KeyDown(IN_WALK)
		local mat1, mat2, salpha, aalpha
		if shift then
			mat1 = ab_tackle
			mat2 = ab_pull
			salpha = 255
			if alt then
				aalpha = 255
			else
				aalpha = 100
			end			
		elseif alt then
			mat1 = ab_blind
			mat2 = ab_heal
			salpha = 100
			aalpha = 255
		else
			mat1 = ab_push
			mat2 = ab_grab
			salpha = 100
			aalpha = 100
		end
		surface.SetMaterial(mat1)
		surface.DrawTexturedRect(sw - 388, sh - 138, 86, 86)
		surface.SetMaterial(mat2)
		surface.DrawTexturedRect(sw - 278, sh - 138, 86, 86)
		
		if not GetNextAvailableProp() then
			surface.SetMaterial(icon_clones)
			surface.DrawTexturedRect(sw - 170, sh - 170, 120, 120)
		end
		
		surface.SetMaterial(m1)
		surface.DrawTexturedRect(sw - 330, sh - 80, 50, 50)
		surface.SetMaterial(m2)
		surface.DrawTexturedRect(sw - 220, sh - 80, 50, 50)
		surface.SetMaterial(m3)
		surface.DrawTexturedRect(sw - 80, sh - 80, 50, 50)
		
		if ply.GetIsSensing and ply:GetIsSensing() then
			surface.SetDrawColor(255,125,125)
		else
			surface.SetDrawColor(255,255,255)
		end
		surface.SetMaterial(icon_sense)
		surface.DrawTexturedRect(sw - 515, sh - 140, 80, 80)
		
		surface.SetMaterial(ks)
		surface.SetDrawColor(255,255,255,salpha)
		surface.DrawTexturedRect(sw - 550, sh - 80, 90, 50)
		surface.SetMaterial(ka)
		surface.SetDrawColor(255,255,255,aalpha)
		surface.DrawTexturedRect(sw - 470, sh - 80, 75, 50)
	end,
	[2] = function()
		local ply = LocalPlayer()
		local health = ply:Health()
		local adrenaline = ply:GetAdrenaline()/100
		local sense = ply.SenseCooldown or 0
		local sh = ScrH()
		local sw = ScrW()
		
		local numrunners = team.NumPlayers(1)
		
		local healthpct = health/100
		
		surface.SetDrawColor(50,50,50,150)
		surface.SetMaterial(mat_bar)
		surface.DrawTexturedRectUV(165, sh - 95, 350, 20, 0, 0, 1, 1)
		
		surface.SetDrawColor(255,125,125)
		surface.DrawTexturedRectUV(161, sh - 93, 350*healthpct, 16, 1-healthpct, 0.1, 1, 0.9)		
		
		draw.RoundedBox(16, 50, sh - 170, 120, 120, color_health)
		draw.RoundedBox(16, 180, sh - 160, 60, 60, color_sense)
		
		surface.SetDrawColor(255,255,255)
		
		surface.SetMaterial(icon_killer)
		surface.DrawTexturedRect(50, sh - 170, 120, 120)
		
		surface.SetMaterial(icon_runner)
		surface.DrawTexturedRect(180, sh - 160, 60, 60)
		
		draw.SimpleTextOutlined("x"..numrunners, "DermaLarge", 230, sh-110, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
	end,
	[3] = function()
		local ply = LocalPlayer()
		local health = ply:Health()
		local sh = ScrH()
		local sw = ScrW()
		
		local healthpct = health/100
		
		surface.SetDrawColor(50,50,50,150)
		surface.SetMaterial(mat_bar)
		surface.DrawTexturedRectUV(165, sh - 85, 420, 20, 0, 0, 1, 1)
		
		surface.SetDrawColor(255,125,125)
		surface.DrawTexturedRectUV(161, sh - 83, 420*healthpct, 16, 1-healthpct, 0.1, 1, 0.9)
		
		
		draw.RoundedBox(16, 50, sh - 170, 120, 120, color_health)
		
		surface.SetDrawColor(255,255,255)
		
		surface.SetMaterial(icon_skeleton)
		surface.DrawTexturedRect(50, sh - 170, 120, 120)
		
		draw.RoundedBox(16, sw - 140, sh - 140, 90, 90, color_clones)
		draw.RoundedBox(16, sw - 250, sh - 140, 90, 90, color_clones)
		
		surface.SetDrawColor(255,255,255)
		
		local shift = ply:KeyDown(IN_SPEED)
		local mat1, mat2, salpha
		if shift then
			mat1 = ab_tackle
			mat2 = ab_pull
			salpha = 255
		else
			mat1 = ab_push
			mat2 = ab_grab
			salpha = 100
		end
		surface.SetMaterial(mat1)
		surface.DrawTexturedRect(sw - 248, sh - 138, 86, 86)
		surface.SetMaterial(mat2)
		surface.DrawTexturedRect(sw - 138, sh - 138, 86, 86)
		
		surface.SetMaterial(m1)
		surface.DrawTexturedRect(sw - 190, sh - 80, 50, 50)
		surface.SetMaterial(m2)
		surface.DrawTexturedRect(sw - 80, sh - 80, 50, 50)
		
		surface.SetMaterial(ks)
		surface.SetDrawColor(255,255,255,salpha)
		surface.DrawTexturedRect(sw - 300, sh - 80, 90, 50)
	end,
}

local hudteam = IsValid(LocalPlayer()) and LocalPlayer():Team() or 1
hook.Add("HUDPaint", "sacrifun_hud", function()
	if IsValid(LocalPlayer()) then hudteam = LocalPlayer():Team() end
	huds[hudteam]()
end)
function sfun_SetTeamHUD(num)
	hudteam = num
end

local hide = {
	CHudHealth = true,
	CHudBattery = true,
	CHudWeaponSelection = true,
}
hook.Add("HUDShouldDraw", "HideHUD", function( id )
	if (hide[id]) then return false end
end)

local add = Vector(0,0,10)
hook.Add("CalcView", "sacrifun_View", function(ply, pos, angles, fov)
	if ply:IsKiller() then
		local view = {}
		view.origin = pos + add
		view.angles = angles
		view.fov = fov
		view.drawviewer = false
		
		return view
	end
end)
hook.Add("CalcViewModelView", "sacrifun_View", function(wep, vm, opos, oang, pos, ang)
	if LocalPlayer():IsKiller() then
		return pos + add, ang
	end
end)

-- Scale killer sizes
local scale = Matrix()
scale:Scale(Vector(1.2,1.2,1.2))
hook.Add("PrePlayerDraw", "sacrifun_playerscale", function(ply)
	if ply:IsKiller() and not ply.IsKillerScaled then
		ply:EnableMatrix("RenderMultiply", scale)
		ply.IsKillerScaled = true
	elseif ply.IsKillerScaled and not ply:IsKiller() then
		ply:DisableMatrix("RenderMultiply")
		ply.IsKillerScaled = false
	end
end)

-- Target ID Health bars
local hudavatar = vgui.Create("AvatarImage")
hudavatar:SetPaintedManually(true)
hudavatar:SetSize(64,64)

local targetply
function GM:HUDDrawTargetID()
	local tr = LocalPlayer():GetEyeTrace()
	if not tr.Hit then targetply = nil return end
	if not tr.HitNonWorld then targetply = nil return end
	
	local ent = tr.Entity
	if not ent:IsPlayer() then targetply = nil return end
	
	if not IsValid(targetply) then
		targetply = ent
		targettime = CurTime() + 0.15 -- The delay for the text to show up
	end
	
	local x = ScrW()/2 - 100
	local y = ScrH()/2 + 100
	
	if CurTime() >= targettime then
		if hudavatar.Player != targetply then
			hudavatar:SetPlayer(targetply, 64)
			hudavatar.Player = targetply
			hudavatar:SetPos(x - 60,y - 35)
		end
		
		local healthpct = targetply:Health()/100
		surface.SetDrawColor(50,50,50,150)
		surface.SetMaterial(mat_bar)
		surface.DrawTexturedRectUV(x, y, 300, 20, 0, 0, 1, 1)
		
		surface.SetDrawColor(255,125,125)
		surface.DrawTexturedRectUV(x - 4, y + 2, 300*healthpct, 16, 1-healthpct, 0.1, 1, 0.9)
		
		draw.SimpleTextOutlined(targetply:Nick(), "DermaLarge", x + 10, y - 15, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 2, color_black)
		
		hudavatar:PaintManual()
	end
end