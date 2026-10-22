local held_physics_entity
local selected_spawnpoint

net.Receive('easy_spawnpoint_editor', function()
    local net_type = net.ReadUInt(2)
    local ent = net.ReadEntity()

    if net_type == SpawnpointEditor.NetType.Pickup then
        held_physics_entity = ent
    elseif net_type == SpawnpointEditor.NetType.Move then
        selected_spawnpoint = ent
    end
end)

---Returns true if the local player is currently holding a physics object.
---@return boolean
function SpawnpointEditor:IsHoldingEntity()
    return IsValid(held_physics_entity)
end

---Returns the currently selected spawnpoint.
---@return Entity
function SpawnpointEditor:GetSelectedSpawnpoint()
    return selected_spawnpoint
end