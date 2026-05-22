
function TOOL:Deploy()
    self:SetOperation(0)
end

function TOOL:Reload()
    local degrees = self:GetClientNumber('rotate_degrees')
    local spawnpoint = self:GetSpawnPointOnCrosshair()

    if spawnpoint then
        spawnpoint = spawnpoint:GetSpawnPointParent() or spawnpoint

        local ang = spawnpoint:GetAngles()
        local rotation = ang.y + degrees

        rotation = math.SnapTo(rotation % 360, degrees)
        ang.y = rotation

        spawnpoint:SetAngles(ang)
    else
        local rotation = self:GetClientNumber('rotation') + degrees
        rotation = math.SnapTo(rotation % 360, degrees)

        self:GetOwner():ConCommand('spawnpoint_rotation ' .. rotation)
    end
end

function TOOL:GetSpawnPointOnCrosshair()
    local index = self:GetClientNumber('index')

    if index < 0 then
        return nil
    end

    local spawnpoint = Entity(index)

    if spawnpoint:IsValid() and spawnpoint:GetClass() == 'networked_spawnpoint' then
        return spawnpoint
    end

    return nil
end

function TOOL:Think()
    self:SetOperation(self:GetSpawnPointOnCrosshair() and 1 or 0)
end