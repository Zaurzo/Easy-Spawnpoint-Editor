AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')

include('shared.lua')

util.AddNetworkString('speditor_physics_pickup')

---Sets whether or not a spawnpoint should be unsuitable for selection.
---@param point Entity The spawnpoint to change unsuitable status of.
---@param value boolean The unsuitable status.
function SpawnpointEditor:SetUnsuitable(point, value)
    if not spawnpoint.IsSpawnpoint(point) then return end

    point._spawnpoint_editor_unsuitable = value and true or false

    spawnpoint.SetUnsuitable(point, value)
end

---Returns true if the provided spawnpoint is unsuitable for selection.
---@param point Entity The spawnpoint to check.
---@return boolean
function SpawnpointEditor:IsUnsuitable(point)
    if spawnpoint.IsSpawnpoint(point) then
        return point._spawnpoint_editor_unsuitable or false
    end

    return false
end

-- Hooks

local function send_pickup_entity(ent, ply)
    net.Start('speditor_physics_pickup')
    net.WriteEntity(ent)
    net.Send(ply)
end

hook.Add('OnPlayerPhysicsPickup', 'SpawnpointEditor', function(ply, ent)
    send_pickup_entity(ent, ply)
end)

hook.Add('OnPlayerPhysicsDrop', 'SpawnpointEditor', function(ply)
    send_pickup_entity(NULL, ply)
end)

-- Clear unsuitable spawnpoints from internal gamemode spawnpoint list
--  I detour this because the default selector has an unfortunate behavior:
--  if all candidates fail/are unsuitable, it will just return the last candidate tried.

local GM = gmod.GetGamemode()
GM._PlayerSelectSpawn = GM._PlayerSelectSpawn or GM.PlayerSelectSpawn

function GM:PlayerSelectSpawn(...)
    if self.SpawnPoints then -- Unsuitable spawnpoints have already been cleared out
        return self:_PlayerSelectSpawn(...)
    end

    local selected_point = self:_PlayerSelectSpawn(...)
    local spawn_points = self.SpawnPoints

    if not spawn_points then
        return selected_point
    end

    for i = #spawn_points, 1, -1 do
        local point = spawn_points[i]

        if SpawnpointEditor:IsUnsuitable(point) then
            table.remove(spawn_points, i)
        end
    end

    return self:_PlayerSelectSpawn(...)
end