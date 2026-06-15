
spawnpoint_editor = spawnpoint_editor or {}

local NW_BOOL_NAME = 'SpawnpointEditor.IsHoldingEntity'

if SERVER then
    include('spawnpoint_editor/init.lua')

    hook.Add('OnPlayerPhysicsPickup', 'SpawnpointEditor', function(ply)
        ply:SetNWBool(NW_BOOL_NAME, true)
    end)

    hook.Add('OnPlayerPhysicsDrop', 'SpawnpointEditor', function(ply)
        ply:SetNWBool(NW_BOOL_NAME, false)
    end)
end

function spawnpoint_editor.IsAllowedToUse(ply)
    return ply:IsSuperAdmin()
end

function spawnpoint_editor.IsHoldingEntity(ply)
    return ply:GetNWBool(NW_BOOL_NAME, false)
end