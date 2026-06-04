
spawnpoint = {}

local entity_classes = {
   	-- Half-Life 2 (Deathmatch) Maps
	["info_player_start"] = true,
	["info_player_combine"] = true,
	["info_player_rebel"] = true,

	-- (Old) GMod Maps
	["gmod_player_start"] = true,

	-- TF Maps
	["info_player_teamspawn"] = true,
}

local class_registry = {}

function spawnpoint.IsSpawnPoint(ent)
    return entity_classes[ent:GetClass()]
end

function spawnpoint.RegisterClass(class)
    if entity_classes[class] then return end

    entity_classes[class] = true

    table.insert(class_registry, class)
end

function spawnpoint.GetAll()
    local spawnpoints, n = {}, 0

    for k, ent in ents.Iterator() do
        if entity_classes[ent:GetClass()] then
            n = n + 1
            spawnpoints[n] = ent
        end
    end

    return spawnpoints
end

function spawnpoint.InvalidateCache()
    local gm = gmod.GetGamemode()

    if gm then
        gm.SpawnPoints = nil
    end
end

hook.Add('PreRegisterSENT', 'SpawnpointClassRegistry', function(tab, class)
    if class ~= 'gmod_player_start' then return end

    local custom_classes = tab.SpawnPointClasses
    local classes_registered = {}

    for k, class in ipairs(custom_classes) do
        entity_classes[class] = true
        classes_registered[class] = true
    end

    for i = 1, #class_registry do
        local class = class_registry[i]

        if not classes_registered[class] then
            table.insert(custom_classes, class)
        end

        class_registry[i] = nil
    end

    class_registry = custom_classes
end)
