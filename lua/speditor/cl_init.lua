include('shared.lua')

local held_physics_entity

net.Receive('speditor_physics_pickup', function()
    local ent = net.ReadEntity()

    held_physics_entity = ent:IsValid() and ent or nil
end)

---Returns true if the local player is currently holding a physics object.
---@return boolean
function SpawnpointEditor:IsHoldingEntity()
    return IsValid(held_physics_entity)
end