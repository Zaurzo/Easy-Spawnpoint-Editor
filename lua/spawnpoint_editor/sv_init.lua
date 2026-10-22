util.AddNetworkString('easy_spawnpoint_editor')

---@param ply Player
---@param ent Entity
---@internal
function SpawnpointEditor:SetHeldEntity(ply, ent)
    net.Start('easy_spawnpoint_editor')
    net.WriteUInt(SpawnpointEditor.NetType.Pickup, 2)
    net.WriteEntity(ent)
    net.Send(ply)
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

hook.Add('OnPlayerPhysicsPickup', 'SpawnpointEditor', function(ply, ent)
    if SpawnpointEditor:IsAllowedToUseTool(ply) and SpawnpointEditor:IsUsingTool(ply) then
        SpawnpointEditor:SetHeldEntity(ply, ent)
    end
end)