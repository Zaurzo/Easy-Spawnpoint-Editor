
require('spawnpoint')

local save_data = include('includes/persistence.lua')
save_data:Load()

-- Register our custom spawnpoint class to be chosen by the default spawnpoint selector
spawnpoint.RegisterClass('networked_spawnpoint')

-- Default spawnpoint entities are point entities, meaning they are not networked to the client.
-- This means we have to create our own visual representation of them.
local function setup_visual_representation(point, data)
    local visual = ents.Create('networked_spawnpoint')
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
        local networked_spawnpoint = ents.Create('networked_spawnpoint')

        if not networked_spawnpoint:IsValid() then
            ErrorNoHaltWithStack('could not create spawnpoint')
            break
        end

        networked_spawnpoint:SetPos(data.pos)
        networked_spawnpoint:SetAngles(data.ang)
        networked_spawnpoint:Spawn()
        networked_spawnpoint:SetSpawnPointColor(data.color)
        networked_spawnpoint:SetIsMasterSpawnPoint(data.master)

        spawnpoint.SetMaster(networked_spawnpoint, data.master)
    end
end

function spawnpoint_editor.RestoreMapDefaults()
    for k, point in ipairs(ents.FindByClass('networked_spawnpoint')) do
        local parent = point:GetSpawnPointParent()

        if parent then
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

hook.Add('InitPostEntity', 'SpawnpointEditor.Setup', spawnpoint_editor.Setup)
hook.Add('PostCleanupMap', 'SpawnpointEditor.Setup', spawnpoint_editor.Setup)

-- Internal hook
hook.Add('SpawnpointEditor.OnSpawnpointsChanged', 'SpawnpointEditor', function()
    save_data:Save()
end)

-- Commands

concommand.Add('spawnpoint_destroy_player_created', function(ply)
    if IsValid(ply) and not spawnpoint_editor.IsAllowedToUse(ply) then return end

    for k, point in ipairs(ents.FindByClass('networked_spawnpoint')) do
        if not point:GetSpawnPointParent() then
            point:Destroy()
        end
    end

    save_data:Save()
end)

concommand.Add('spawnpoint_destroy_map_created', function(ply)
    if IsValid(ply) and not spawnpoint_editor.IsAllowedToUse(ply) then return end

    for k, point in ipairs(ents.FindByClass('networked_spawnpoint')) do
        if point:GetSpawnPointParent() then
            point:Destroy()
        end
    end

    save_data:Save()
end)

concommand.Add('spawnpoint_restore_default', function(ply)
    if IsValid(ply) and not spawnpoint_editor.IsAllowedToUse(ply) then return end

    spawnpoint_editor.RestoreMapDefaults()

    save_data:Save()
end)