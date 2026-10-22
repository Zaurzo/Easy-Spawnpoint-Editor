util.AddNetworkString('easy_spawnpoint_editor')

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

---@param ply Player
---@param point Entity
---@internal
function SpawnpointEditor:SetSelectedSpawnpoint(ply, point)
    net.Start('easy_spawnpoint_editor')
    net.WriteUInt(SpawnpointEditor.NetType.Move, 2)
    net.WriteEntity(point)
    net.Send(ply)
end

-- Hooks

local function send_pickup_entity(ent, ply)
    net.Start('easy_spawnpoint_editor')
    net.WriteUInt(SpawnpointEditor.NetType.Pickup, 2)
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
local function wrap_spawnpoint_selector()
    local GM = gmod.GetGamemode()
    local PlayerSelectSpawn = GM.PlayerSelectSpawn

    if not PlayerSelectSpawn then return end

    function GM:PlayerSelectSpawn(...)
        if self.SpawnPoints then
            return PlayerSelectSpawn(self, ...)
        end

        local selected_point = PlayerSelectSpawn(self, ...)
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

        return PlayerSelectSpawn(self, ...)
    end
end

hook.Add('OnGamemodeLoaded', 'SpawnpointEditor.WrapSelector', wrap_spawnpoint_selector)