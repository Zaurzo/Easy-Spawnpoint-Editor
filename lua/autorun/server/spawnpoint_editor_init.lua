
require('spawnpoint')
require('spawnpoint/editor')

local save_data = spawnpoint.editor.SaveData
local points = save_data:Load()

hook.Add('InitPostEntity', 'SpawnpointEditor.Setup', function()
    spawnpoint.editor.Setup()
end)

hook.Add('PostCleanupMap', 'SpawnpointEditor.Setup', function()
    spawnpoint.editor.Setup()
end)

-- Internal hook
hook.Add('SpawnpointEditor.OnSpawnpointsChanged', 'SpawnpointEditor', function()
    save_data:Save()
end)

-- Commands

concommand.Add('spawnpoint_destroy_player_created', function(ply)
    spawnpoint.editor.RemovePlayerCreated()

    save_data:Save()
end)

concommand.Add('spawnpoint_destroy_map_created', function(ply)
    spawnpoint.editor.RemoveMapCreated()

    save_data:Save()
end)

concommand.Add('spawnpoint_restore_default', function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    for k, point in ipairs(ents.FindByClass('networked_spawnpoint')) do
        local parent = point:GetSpawnPointParent()

        if parent then
            point:SetNoDraw(false)
            point:SetAngles(point.StoredAngle)
            point:SetNoCollide(false)
            point:SetSpawnPointColor(Vector(0, 1, 0))
            point:SetIsMasterSpawnPoint(point.StoredMaster)

            spawnpoint.SetMaster(parent, point.StoredMaster)
            spawnpoint.SetUnsuitable(parent, false)

            point.IsDestroyed = false
        end
    end

    save_data:Save()
end)