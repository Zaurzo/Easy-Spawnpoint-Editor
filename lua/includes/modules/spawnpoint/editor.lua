
-- Editor sub-module for 'spawnpoint' module
-- I wish to keep 'spawnpoint' its own separate module and usable outside this addon.

AddCSLuaFile()

module('spawnpoint.editor', package.seeall)

include('editor/persistence.lua')

MAX_SPAWNPOINT_COUNT = 512

-- Register our custom spawnpoint class to be chosen by the
-- default spawnpoint selector
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

        point:SetAngles(data.ang)

        visual:SetIsMasterSpawnPoint(data.master)
        visual:SetSpawnPointColor(data.color)
    else
        visual:Destroy()
    end

    return visual
end

function Setup()
    local points = SaveData:Load()

    for k, map_point in ipairs(spawnpoint.GetAll(true)) do
        local data = points.changed[ map_point:MapCreationID() ]

        if not setup_visual_representation(map_point, data) then 
            ErrorNoHaltWithStack('could not create visual representations for spawnpoints')
            break 
        end
    end

    for k, data in ipairs(points.created) do
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

function RemoveMapCreated()
    for k, point in ipairs(ents.FindByClass('networked_spawnpoint')) do
        if point:GetSpawnPointParent() then
            point:Destroy()
        end
    end
end

function RemovePlayerCreated()
    for k, point in ipairs(ents.FindByClass('networked_spawnpoint')) do
        if not point:GetSpawnPointParent() then
            point:Destroy()
        end
    end
end