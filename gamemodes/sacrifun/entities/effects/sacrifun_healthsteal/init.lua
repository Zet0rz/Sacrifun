local lifetime = 1 -- Time with total effect (rising particles)
local stoptime = 1 -- Time with drain effect
local particledelay = 0.05
local risedelay = 0.2
local riseparticledelay = 0.025
local add = Vector(0,0,40)

function EFFECT:Init( data )

	self.Start = data:GetOrigin() + add
	self.Player = data:GetEntity()
	self.MoveSpeed = 50
	
	self.NextParticle = CurTime()
	self.NextRiseParticle = CurTime() + risedelay
	self.KillTime = CurTime() + lifetime
	self.StopTime = CurTime() + stoptime
	
	self.Emitter = ParticleEmitter( self.Start )
	self.Particles = {}
	
	--print(self.Emitter, self.NextParticle, self, self.Player)
	
end

function EFFECT:Think()
	local ct = CurTime()
	if ct >= self.NextParticle then
		local particle = self.Emitter:Add("sprites/glow04_noz", self.Emitter:GetPos())
		if (particle) then
			particle:SetVelocity( (self.Player:GetPos() - self.Start + add)*2 )
			particle:SetColor(math.random(200,255), math.random(100,200), math.random(100,150))
			particle:SetLifeTime( 0 )
			particle:SetDieTime( 0.5 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 0 )
			particle:SetStartSize( 25 )
			particle:SetEndSize( 25 )
			particle:SetRoll( math.Rand(0, 36)*10 )
			--particle:SetRollDelta( math.Rand(-200, 200) )
			particle:SetAirResistance( 0 )
			particle:SetGravity( Vector( 0, 0, 0 ) )
			
			self.NextParticle = CurTime() + particledelay
		end
	end
	if ct >= self.NextRiseParticle then
		local particle = self.Emitter:Add("sprites/glow04_noz", self.Player:GetPos() + Vector(math.Rand(-10,10), math.Rand(-10,10), 0))
		if (particle) then
			particle:SetVelocity( Vector(0,0,100) )
			particle:SetColor(math.random(200,255), math.random(100,200), math.random(100,150))
			particle:SetLifeTime( 0 )
			particle:SetDieTime( 0.5 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 0 )
			particle:SetStartSize( 10 )
			particle:SetEndSize( 10 )
			particle:SetRoll( math.Rand(0, 36)*10 )
			--particle:SetRollDelta( math.Rand(-200, 200) )
			particle:SetAirResistance( 10 )
			particle:SetGravity( Vector( 0, 0, 0 ) )
			
			self.NextRiseParticle = CurTime() + riseparticledelay
		end
	end
	if self.KillTime < ct then
		return false
	else
		return true
	end
end

function EFFECT:Render()
	
end
