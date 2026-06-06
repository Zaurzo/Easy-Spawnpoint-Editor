
spawnpoint = {}

-- Spawnflag enum
-- The spawnpoint selector will always choose the first spawnpoint with this flag
spawnpoint.SF_MASTER_SPAWNPOINT = 1

local class_registry = {}
local unsuitable_points = {}

local entity_classes = {
   	-- Half-Life 2 (Deathmatch) Maps
	info_player_start = true,
	info_player_combine = true,
	info_player_rebel = true,

	info_player_teamspawn = true, -- TF Maps
	info_player_blue = true,
	info_player_red = true,
	info_player_coop = true, -- Synergy?
	info_player_deathmatch = true,
	info_player_zombiemaster = true, -- ZM
	info_spawnpoint = true,

	info_player_counterterrorist = true, -- CSS
	info_player_terrorist = true,

	info_player_allies = true, -- DODS
	info_player_axis = true,

	info_player_knight = true, -- PVKII
	info_player_pirate = true,
	info_player_viking = true,

	info_survivor_position = true, -- L4D
	info_survivor_rescue = true,

	info_player_human = true, -- ZPS
	info_player_zombie = true,

	diprip_start_team_red = true, -- DIPRIP
	diprip_start_team_blue = true,

	info_player_fof = true, -- Firstful of Frags
	info_player_desperado = true,
	info_player_vigilante = true,

	info_player_attacker = true, -- NEOTOKYO
	info_player_defender = true,

	info_player_usa = true, -- MC:V
	info_player_vc = true,
	info_zombie_spawn = true,
	info_deathmatch_spawn = true,

	info_coop_spawn = true, -- Portal 2 Coop
	ins_spawnpoint = true, -- Insurgency
	dys_spawn_point = true, -- Dystopia
	aoc_spawnpoint = true, -- Age of Chivalry
	info_ff_teamspawn = true, -- Fortress Forever

	gmod_player_start = true -- (Old) GMod Maps
}

function spawnpoint.IsSpawnPointClass(class)
    return entity_classes[class]
end

function spawnpoint.RegisterClass(class)
    if entity_classes[class] then return end

    entity_classes[class] = true

    table.insert(class_registry, class)
end

function spawnpoint.GetClassRegistry()
    return class_registry
end

function spawnpoint.GetAll(map_created)
    local spawnpoints, n = {}, 0

    for k, ent in ents.Iterator() do
        if entity_classes[ent:GetClass()] and (not map_created or ent:CreatedByMap()) then
            n = n + 1
            spawnpoints[n] = ent
        end
    end

    return spawnpoints
end

local function invalidate_cache()
    local gm = gmod.GetGamemode()

    if gm then
        gm.SpawnPoints = nil
    end
end

function spawnpoint.SetUnsuitable(point, value)
    if isentity(point) and entity_classes[point:GetClass()] then
        unsuitable_points[point] = value or nil

        invalidate_cache()
    end
end

function spawnpoint.IsUnsuitable(point)
    return unsuitable_points[point] or false
end

spawnpoint.InvalidateCache = invalidate_cache

local function add_missing_values(to, from)
    local existing = {}

    for k, value in ipairs(to) do
        existing[value] = true
    end

    for k, value in ipairs(from) do
        if not existing[value] then
            table.insert(to, value)
        end
    end
end

hook.Add('PreRegisterSENT', 'SpawnPointClassRegistry', function(tab, class)
    if class ~= 'gmod_player_start' then return end

    -- We need to use this table as it's what the default spawnpoint selector uses
    local custom_classes = tab.SpawnPointClasses
    if not custom_classes then return end

    for k, class in ipairs(custom_classes) do
        entity_classes[class] = true
    end

    add_missing_values(custom_classes, class_registry)

    class_registry = custom_classes
end)

hook.Add('IsSpawnpointSuitable', 'SpawnPointSuitability', function(ply, point)
    if unsuitable_points[point] then
        return false
    end
end)

hook.Add('OnGamemodeLoaded', 'RemoveUnsuitableSpawnPoints', function()
    local GM = gmod.GetGamemode()
    local PlayerSelectSpawn = GM.PlayerSelectSpawn

    function GM:PlayerSelectSpawn(ply, transition)
        local point = PlayerSelectSpawn(self, ply, transition)

        if not self.SpawnPoints then -- We likely aren't using the default selector
            return point
        end

        -- We selected an unsuitable spawnpoint
        if point and unsuitable_points[point] then
            local sanitized_list = {}

            -- Replace the SpawnPoints cache with a version without
            -- the unsuitable points and re-roll.
            --
            -- We do this because of how the default spawnpoint selector works.
            -- Even if all the spawnpoints it tries fail IsSpawnpointSuitable, it will
            -- ultimately just force itself to use one.
            for k, point in ipairs(self.SpawnPoints) do
                if not unsuitable_points[point] then
                    table.insert(sanitized_list, point)
                end
            end

            self.SpawnPoints = sanitized_list

            return PlayerSelectSpawn(self, ply, transition)
        end

        return point
    end
end)
