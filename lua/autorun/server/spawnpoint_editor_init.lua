
require('spawnpoint')
include('spawnpoint_editor/post_entity_created.lua')

local save_data = include('spawnpoint_editor/save_data.lua')
local points = save_data:Load()

-- Register our custom spawnpoint class to be chosen by the
-- default spawnpoint selector
spawnpoint.RegisterClass('networked_spawnpoint')

hook.Add('InitPostEntity', 'SpawnpointEditor.Initialize', function()
    for k, data in ipairs(points.created) do
        local networked_spawnpoint = ents.Create('networked_spawnpoint')

        if not networked_spawnpoint:IsValid() then
            ErrorNoHaltWithStack('could not create networked_spawnpoint')
            break
        end

        networked_spawnpoint:SetPos(data.pos)
        networked_spawnpoint:SetAngles(data.ang)
        networked_spawnpoint:Spawn()
        networked_spawnpoint:AddEFlags(EFL_KEEP_ON_RECREATE_ENTITIES)
        networked_spawnpoint:SetSpawnPointColor(data.color)
        networked_spawnpoint:SetIsMasterSpawnPoint(data.master)
    end
end)

hook.Add('SpawnpointEditor.PostEntityCreated', 'SetupSpawnPoint', function(ent)
    local class = ent:GetClass()
    if not spawnpoint.IsSpawnPointClass(class) or class == 'networked_spawnpoint' then return end

    -- Default spawnpoints are not networked to the client, so we have to create
    -- our own visual representations of them
    local networked_spawnpoint = ents.Create('networked_spawnpoint')

    if not networked_spawnpoint:IsValid() then
        ErrorNoHaltWithStack('could not create networked_spawnpoint')
        return
    end

    networked_spawnpoint:Spawn()
    networked_spawnpoint:SetSpawnPointParent(ent)

    local data = save_data:GetChangeData(ent)
    if not data then return end

    if data.removed then
        networked_spawnpoint:Destroy()
        return
    end

    if data.master then
        ent:AddSpawnFlags(spawnpoint.SF_MASTER_SPAWNPOINT)
    else
        ent:RemoveSpawnFlags(spawnpoint.SF_MASTER_SPAWNPOINT)
    end

    ent:SetAngles(data.ang)

    networked_spawnpoint:SetIsMasterSpawnPoint(data.master)
    networked_spawnpoint:SetSpawnPointColor(data.color)
end)

-- Internal hook
hook.Add('SpawnpointEditor.OnSpawnpointsChanged', 'SpawnpointEditor', function()
    save_data:Save()
end)

-- Commands

local function destroy_all_player_created()
    for k, point in ipairs(ents.FindByClass('networked_spawnpoint')) do
        if not point:GetSpawnPointParent() then
            point:Destroy()
        end
    end

    save_data:Save()
end

concommand.Add('spawnpoint_destroy_player_created', function(ply)
    if not IsValid(ply) or ply:IsSuperAdmin() then
        destroy_all_player_created()
    end
end)

concommand.Add('spawnpoint_destroy_map_created', function(ply)
    for k, point in ipairs(ents.FindByClass('networked_spawnpoint')) do
        if point:GetSpawnPointParent() then
            point:Destroy()
        end
    end

    save_data:Save()
end)

concommand.Add('spawnpoint_restore_default', function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    for k, point in ipairs(ents.FindByClass('networked_spawnpoint')) do
        local parent = point:GetSpawnPointParent()

        if parent then
            point:SetNoDraw(false)
            point:SetNoCollide(false)
            point:SetSpawnPointColor(Vector(0, 1, 0))
            point:SetAngles(point.StoredAngle)
            point:SetIsMasterSpawnPoint(point.StoredMaster)

            if point.StoredMaster then
                parent:AddSpawnFlags(spawnpoint.SF_MASTER_SPAWNPOINT)
            else
                parent:RemoveSpawnFlags(spawnpoint.SF_MASTER_SPAWNPOINT)
            end

            point.IsDestroyed = false

            spawnpoint.SetUnsuitable(parent, false)
        end
    end

    save_data:Save()
end)
