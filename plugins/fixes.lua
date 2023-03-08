
local PLUGIN = PLUGIN
PLUGIN.name = "Fixes"
PLUGIN.author = "kuromeew"
PLUGIN.description = "Fixes helix"

PLUGIN.kitStart = {
	[ "cid" ] = 1,
	[ "water" ] = 2,
}
function PLUGIN:OnCharacterCreated(ply, char)
	local inv = char:GetInventory()

	for k, v in next, PLUGIN.kitStart do
		inv:Add(k, v)
	end

	char:SetMoney(12000)
end

ix.log.AddType("entityRemoved", function(client, ...)
	local arg = {...}
	return string.format("%s has removed the '%s' enitity.", client:Name(), arg[1])
end)

ix.log.AddType("moneyPickedUp", function(client)
	return string.format("%s has picked up money.", client:Name())
end)

function PLUGIN:OnPickupMoney(ply, ent)
	ix.log.Add(ply, "moneyPickedUp")
end

function PLUGIN:PlayerInitialSpawn(ply)
	ply:SetCanZoom(false)
end

function PLUGIN:OnItemSpawned(ent)
	ent.health = 250
end

PLUGIN.duplicatorBlackList = {
	[ "ix_container" ] = true,
	[ "ix_money" ] = true
}
hook.Add("CanTool", "FixesHook", function(ply, tr, tool)
	local ent = tr.Entity

	if IsValid(ent) then
		local name, steamID, class = ply:Name(), ply:SteamID(), ent:GetClass()
		if tool == "remover" then
			if PLUGIN.removerBlackList[ class ] ~= nil then
				if not ply:IsSuperAdmin() and ent.TempOwnerSteamID ~= ply:SteamID64() then
					ix.log.AddRaw(string.format("%s [%s] пытался удалить запрещенный энтити %s", name, steamID, class))
			
					ply:Notify("У вас нет прав/Этот энтити не принадлежит вам")

					return false
				else
					ix.log.Add(ply, "entityRemoved", tostring(ent))
				end
			end
		elseif tool == "advdupe2" then
			if PLUGIN.duplicatorBlackList[ class ] ~= nil then
				ix.log.AddRaw(string.format("%s [%s] пытался дублировать запрещенный энтити %s", name, steamID, class))
				ply:Notify("Этот энтити нельзя дублировать")
				return false
			end
		end
	end
end)

hook.Add("PlayerSpray", "FixesHook2", function(ply)
	return ply:IsSuperAdmin() == false
end)

hook.Add("PlayerThrowPunch", "OnepunchMan", function(ply, trace)
	if ply:IsSuperAdmin() then
		local ent = trace.Entity
		if IsValid(ent) then
			if ent:IsPlayer() then
				ply:ConsumeStamina(100)
				ix.chat.Send(ent, "used", 'Контрприем "Лом"')
				ent:EmitSound("weapons/crowbar/crowbar_impact" .. math.random(1, 2) .. ".wav", 70)
				ply:SetRagdolled(true, 10)
			end
		end
	end
end)

function PLUGIN:OnCharacterFallover(client, entity, bFallenOver)
	if IsValid(entity) then
	    entity:SetCollisionGroup(COLLISION_GROUP_NONE)
		entity:SetCustomCollisionCheck(false)
	end
end

function PLUGIN:InitializedPlugins()
    ix.command.list["charfallover"].OnRun = function(this, client, time)
        if client:Alive() == false or client:GetMoveType() == MOVETYPE_NOCLIP then
			return "@notNow"
		end

		if time ~= nil and time > 0 then
			time = math.Clamp(time, 1, 60)
		end

		if IsValid(client.ixRagdoll) == false then
			if client:GetNetVar("tying") or client:IsRestricted() then
				client:NotifyLocalized("notNow")
                return
			end

            local actEnterAngle = client:GetNetVar("actEnterAngle")

            if actEnterAngle ~= nil or (client._ixNextCharFallOver and client._ixNextCharFallOver > CurTime()) then
                client:NotifyLocalized("notNow")
                return
            end

            local client_velocity = client:GetVelocity()
            client_velocity = client_velocity:Length()

            local client_speed = math.Round(client_velocity);
            if client_speed and client_speed <= 15 then
			    client:SetRagdolled(true, time)
				client._ixNextCharFallOver = CurTime() + 30

				if IsValid(client.ixRagdoll) then
					client.ixRagdoll.ixActiveWeapon = nil
				end
            else
                client:NotifyLocalized("notNow")
            end
		end
    end
end

hook.Add("ScalePlayerDamage", "Dmgscale", function(ply, hitgroup, dmgInfo)
	if hitgroup == HITGROUP_HEAD then 
		dmgInfo:ScaleDamage(2)
	elseif (hitgroup == HITGROUP_LEFTLEG or hitgroup == HITGROUP_RIGHTLEG) and math.random(4) == 2 then --LEGS DAMAGE
		ply:ConsumeStamina(100)
	end
end)
