
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

TOOL.SelectDistance = 512

if CLIENT then
    include('spawnpoint/cl_init.lua')
end

if SERVER then
    function TOOL:Think()
        if self:GetOperation() ~= 2 then
            self:SetOperation(self:GetClientNumber('index') != 0 and 1 or 0)
        end
    end

    function TOOL:Holster()
        local wep = self:GetWeapon()
        local move_ent = wep:GetNWEntity('SpawnpointEditor_MoveEnt')
        
        if not IsValid(move_ent) then return end

        move_ent:SetNoCollide(false)
        move_ent:SetNoDraw(false)

        wep:SetNWEntity('SpawnpointEditor_MoveEnt', NULL)
    end
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

function TOOL:LeftClick(tool_tr)
    local tr = self:GetTrace()

    tool_tr.HitNormal = tr.HitNormal
    tool_tr.HitPos = tr.HitPos

    local wep = self:GetWeapon()
    local move_ent = wep:GetNWEntity('SpawnpointEditor_MoveEnt')

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

        wep:SetNWEntity('SpawnpointEditor_MoveEnt', NULL)

        self:SetOperation(1)

        return true
    end

    local tr_ent = tr.Entity

    -- Apply settings to spawnpoint on crosshair
    if IsValid(tr_ent) and tr_ent:GetClass() == 'networked_spawnpoint' then
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
        local networked_spawnpoint = ents.Create('networked_spawnpoint')

        if not networked_spawnpoint:IsValid() then
            error('could not create networked spawnpoint')
        end

        networked_spawnpoint:SetPos(tr.HitPos)
        networked_spawnpoint:SetAngles(self:GetAngle())
        networked_spawnpoint:SetSpawnEffect(true)
        networked_spawnpoint:Spawn()
        networked_spawnpoint:SetSpawnPointColor(self:GetColorVector())

        if self:GetClientBool('master') then
            networked_spawnpoint:SetIsMasterSpawnPoint(true)

            spawnpoint.SetMaster(networked_spawnpoint, true)
        end

        undo.Create('info_player_start')
            undo.AddEntity(networked_spawnpoint)
            undo.SetPlayer(self:GetOwner())
        undo.Finish()

        hook.Run('SpawnpointEditor.OnSpawnpointsChanged')
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
    local degrees = self:GetClientNumber('rotate_degrees')

    local tr = self:GetTrace()
    local ent = tr.Entity

    if IsValid(ent) and ent:GetClass() == 'networked_spawnpoint' then
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