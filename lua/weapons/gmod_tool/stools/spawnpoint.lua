
AddCSLuaFile('spawnpoint/cl_init.lua')

TOOL.Category = 'Zaurzo'
TOOL.Name = '#tool.spawnpoint.name'

TOOL.ClientConVar['r'] = 0
TOOL.ClientConVar['g'] = 255
TOOL.ClientConVar['b'] = 0
TOOL.ClientConVar['index'] = 0
TOOL.ClientConVar['master'] = 0
TOOL.ClientConVar['rotation'] = 0
TOOL.ClientConVar['rotate_degrees'] = 45

TOOL.Information = {
    { name = 'info', op = 2 },
	{ name = 'left', op = 0 },
    { name = 'left_1', op = 1 },
    { name = 'left_2', op = 2 },
	{ name = 'right', op = 1 },
    { name = 'reload' },
    { name = 'use', op = 1 },
}

---@enum Operation
TOOL.Operation = {
    --- The default operation.
    Add = 0,

    --- When aiming at a spawnpoint.
    Apply = 1,

    --- When you have a spawnpoint selected.
    Move = 2
}

TOOL.SelectDistance = 512

if SERVER then
    include('spawnpoint/init.lua')
else
    include('spawnpoint/cl_init.lua')
end

local NW_VAR_MOVE_ENT = 'SpawnpointEditor_MoveEnt'

function TOOL:GetMoveSpawnPoint()
    return self:GetWeapon():GetNWEntity(NW_VAR_MOVE_ENT, NULL)
end

function TOOL:SetMoveSpawnPoint(point)
    self:GetWeapon():SetNWEntity(NW_VAR_MOVE_ENT, point)
end

function TOOL:SetClientInfo(property, value)
    if SERVER then
        self:GetOwner():ConCommand('spawnpoint_' .. property .. ' ' .. tostring(value))
   	elseif self.ClientConVars[property] then
		self.ClientConVars[property]:SetString(value)
    end
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
	trace.endpos = trace.start + (ply:GetAimVector() * self.SelectDistance)
	trace.filter = ply
    trace.mask = bit.bor(MASK_SOLID, CONTENTS_CURRENT_0)

    return util.TraceLine(trace)
end

function TOOL:IsOwnerHoldingEntity()
    local ply = self:GetOwner()
    return spawnpoint_editor.IsHoldingEntity(ply)
end

function TOOL:LeftClick(tool_tr)
    if self:IsOwnerHoldingEntity() then return end

    local tr = self:GetTrace()

    tool_tr.HitNormal = tr.HitNormal
    tool_tr.HitPos = tr.HitPos

    local wep = self:GetWeapon()
    local move_ent = self:GetMoveSpawnPoint()

    -- Move selected spawnpoint
    if IsValid(move_ent) then
        if SERVER then
            local point = move_ent:GetSpawnPointParent() or move_ent

            point:SetPos(tool_tr.HitPos)
            point:SetAngles(self:GetAngle())
        end

        move_ent:SetNoDraw(false)
        move_ent:SetNoCollide(false)

        hook.Run('SpawnpointEditor.OnSpawnpointsChanged')

        self:SetMoveSpawnPoint(NULL)
        self:SetOperation(self.Operation.Apply)

        return true
    end

    local tr_ent = tr.Entity

    -- Apply settings to spawnpoint on crosshair
    if IsValid(tr_ent) and tr_ent:GetClass() == 'editable_spawnpoint' then
        local is_master = self:GetClientBool('master')
        local point = tr_ent

        tr_ent:SetSpawnPointColor(self:GetColorVector())
        tr_ent:SetIsMasterSpawnPoint(is_master)

        if SERVER then
            point = point:GetSpawnPointParent() or point
            spawnpoint.SetMaster(point, is_master)

            hook.Run('SpawnpointEditor.OnSpawnpointsChanged')
        end

        tool_tr.Entity = point

        return true
    end

    if SERVER then
        local editable_spawnpoint = ents.Create('editable_spawnpoint')

        if not editable_spawnpoint:IsValid() then
            error('could not create networked spawnpoint')
        end

        editable_spawnpoint:SetPos(tr.HitPos)
        editable_spawnpoint:SetAngles(self:GetAngle())
        editable_spawnpoint:SetSpawnEffect(true)
        editable_spawnpoint:Spawn()
        editable_spawnpoint:SetSpawnPointColor(self:GetColorVector())

        if self:GetClientBool('master') then
            editable_spawnpoint:SetIsMasterSpawnPoint(true)

            spawnpoint.SetMaster(editable_spawnpoint, true)
        end

        undo.Create('info_player_start')
            undo.AddEntity(editable_spawnpoint)
            undo.SetPlayer(self:GetOwner())
        undo.Finish()

        hook.Run('SpawnpointEditor.OnSpawnpointsChanged')
    end

    return true
end

function TOOL:RightClick(tool_tr)
    if self:IsOwnerHoldingEntity() then return end

    local tr = self:GetTrace()
    local ent = tr.Entity

    if not IsValid(ent) or ent:GetClass() ~= 'editable_spawnpoint' then
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

		if ent:GetSpawnPointParent() then
            ent:Destroy()

            hook.Run('SpawnpointEditor.OnSpawnpointsChanged')

            return true
        end

        ent:SetNotSolid(true)
        ent:SetNoDraw(true)

        -- Wait for the remove effect
        timer.Simple(0.15, function()
            if not ent:IsValid() then return end

            ent:Destroy()

            hook.Run('SpawnpointEditor.OnSpawnpointsChanged')
        end)
    end

    return true
end

function TOOL:Reload(tool_tr)
    if self:IsOwnerHoldingEntity() then return end

    local degrees = self:GetClientNumber('rotate_degrees')

    local tr = self:GetTrace()
    local ent = tr.Entity

    if IsValid(ent) and ent:GetClass() == 'editable_spawnpoint' then
        if SERVER then
            local point = ent:GetSpawnPointParent() or ent
            local ang = point:GetAngles()

            ang.y = math.SnapTo(ang.y + degrees, degrees) % 360

            point:SetAngles(ang)

            hook.Run('SpawnpointEditor.OnSpawnpointsChanged')
        end

        tool_tr.HitNormal = tr.HitNormal
        tool_tr.HitPos = tr.HitPos

        return true
    end

    local rotation = math.SnapTo(self:GetClientNumber('rotation') + degrees, degrees)

    self:SetClientInfo('rotation', rotation % 360)
end

function TOOL:Allowed()
    if not self.AllowedCVar:GetBool() then
        return false
    end

    local ply = self:GetOwner()

    return not IsValid(ply) or spawnpoint_editor.IsAllowedToUse(ply)
end