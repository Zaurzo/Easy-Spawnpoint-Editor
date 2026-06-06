
AddCSLuaFile('shared.lua')
AddCSLuaFile('cl_init.lua')

include('shared.lua')

function ENT:Think()
    self:NextThink(CurTime())
    return true
end

function ENT:SetSpawnPointParent(point)
    self.StoredAngle = point:GetAngles()
    self.StoredMaster = point:HasSpawnFlags(spawnpoint.SF_MASTER_SPAWNPOINT)

    self:SetPos(point:GetPos())
    self:SetAngles(point:GetAngles())
    self:SetSpawnPointClassName(point:GetClass())
    self:SetParent(point)
    self:DeleteOnRemove(point)

    if self.StoredMaster then
        self:SetIsMasterSpawnPoint(true)
    end

    self.SpawnPointParent = point

    spawnpoint.SetUnsuitable(self, true)
end

function ENT:GetSpawnPointParent()
    return self.SpawnPointParent
end

function ENT:GetSpawnPointMapID()
    local point = self.SpawnPointParent
    if not point then return end

    local creation_id = point:MapCreationID()

    if creation_id ~= -1 then
        return creation_id
    end

    return nil
end

function ENT:SetNoCollide(state)
    if state then
        self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
    else
        self:SetCollisionGroup(COLLISION_GROUP_NONE)
    end
end

function ENT:Destroy()
    local parent = self.SpawnPointParent

    if parent then
        -- Hide and block the map created spawnpoint
        spawnpoint.SetUnsuitable(parent, true)

        self:SetNoDraw(true)
        self:SetNoCollide(true)
    else
        self:Remove()
    end
end

function ENT:OnRemove()
    spawnpoint.InvalidateCache()
end
