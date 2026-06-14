
function TOOL:Think()
    if self:GetOperation() ~= 2 then
        self:SetOperation(self:GetClientNumber('index') ~= 0 and 1 or 0)
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