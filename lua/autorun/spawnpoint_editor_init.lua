-- Easy Spawnpoint Editor

if SERVER then
    include('spawnpoint_editor/init.lua')
else
    include('spawnpoint_editor/cl_init.lua')
end