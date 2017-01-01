local meta = FindMetaTable("Player")

local range = 250
local steal = 25
local cooldown = 5
local immunity = 1
local mins = Vector(-5,-5,-5)
local maxs = Vector(5,5,5)

function meta:StealHealth(ply, amount)
	if not ply:IsRunner() then return end -- Can only steal from other runners
	
	local ct = CurTime()
	if self.NextHealthSteal and self.NextHealthSteal > ct then return end
	if ply.HealthStealImmunity > ct then return end
	
	amount = amount or steal
	local h1 = self:Health()
	local h2 = ply:Health()
	
	if h1 == h2 then return end
	
	local from, to
	if h1 > h2 then
		amount = math.Clamp(amount, 0, h1 - 1)
		from = self
		to = ply
	else
		amount = math.Clamp(amount, 0, h2 - 1)
		to = self
		from = ply
	end
	
	from:SetHealth(math.Clamp(from:Health() - amount, 1, 100))
	to:SetHealth(math.Clamp(to:Health() + amount, 1, 100))
	
	self.NextHealthSteal = ct + cooldown -- Cooldown (on the guy who initialized)
	self.HealthStealImmunity = ct + immunity -- Can't be re-stolen from for this time
	self.HealthStealTarget = nil
	-- TODO: Fancy effect
	
	local ef = EffectData()
	ef:SetOrigin(from:GetPos())
	ef:SetEntity(to)
	util.Effect("sacrifun_healthsteal", ef, true, true)
end

function meta:AttemptHealthSteal()
	if not self:IsRunner() then return end
	if self.NextHealthSteal and self.NextHealthSteal > CurTime() then return end
	
	self:LagCompensation(true)
	
	local tr = util.TraceHull({
		start = self:GetShootPos(),
		endpos = self:GetShootPos() + self:GetAimVector()*range,
		filter = self,
		mins = mins,
		maxs = maxs,
		mask = MASK_SHOT
	})
	
	self:LagCompensation(false)
	
	debugoverlay.Cross(tr.HitPos, 5)
	
	if IsValid(tr.Entity) and tr.Entity:IsPlayer() then
		if true then --if tr.Entity == self.HealthStealTarget then
			--print("Hit", tr.Entity)
			self:StealHealth(tr.Entity)
			self.HealthStealTarget = nil
		else
			self.HealthStealTarget = tr.Entity
		end
	end
end