
require('spawnpoint')
include('sv_postentitycreated.lua')

g_SpawnPoints = {
    [0] = {}, -- Default map spawnpoints
    [1] = {} -- Player-created spawnpoints
}

local persistence = include('sv_persistence.lua')
local SF_MASTER_SPAWNPOINT = 1

-- Register our custom spawnpoint
spawnpoint.RegisterClass('networked_spawnpoint')

hook.Add('InitPostEntity', 'SpawnpointEditor.Initialize', function()
    for _, data in ipairs(g_SpawnPoints[1]) do
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

        data.index = networked_spawnpoint:EntIndex()
    end
end)

-- Default spawnpoints are not networked to the client, so we have to create
-- our own visual representations of them
hook.Add('SpawnpointEditor.PostEntityCreated', 'CreateDisplays', function(ent)
    if not spawnpoint.IsSpawnPoint(ent) or ent:GetClass() == 'networked_spawnpoint' then return end

    local data = g_SpawnPoints[0][ent:MapCreationID()]

    if data then
        if data.removed then
            ent:Remove()
            return
        end

        if data.master then
            ent:AddSpawnFlags(SF_MASTER_SPAWNPOINT)
        end

        ent:SetAngles(data.ang)
    end

    local networked_spawnpoint = ents.Create('networked_spawnpoint')

    if not networked_spawnpoint:IsValid() then
        ErrorNoHaltWithStack('could not create networked_spawnpoint')
        return
    end

    networked_spawnpoint:Spawn()
    networked_spawnpoint:SetSpawnPointParent(ent)

    if data then
        networked_spawnpoint:SetSpawnPointColor(data.color)
    end
end)

-- Don't choose networked spawnpoints that are just for display
hook.Add('IsSpawnpointSuitable', 'SpawnpointEditor', function(ply, spawnpoint)
    if spawnpoint:GetClass() == 'networked_spawnpoint' and spawnpoint:GetSpawnPointParent() then
        return false
    end
end)

-- Commands

local function destroy_all_player_created()
    g_SpawnPoints[1] = {}

    for _, ent in ipairs(ents.FindByClass('networked_spawnpoint')) do
        if not ent:GetSpawnPointParent() then
            ent:Remove()
        end
    end
end

concommand.Add('spawnpoint_destroy_player_created', function(ply)
    if not IsValid(ply) or ply:IsSuperAdmin() then
        destroy_all_player_created()
    end
end)

concommand.Add('spawnpoint_destroy_map_created', function(ply)
    for _, ent in ipairs(ents.FindByClass('networked_spawnpoint')) do
        local parent = ent:GetSpawnPointParent()

        if parent then
            g_SpawnPoints[0][parent:MapCreationID()] = { removed = true }

            parent:Remove()
        end
    end

    persistence:Save()
end)

concommand.Add('spawnpoint_restore_default', function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    local filter = {}

    for _, ent in ents.Iterator() do
        if not spawnpoint.IsSpawnPoint(ent) then
            filter[ent:GetClass()] = true
        end
    end

    game.CleanUpMap(true, table.GetKeys(filter))

    g_SpawnPoints[0] = {}

    persistence:Save()

    destroy_all_player_created()
end)
