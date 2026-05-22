
TOOL.Category = 'Construction'
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

function TOOL:GetColor()
    local r = self:GetClientNumber('r', 0)
    local g = self:GetClientNumber('g', 255)
    local b = self:GetClientNumber('b', 0)

    return Color(r, g, b, 255)
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

function TOOL:LeftClick(tool_tr)
    local tr = self:GetTrace()
    local spawnpoint = tr.Entity

    tool_tr.HitNormal = tr.HitNormal
    tool_tr.HitPos = tr.HitPos

    -- Apply settings to spawnpoint on crosshair
    if self:GetOperation() == 1 and IsValid(spawnpoint) then
        local is_master = self:GetClientBool('master')

        spawnpoint:SetSpawnPointColor(self:GetColor():ToVector())
        spawnpoint:SetIsMasterSpawnPoint(is_master)

        if is_master then
            spawnpoint:AddSpawnFlags(SF_MASTER_SPAWNPOINT)
        else
            spawnpoint:RemoveSpawnFlags(SF_MASTER_SPAWNPOINT)
        end

        tool_tr.Entity = spawnpoint

        return true
    end

    if SERVER then
        spawnpoint = ents.Create('networked_spawnpoint')

        if not spawnpoint:IsValid() then
            error('could not create networked spawnpoint')
        end

        spawnpoint:SetPos(tr.HitPos)
        spawnpoint:SetAngles(self:GetAngle())
        spawnpoint:Spawn()
        spawnpoint:SetSpawnPointColor(self:GetColor():ToVector())

        if self:GetClientBool('master') then
            spawnpoint:SetIsMasterSpawnPoint(true)
            spawnpoint:AddSpawnFlags(SF_MASTER_SPAWNPOINT)
        end

        local gm = gmod.GetGamemode()

        if gm then
            gm.SpawnPoints = nil -- Invalidate the SpawnPoints cache
        end
    end

    return true
end

function TOOL:RightClick(tool_tr)
    if self:GetOperation() ~= 1 then -- Operation is set to 1 if we're looking at a spawnpoint
        return false
    end

    local tr = self:GetTrace()
    local spawnpoint = tr.Entity

    if not IsValid(spawnpoint) then
        return false
    end

    tool_tr.HitNormal = tr.HitNormal
    tool_tr.HitPos = tr.HitPos
    tool_tr.Entity = spawnpoint

    spawnpoint:Remove()

    return true
end