
AddCSLuaFile()

ENT.Base = 'base_anim'
ENT.Type = 'anim'

function ENT:Initialize()
    self:SetModel('models/editor/playerstart.mdl')
    self:SetSubMaterial(0, 'editor/orange_mono')
    self:EnableCustomCollisions()
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
    self:NetworkVar('Bool', 3, 'SetInvisible')

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

        spawnpoint.InvalidateCache()
    end

    function ENT:Think()
        self:NextThink(CurTime())

        return true
    end
end

if CLIENT then
    matproxy.Add {
        name = 'SpawnPointColor',

        bind = function(self, mat, ent)
            if ent.GetSpawnPointColor then
                mat:SetVector('$color2', ent:GetSpawnPointColor())
            end
        end
    }

    function ENT:Think()
        self:NextThink(CurTime())

        self.CanDraw = false

        local ply = LocalPlayer()
        local wep = ply:GetActiveWeapon()

        if not wep:IsValid() or wep:GetClass() ~= 'gmod_tool' then
            return true
        end

        local tool = ply:GetTool()

        if not tool or tool.Mode ~= 'spawnpoint' then
            return true
        end

        local index = self:EntIndex()

        if index == tool:GetClientNumber('index') then
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

        return true
    end

    function ENT:Draw()
        if self.CanDraw then
            self:DrawModel()
        end
    end
end
