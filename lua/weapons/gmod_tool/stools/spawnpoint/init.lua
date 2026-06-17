
function TOOL:Think()
    if self:GetOperation() == self.Operation.Move then return end

    local operation = self.Operation.Add
    
    if self:GetClientNumber('index') ~= 0 then
        operation = self.Operation.Apply
    end

    self:SetOperation(operation)
end

function TOOL:Holster()
    self:SetOperation(self.Operation.Add)

    local move_ent = self:GetMoveSpawnPoint()
    if not IsValid(move_ent) then return end

    move_ent:SetNoCollide(false)
    move_ent:SetNoDraw(false)

    self:SetMoveSpawnPoint(NULL)
end