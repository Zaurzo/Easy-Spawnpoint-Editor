
function TOOL:Deploy()
    self:SetOperation(0)
end

function TOOL:Reload()
    local degrees = self:GetClientNumber('rotate_degrees')
    local rotation = self:GetClientNumber('rotation') + degrees

    if rotation >= 360 then
        rotation = 0
    end

    rotation = math.SnapTo(rotation, degrees)

    self:GetOwner():ConCommand('spawnpoint_rotation ' .. rotation)
end

function TOOL:GetSpawnPoint()
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
    self:SetOperation(self:GetSpawnPoint() and 1 or 0)
end