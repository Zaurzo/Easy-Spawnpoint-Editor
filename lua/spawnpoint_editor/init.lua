
require('spawnpoint')

local save_data = include('includes/persistence.lua')
save_data:Load()

-- Register our custom spawnpoint class to be chosen by the default spawnpoint selector
spawnpoint.RegisterClass('editable_spawnpoint')

-- Default spawnpoint entities are point entities, meaning they are not networked to the client.
-- This means we have to create our own visual representation of them.
local function setup_visual_representation(point, data)
    local visual = ents.Create('editable_spawnpoint')
    if not visual:IsValid() then return end

    visual:Spawn()
    visual:SetSpawnPointParent(point)

    if not data then
        return visual
    end

    if not data.removed then
        spawnpoint.SetMaster(point, data.master)

        if data.pos then
            point:SetPos(data.pos)
        end

        point:SetAngles(data.ang)

        visual:SetIsMasterSpawnPoint(data.master)
        visual:SetSpawnPointColor(data.color)
    else
        visual:Destroy()
    end

    return visual
end

function spawnpoint_editor.Setup()
    for k, map_point in ipairs(spawnpoint.GetAll(true)) do
        local data = save_data.points.changed[ map_point:MapCreationID() ]

        if not setup_visual_representation(map_point, data) then 
            ErrorNoHaltWithStack('could not create visual representations for spawnpoints')
            break 
        end
    end

    for k, data in ipairs(save_data.points.created) do
        local editable_spawnpoint = ents.Create('editable_spawnpoint')

        if not editable_spawnpoint:IsValid() then
            ErrorNoHaltWithStack('could not create spawnpoint')
            break
        end

        editable_spawnpoint:SetPos(data.pos)
        editable_spawnpoint:SetAngles(data.ang)
        editable_spawnpoint:Spawn()
        editable_spawnpoint:SetSpawnPointColor(data.color)
        editable_spawnpoint:SetIsMasterSpawnPoint(data.master)

        spawnpoint.SetMaster(editable_spawnpoint, data.master)
    end
end

function spawnpoint_editor.RestoreMissingDefaults()
    for k, point in ipairs(ents.FindByClass('editable_spawnpoint')) do
        local parent = point:GetSpawnPointParent()

        if parent and point.IsDestroyed then
            parent:SetPos(point.StoredPosition)
            parent:SetAngles(point.StoredAngle)

            point:SetNoDraw(false)
            point:SetNoCollide(false)
            point:SetSpawnPointColor(Vector(0, 1, 0))
            point:SetIsMasterSpawnPoint(point.StoredMaster)

            spawnpoint.SetMaster(parent, point.StoredMaster)
            spawnpoint.SetUnsuitable(parent, false)

            point.IsDestroyed = false
        end
    end
end

function spawnpoint_editor.RemoveMapCreated()
    for k, point in ipairs(ents.FindByClass('editable_spawnpoint')) do
        if point:GetSpawnPointParent() then
            point:Destroy()
        end
    end
end

hook.Add('InitPostEntity', 'SpawnpointEditor.Setup', spawnpoint_editor.Setup)
hook.Add('PostCleanupMap', 'SpawnpointEditor.Setup', spawnpoint_editor.Setup)

-- Internal hook
hook.Add('SpawnpointEditor.OnSpawnpointsChanged', 'SpawnpointEditor', function()
    save_data:Save()
end)

-- Commands

concommand.Add('spawnpoint_remove_player_created', function(ply)
    if IsValid(ply) and not spawnpoint_editor.IsAllowedToUse(ply) then return end

    for k, point in ipairs(ents.FindByClass('editable_spawnpoint')) do
        if not point:GetSpawnPointParent() then
            point:Destroy()
        end
    end

    save_data:Save()
end)

concommand.Add('spawnpoint_remove_map_created', function(ply)
    if IsValid(ply) and not spawnpoint_editor.IsAllowedToUse(ply) then return end

    spawnpoint_editor.RemoveMapCreated()

    save_data:Save()
end)

concommand.Add('spawnpoint_restore_missing', function(ply)
    if IsValid(ply) and not spawnpoint_editor.IsAllowedToUse(ply) then return end

    spawnpoint_editor.RestoreMissingDefaults()

    save_data:Save()
end)

concommand.Add('spawnpoint_reset_map_created', function(ply)
    if IsValid(ply) and not spawnpoint_editor.IsAllowedToUse(ply) then return end

    spawnpoint_editor.RemoveMapCreated()
    spawnpoint_editor.RestoreMissingDefaults()

    save_data:Save()
end)

concommand.Add('spawnpoint_reset', function(ply)
    if IsValid(ply) and not spawnpoint_editor.IsAllowedToUse(ply) then return end

    for k, point in ipairs(ents.FindByClass('editable_spawnpoint')) do
        point:Destroy()
    end

    spawnpoint_editor.RestoreMissingDefaults()

    save_data:Save()
end)