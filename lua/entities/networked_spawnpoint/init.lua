
AddCSLuaFile('shared.lua')
AddCSLuaFile('cl_init.lua')

include('shared.lua')

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end

function ENT:SetSpawnPointParent(point)
    self.StoredPosition = point:GetPos()
    self.StoredAngle = point:GetAngles()
    self.StoredMaster = spawnpoint.IsMaster(point)

    self:SetPos(point:GetPos())
    self:SetAngles(point:GetAngles())
    self:SetSpawnPointClassName(point:GetClass())
    self:SetParent(point)
    self:DeleteOnRemove(point)
    self:SetUseType(SIMPLE_USE)

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
    self.IsDestroyed = true

    if self.SpawnPointParent then
        self:SetNoDraw(true)
        self:SetNoCollide(true)

        spawnpoint.SetUnsuitable(self.SpawnPointParent, true)
    else
        self:Remove()
    end
end

function ENT:OnUse(ply, tool)
    local wep = ply:GetActiveWeapon()

    if not wep:IsValid() or wep:GetClass() ~= 'gmod_tool' then 
        return NULL
    end

    if IsValid(wep.SpawnpointEditor_MoveEnt) then 
        return NULL
    end

    self:SetNoDraw(true)
    self:SetNoCollide(true)

    wep:SetNWEntity('SpawnpointEditor_MoveEnt', self)

    local ang = self:GetAngles()

    tool:SetOperation(2)
    tool:SetClientInfo('rotation', ang.y)

    return self
end

function ENT:OnRemove()
    spawnpoint.InvalidateCache()
end

hook.Add('FindUseEntity', 'SpawnpointEditor', function(ply, ent)
    local tool = ply:GetTool()
    if not tool or tool.Mode ~= 'spawnpoint' then return end

    local tr = tool:GetTrace()
    ent = tr.Entity

    if IsValid(ent) and ent:GetClass() == 'networked_spawnpoint' then
        return ent:OnUse(ply, tool)
    end
end)