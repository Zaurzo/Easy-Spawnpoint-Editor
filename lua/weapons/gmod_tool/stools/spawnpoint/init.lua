
function TOOL:Think()
    if self:GetOperation() ~= 2 then
        self:SetOperation(self:GetClientNumber('index') ~= 0 and 1 or 0)
    end
end

function TOOL:Holster()
    self:SetOperation(0)
    
    local move_ent = self:GetMoveSpawnPoint()
    if not IsValid(move_ent) then return end

    move_ent:SetNoCollide(false)
    move_ent:SetNoDraw(false)

    self:SetMoveSpawnPoint(NULL)
end