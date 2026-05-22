
hook.Add('InitPostEntity', 'EasySpawnpointEditor.Initialize', function()

    -- Get list of all spawnpoint entity classes
    -- https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/base/gamemode/player.lua#L360-L495

    local spawn_point_entity_classes = {
        -- Half-Life 2 (Deathmatch) Maps
        ['info_player_start'] = true,
        ['info_player_combine'] = true,
        ['info_player_rebel'] = true,

        -- (Old) GMod Maps
        ['gmod_player_start'] = true,

        -- TF Maps
        ['info_player_teamspawn'] = true,
    }

    local extra_classes = scripted_ents.GetMember('gmod_player_start', 'SpawnPointClasses')

    for _, class in pairs(extra_classes) do
        spawn_point_entity_classes[class] = true
    end

    for _, ent in ents.Iterator() do
        if spawn_point_entity_classes[ent:GetClass()] then
            local networked_spawnpoint = ents.Create('networked_spawnpoint')

            if not networked_spawnpoint:IsValid() then
                error('could not create networked_spawnpoint')
            end

            networked_spawnpoint:Spawn()
            networked_spawnpoint:SetSpawnPointParent(ent)
        end
    end

    -- Register our custom spawnpoint
    table.insert(extra_classes, 'networked_spawnpoint')
end)

hook.Add('IsSpawnpointSuitable', 'EasySpawnpointEditor', function(ply, spawnpoint)
    if spawnpoint:GetClass() == 'networked_spawnpoint' and spawnpoint:GetSpawnPointParent() then
        return false
    end
end)