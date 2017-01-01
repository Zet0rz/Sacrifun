local meta = FindMetaTable("Player")

local loopfreq = 0.2
local freq = 0.5
local nextcheck = 0
local looptbl = {}

function meta:CollideWhenPossible()
	if IsValid(self) and IsValid(self:GetCarriedObject()) then
		local tr = util.TraceEntity({start = self:GetPos(), endpos = self:GetPos(), filter = self}, self)
		if not IsValid(tr.Entity) then
			self:SetCarriedObject(nil)
			self:CollisionRulesChanged()
			return -- Not colliding
		end
		table.insert(looptbl, self)
	end
end

hook.Add("Think", "sacrifun_antistuck", function()
	if nextcheck < CurTime() then
		for k,v in pairs(looptbl) do
			if IsValid(v) and IsValid(v:GetCarriedObject()) then
				local tr = util.TraceEntity({start = v:GetPos(), endpos = v:GetPos(), filter = v}, v)
				if not IsValid(tr.Entity) then
					v:SetCarriedObject(nil)
					v:CollisionRulesChanged()
					v.NextSuffocationDamage = nil
					table.remove(looptbl, k)
				else
					if not v.NextSuffocationDamage then
						v.NextSuffocationDamage = CurTime() + 2
					end
					if v.NextSuffocationDamage < CurTime() then
						v:TakeDamage(5, v, v:GetCarriedObject())
						v.NextSuffocationDamage = CurTime() + 1
					end
				end
			else
				table.remove(looptbl, k)
			end
		end
		nextcheck = CurTime() + loopfreq
	end
end)