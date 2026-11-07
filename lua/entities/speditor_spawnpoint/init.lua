
AddCSLuaFile('shared.lua')
AddCSLuaFile('cl_init.lua')

include('shared.lua')

function ENT:OnRemove()
    spawnpoint.InvalidateCache()
end

hook.Add('FindUseEntity', 'SpawnpointEditor', function(ply, ent)
    local tool = ply:GetTool()
    if not tool or tool.Mode ~= 'spawnpoint' then return end

    local tr = tool:GetTrace()
    ent = tr.Entity

    if IsValid(ent) and ent:GetClass() == 'editable_spawnpoint' then
        return ent:OnUse(ply, tool)
    end
end)