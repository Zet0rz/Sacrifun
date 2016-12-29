local meta = FindMetaTable("Player")

local range = 150
local steal = 25
local cooldown = 5
local immunity = 1
local mins = Vector(-10,-10,-10)
local maxs = Vector(10,10,10)

function meta:StealHealth(ply, amount)
	local ct = CurTime()
	if self.NextHealthSteal and self.NextHealthSteal > ct then return end
	if ply.HealthStealImmunity > ct then return end
	
	amount = amount or steal
	local h1 = self:Health()
	local h2 = ply:Health()
	
	if h1 == h2 then return end
	
	if h1 > h2 then
		amount = math.Clamp(amount, 0, h1 - 1)
		self:SetHealth(math.Clamp(h1 - amount, 1, 100))
		ply:SetHealth(math.Clamp(h2 + amount, 1, 100))
	else
		amount = math.Clamp(amount, 0, h2 - 1)
		self:SetHealth(math.Clamp(h1 + amount, 1, 100))
		ply:SetHealth(math.Clamp(h2 - amount, 1, 100))
	end
	
	self.NextHealthSteal = ct + cooldown -- Cooldown (on the guy who initialized)
	self.HealthStealImmunity = ct + immunity -- Can't be re-stolen from for this time
	-- TODO: Fancy effect
end

function meta:AttemptHealthSteal()
	if not self:IsRunner() then return end
	if self.NextHealthSteal and self.NextHealthSteal > CurTime() then return end
	
	local tr = util.TraceHull({
		start = self:GetShootPos(),
		endpos = self:GetShootPos() + self:GetAimVector()*range,
		filter = self,
		mins = mins,
		maxs = maxs,
		mask = MASK_SHOT
	})
	
	if IsValid(tr.Entity) and tr.Entity:IsPlayer() and tr.Entity == self.HealthStealTarget then
		self:StealHealth(tr.Entity)
		self.HealthStealTarget = nil
	else
		self.HealthStealTarget = tr.Entity
	end
end