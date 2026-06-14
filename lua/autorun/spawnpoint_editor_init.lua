
spawnpoint_editor = spawnpoint_editor or {}

function spawnpoint_editor.IsAllowedToUse(ply)
    return ply:IsSuperAdmin()
end

if SERVER then
    include('spawnpoint_editor/init.lua')
end