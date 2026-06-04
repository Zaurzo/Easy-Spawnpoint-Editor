
TOOL.Category = 'Zaurzo'
TOOL.Name = '#tool.spawnpoint.name'

TOOL.ClientConVar['r'] = 0
TOOL.ClientConVar['g'] = 255
TOOL.ClientConVar['b'] = 0
TOOL.ClientConVar['index'] = -1
TOOL.ClientConVar['master'] = 0
TOOL.ClientConVar['rotation'] = 0
TOOL.ClientConVar['rotate_degrees'] = 45

TOOL.Information = {
	{ name = 'left', op = 0 },
    { name = 'left_1', op = 1 },
	{ name = 'right', op = 1 },
    { name = 'reload' }
}

if SERVER then
    AddCSLuaFile('spawnpoint/cl_init.lua')
    include('spawnpoint/init.lua')
else
    include('spawnpoint/cl_init.lua')
end

function TOOL:GetColorVector()
    local r = self:GetClientNumber('r', 0)
    local g = self:GetClientNumber('g', 255)
    local b = self:GetClientNumber('b', 0)

    return Color(r, g, b, 255):ToVector()
end

function TOOL:GetAngle()
    local rotation = self:GetClientNumber('rotation')

    return Angle(0, rotation, 0)
end

function TOOL:GetTrace()
    local trace = {}
    local ply = self:GetOwner()

	trace.start = ply:EyePos()
	trace.endpos = trace.start + (ply:GetAimVector() * 512)
	trace.filter = ply
    trace.mask = bit.bor(MASK_SOLID, CONTENTS_CURRENT_0)

    return util.TraceLine(trace)
end

local SF_MASTER_SPAWNPOINT = 1

local function invalidate_spawnpoints_cache()
    local gm = gmod.GetGamemode()

    if gm then
        gm.SpawnPoints = nil
    end
end

function TOOL:LeftClick(tool_tr)
    local tr = self:GetTrace()
    local networked_spawnpoint = tr.Entity

    tool_tr.HitNormal = tr.HitNormal
    tool_tr.HitPos = tr.HitPos

    -- Apply settings to spawnpoint on crosshair
    if self:GetOperation() == 1 and IsValid(networked_spawnpoint) then
        local is_master = self:GetClientBool('master')

        networked_spawnpoint:SetSpawnPointColor(self:GetColorVector())
        networked_spawnpoint:SetIsMasterSpawnPoint(is_master)

        tool_tr.Entity = spawnpoint

        local spawnpoint = networked_spawnpoint

        if SERVER then
            spawnpoint = spawnpoint:GetSpawnPointParent() or spawnpoint
        end

        if is_master then
            spawnpoint:AddSpawnFlags(SF_MASTER_SPAWNPOINT)
        else
            spawnpoint:RemoveSpawnFlags(SF_MASTER_SPAWNPOINT)
        end

        if SERVER then
            hook.Run('SpawnpointEditor.OnChanged', networked_spawnpoint)

            invalidate_spawnpoints_cache()
        end

        return true
    end

    if SERVER then
        networked_spawnpoint = ents.Create('networked_spawnpoint')

        if not networked_spawnpoint:IsValid() then
            error('could not create networked spawnpoint')
        end

        networked_spawnpoint:SetPos(tr.HitPos)
        networked_spawnpoint:SetAngles(self:GetAngle())
        networked_spawnpoint:SetSpawnEffect(true)
        networked_spawnpoint:Spawn()
        networked_spawnpoint:SetSpawnPointColor(self:GetColorVector())
        networked_spawnpoint:AddEFlags(EFL_KEEP_ON_RECREATE_ENTITIES)

        if self:GetClientBool('master') then
            networked_spawnpoint:SetIsMasterSpawnPoint(true)
            networked_spawnpoint:AddSpawnFlags(SF_MASTER_SPAWNPOINT)
        end

        hook.Run('SpawnpointEditor.OnCreated', networked_spawnpoint)

        invalidate_spawnpoints_cache()
    end

    return true
end

function TOOL:RightClick(tool_tr)
    local tr = self:GetTrace()
    local ent = tr.Entity

    if not IsValid(ent) or ent:GetClass() ~= 'networked_spawnpoint' then
        return false
    end

    tool_tr.HitNormal = tr.HitNormal
    tool_tr.HitPos = tr.HitPos
    tool_tr.Entity = ent

    if SERVER then
        local ed = EffectData()

		ed:SetOrigin(ent:GetPos())
		ed:SetEntity(ent)

	    util.Effect('entity_remove', ed, true, true)

        ent:SetNotSolid(true)
        ent:SetNoDraw(true)

        -- Wait for the remove effect
        timer.Simple(0.15, function()
            if ent:IsValid() then
                ent:Remove()

                invalidate_spawnpoints_cache()
            end
        end)

        hook.Run('SpawnpointEditor.OnRemoved', ent)
    end

    return true
end

function TOOL:Reload(tool_tr)
    local degrees = self:GetClientNumber('rotate_degrees')

    local tr = self:GetTrace()
    local ent = tr.Entity

    if IsValid(ent) and ent:GetClass() == 'networked_spawnpoint' then
        if SERVER then
            local spawnpoint = ent:GetSpawnPointParent() or ent
            local ang = spawnpoint:GetAngles()

            ang.y = math.SnapTo((ang.y + degrees) % 360, degrees)

            spawnpoint:SetAngles(ang)
        end

        tool_tr.HitNormal = tr.HitNormal
        tool_tr.HitPos = tr.HitPos

        hook.Run('SpawnpointEditor.OnChanged', ent)

        return true
    end

    local rotation = self:GetClientNumber('rotation') + degrees
    rotation = math.SnapTo(rotation % 360, degrees)

    self:GetOwner():ConCommand('spawnpoint_rotation ' .. rotation)
end
