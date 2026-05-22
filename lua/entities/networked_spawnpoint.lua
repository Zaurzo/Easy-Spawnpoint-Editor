
AddCSLuaFile()

ENT.Base = 'base_anim'
ENT.Type = 'anim'

function ENT:Initialize()
    self:SetModel('models/editor/playerstart.mdl')
    self:SetSubMaterial(0, 'editor/orange_mono')
    self:EnableCustomCollisions(true)
    self:DrawShadow(false)
    self:SetSolid(SOLID_BBOX)

    self:SetCollisionBounds(
        Vector(-10, -10, 0),
        Vector(10, 10, 70)
    )

    if CLIENT then
        self.halo = { self }
    end
end

function ENT:SetupDataTables()
    self:NetworkVar('Vector', 0, 'SpawnPointColor')
    self:NetworkVar('String', 1, 'SpawnPointClassName')
    self:NetworkVar('Bool', 2, 'IsMasterSpawnPoint')

    if SERVER then
        self:SetSpawnPointColor(Vector(0, 1, 0))
        self:SetSpawnPointClassName('info_player_start')
        self:SetIsMasterSpawnPoint(false)
    end
end

function ENT:TestCollision(startpos, delta, isbox, extends, mask)
    -- I need everything to pass through this entity, but allow
    -- client-side traces to hit it, so I check for a random
    -- content mask

    return bit.band(mask, CONTENTS_CURRENT_0) == CONTENTS_CURRENT_0
end

if SERVER then
    local SF_MASTER_SPAWNPOINT = 1

    function ENT:SetSpawnPointParent(spawnpoint)
        self:SetPos(spawnpoint:GetPos())
        self:SetAngles(spawnpoint:GetAngles())
        self:SetSpawnPointClassName(spawnpoint:GetClass())
        self:SetParent(spawnpoint)
        self:DeleteOnRemove(spawnpoint)

        if spawnpoint:HasSpawnFlags(SF_MASTER_SPAWNPOINT) then
            self:SetIsMasterSpawnPoint(true)
        end
        
        self.SpawnPointParent = spawnpoint
    end

    function ENT:GetSpawnPointParent()
        return self.SpawnPointParent
    end
end

if CLIENT then
    function ENT:Think()
        self.CanDraw = false

        local ply = LocalPlayer()
        local wep = ply:GetActiveWeapon()

        if not wep:IsValid() or wep:GetClass() ~= 'gmod_tool' then return end

        local tool = ply:GetTool()
        if not tool or tool.Mode ~= 'spawnpoint' then return end

        local index = self:EntIndex()

        if tool:GetClientNumber('index') == index then
            local tip = self:GetSpawnPointClassName()

            if self:GetIsMasterSpawnPoint() then
                tip = tip .. ' (Master)'
            end

            local offset = self:OBBCenter()
            offset.z = self:OBBMaxs().z - 6

            AddWorldTip(index, tip, nil, self:GetPos() + offset)

            halo.Add(self.halo, color_white, 1, 1, 2, true, true)
        end

        self.CanDraw = true
    end

    function ENT:Draw()
        if self.CanDraw then
            self:DrawModel()
        end
    end
end