-- Easy Spawnpoint Editor

local HOOK_NAME = 'EasySpawnpointEditor.Initialize'

local function init_spawnpoint_editor()
    hook.Remove('InitPostEntity', HOOK_NAME)

    local gm = gmod.GetGamemode()
    if not gm or not gm.IsSandboxDerived then return end -- Tool available only in the Sandbox family

    if SERVER then
        include('speditor/init.lua')
    else
        include('speditor/cl_init.lua')
    end
end

hook.Add('InitPostEntity', HOOK_NAME, init_spawnpoint_editor)