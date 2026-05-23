
function TOOL:Deploy()
    self:SetOperation(0)
end

function TOOL:GetSpawnPointOnCrosshair()
    local index = self:GetClientNumber('index')

    if index < 0 then
        return nil
    end

    local ent = Entity(index)

    if ent:IsValid() and ent:GetClass() == 'networked_spawnpoint' then
        return ent
    end

    return nil
end

function TOOL:Think()
    self:SetOperation(self:GetSpawnPointOnCrosshair() and 1 or 0)
end