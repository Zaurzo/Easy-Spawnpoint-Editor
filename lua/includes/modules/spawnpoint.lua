-- Spawnpoint Module
-- This should only really be used after entities are initialized

spawnpoint = {}

-- Spawnflag that determines if the spawnpoint is the master spawnpoint
local SF_MASTER_SPAWNPOINT = 1

local spawn_point_classes
local spawn_point_cache

local spawn_point_class_registry = {
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

local function get_class_list()
    if spawn_point_classes then
        return spawn_point_classes
    end

    local gmod_player_start = scripted_ents.GetStored('gmod_player_start')
    if not gmod_player_start then return end
    
    spawn_point_classes = gmod_player_start.t.SpawnPointClasses

    local is_in_class_list = {}

    -- Sync our internal lookup table with the class list
    for _, class in ipairs(spawn_point_classes) do
        is_in_class_list[class] = true
        spawn_point_class_registry[class] = true
    end

    -- Add any custom registered class to the class list
    for class in pairs(spawn_point_class_registry) do
        if not is_in_class_list[class] then
            table.insert(spawn_point_classes, class)
        end
    end

    return spawn_point_classes
end

---Registers a class as a spawnpoint entity class.
---@param class_name string The name of the class to register.
function spawnpoint.RegisterClass(class_name)
    if spawn_point_class_registry[class_name] then return end

    local class_list = get_class_list()

    if class_list then
        table.insert(class_list, class_name)
    end

    spawn_point_class_registry[class_name] = true
    spawn_point_cache = nil

    spawnpoint.InvalidateCache()
end

---Returns whether or not the provided class is a spawnpoint entity class.
---@param class_name string The name of the class to check.
---@return boolean
function spawnpoint.IsClass(class_name)
    return spawn_point_class_registry[class_name]
end

---Returns a new list of all spawnpoints currently on the map.
---@return Entity[]
function spawnpoint.GetAll()
    local points = {}

    for _, ent in ents.Iterator() do
        if spawn_point_class_registry[ent:GetClass()] then
            table.insert(points, ent)
        end
    end

    return points
end

local current_entity_cache

---Returns an iterator for all spawnpoints currently on the map.
---@return table spawnpoints The cached spawnpoint list to iterate over.
---@return function iterator
---@return number startIndex
function spawnpoint.Iterator()
    local _, entity_cache = ents.Iterator() -- entity cache is refreshed whenever an entity is created or removed

    if entity_cache ~= current_entity_cache then
        spawn_point_cache = spawnpoint.GetAll()
        current_entity_cache = entity_cache
    end

    return ipairs(spawn_point_cache)
end

---Sets a spawnpoint to be unsuitable for selection or not.
---@param point Entity The spawnpoint to set unsuitable.
---@param value boolean Whether or not to be unsuitable.
function spawnpoint.SetUnsuitable(point, value)
    if not spawnpoint.IsClass(point:GetClass()) then return end

    point.m_SpawnpointModuleUnsuitable = value and true or nil

    spawnpoint.InvalidateCache()
end

---Returns whether or not the spawnpoint is unsuitable for selection.
---@param point Entity The spawnpoint to check.
---@return boolean unsuitable
function spawnpoint.IsUnsuitable(point)
    return point.m_SpawnpointModuleUnsuitable
end

---Sets a spawnpoint to be the master spawnpoint.
---The spawnpoint selector will choose master spawnpoints over all else.
---@param point Entity The spawnpoint to set as the master.
---@param value boolean Whether or not to be master.
function spawnpoint.SetMaster(point, value)
    if not spawnpoint.IsClass(point:GetClass()) then return end

    if value then
        point:AddSpawnFlags(SF_MASTER_SPAWNPOINT)
    else
        point:RemoveSpawnFlags(SF_MASTER_SPAWNPOINT)
    end

    spawnpoint.InvalidateCache()
end

---Returns whether or not the spawnpoint is the master spawnpoint.
---@param point Entity The spawnpoint to check.
---@return boolean master
function spawnpoint.IsMaster(point)
    if spawnpoint.IsClass(point:GetClass()) then
        return point:HasSpawnFlags(SF_MASTER_SPAWNPOINT)
    end
end

---Invalidates the internal spawnpoint entity cache used by the gamemode.
function spawnpoint.InvalidateCache()
    local GM = gmod.GetGamemode()

    if GM then
        GM.SpawnPoints = nil
    end
end

-- Detour management

-- Clear unsuitable spawnpoints from internal gamemode spawnpoint list
--  I detour this because the default selector has an unfortunate behavior:
--  if all candidates fail/are unsuitable, it will just return the last candidate tried.
local function wrap_spawnpoint_selector()
    local GM = gmod.GetGamemode()
    local PlayerSelectSpawn = GM.PlayerSelectSpawn

    if not PlayerSelectSpawn then return end

    function GM:PlayerSelectSpawn(...)
        if self.SpawnPoints then
            return PlayerSelectSpawn(self, ...)
        end

        local selected_point = PlayerSelectSpawn(self, ...)
        local spawn_points = self.SpawnPoints

        if not spawn_points then
            return selected_point
        end

        for i = #spawn_points, 1, -1 do
            local point = spawn_points[i]

            if spawnpoint.IsUnsuitable(point) then
                table.remove(spawn_points, i)
            end
        end

        return PlayerSelectSpawn(self, ...)
    end
end

-- Hooks

hook.Add('IsSpawnpointSuitable', 'spawnpoint.module.IsSpawnpointSuitable', function(ply, point)
    if spawnpoint.IsUnsuitable(point) then
        return false
    end
end)

hook.Add('Initialize', 'spawnpoint.Initialize', function()
    wrap_spawnpoint_selector()
    get_class_list() -- cache class list
end)