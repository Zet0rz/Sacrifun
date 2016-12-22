
local props = {
	"models/props_c17/FurnitureCouch001a.mdl",
	"models/props_junk/wood_crate002a.mdl",
	"models/props_junk/wood_crate001a.mdl",
	"models/props_wasteland/kitchen_counter001c.mdl",
	"models/props_wasteland/kitchen_counter001d.mdl",
	"models/props_wasteland/kitchen_stove001a.mdl",
	"models/props_interiors/VendingMachineSoda01a.mdl",
	"models/props_interiors/BathTub01a.mdl",
	"models/props_c17/concrete_barrier001a.mdl",
	"models/props_c17/furnitureStove001a.mdl",
	"models/props_combine/breendesk.mdl",
	"models/props_interiors/Furniture_shelf01a.mdl",
	"models/props_junk/TrashDumpster01a.mdl",
	"models/props_wasteland/laundry_cart001.mdl",
	"models/props_wasteland/laundry_dryer002.mdl",
	"models/props_wasteland/medbridge_post01.mdl",
	"models/props_wasteland/controlroom_storagecloset001a.mdl",
	"models/props_combine/breenchair.mdl",
	
}

local cvar = CreateConVar("sfun_prep_props", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Sets how many props players can spawn during preparation phase.")

if SERVER then
	local meta = FindMetaTable("Player")
	
	util.AddNetworkString("sfun_playerprops_clear")
	util.AddNetworkString("sfun_playerprops_add")
	util.AddNetworkString("sfun_playerprops_remove")
	
	function meta:RestockProps()
		self:RemoveProps()
		local count = cvar:GetInt()
		if count > 0 then
			for i = 1, count do
				self:GiveProp()
			end
		end
	end
	
	function meta:RemoveProps()
		self.Props = {}
		net.Start("sfun_playerprops_clear")
		net.Send(self)
	end
	
	function meta:GiveProp(model)
		model = model or table.Random(props)
		net.Start("sfun_playerprops_add")
			net.WriteString(model)
		net.Send(self)
		
		table.insert(self.Props, model)
	end
	
	function meta:CreateProp()
		local model = self.Props[1]
		if not model then return end
		
		local start = self:GetShootPos()
		local aim = self:GetAimVector()

		local tr = util.TraceLine({
			start = start,
			endpos = start + (aim*2048),
			filter = self
		})

		-- Prevent spawning too close
		--[[if ( !tr.Hit || tr.Fraction < 0.05 ) then
			return
		end]]

		local ent = ents.Create( "prop_physics" )
		if ( !IsValid( ent ) ) then return end

		local ang = Angle(0,self:EyeAngles()[2]+180,0)

		ent:SetModel(model)
		ent:SetAngles(ang)
		ent:SetPos(tr.HitPos)
		ent:Spawn()
		ent:Activate()

		-- Attempt to move the object so it sits flush
		-- This is taken from Sandbox' spawn function

		local newpoint = tr.HitPos - (tr.HitNormal * 512)
		newpoint = ent:NearestPoint(newpoint)
		newpoint = ent:GetPos() - newpoint
		newpoint = tr.HitPos + newpoint
		
		-- Set new position
		ent:SetPos(newpoint)
		
		-- Perform a trace to see if we have space here
		local space = util.TraceEntity({start = ent:GetPos(), endpos = ent:GetPos(), filter = ent}, ent)
		if space.Hit then
			ent:Remove()
			self:ChatPrint("Not enough space to spawn here")
		else
			net.Start("sfun_playerprops_remove")
			net.Send(self)
			table.remove(self.Props, 1)
		end
	end
	
else

	local availableprops = {}
	
	local spawnicon
	local function UpdateSpawnProps(clear)
		if clear then
			if IsValid(spawnicon) then spawnicon:Remove() end
		else
			if not IsValid(spawnicon) then
				spawnicon = vgui.Create("SpawnIcon")
				spawnicon:SetSize(110,110)
				spawnicon:SetPos(ScrW() - 165, ScrH() - 165)
			end
			spawnicon:SetModel(GetNextAvailableProp())
		end
	end

	net.Receive("sfun_playerprops_clear", function()
		availableprops = {}
		UpdateSpawnProps(true)
	end)
	
	net.Receive("sfun_playerprops_add", function()
		local model = net.ReadString()
		table.insert(availableprops, model)
		UpdateSpawnProps()
	end)
	
	net.Receive("sfun_playerprops_remove", function()
		table.remove(availableprops, 1)
		UpdateSpawnProps(table.Count(availableprops) <= 0)
	end)
	
	function GetNextAvailableProp()
		return availableprops[1]
	end
	
	function GetAvailableProps()
		return availableprops
	end
end