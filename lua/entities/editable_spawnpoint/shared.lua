
ENT.Base = 'base_anim'
ENT.Type = 'anim'
ENT.Model = 'models/editor/playerstart.mdl'
ENT.BodyMaterial = 'editor/orange_mono'
ENT.DoNotDuplicate = true

function ENT:Initialize()
    self:SetModel(self.Model)
    self:SetSubMaterial(0, self.BodyMaterial)
    self:EnableCustomCollisions()
    self:DrawShadow(false)
    self:SetSolid(SOLID_BBOX)

    self:SetCollisionBounds(
        Vector(-10, -10, 0),
        Vector(10, 10, 70)
    )

    self:Setup()
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

local MASK_PLAYER_USE = 100745227

function ENT:TestCollision(startpos, delta, isbox, extends, mask)
    if mask == MASK_ALL then return false end -- Block properties menu
    
    -- Allow player +use
    if bit.band(mask, MASK_PLAYER_USE) == MASK_PLAYER_USE then
        return true
    end

    -- I need everything to pass through this entity, but allow
    -- client-side traces to hit it, so I just use and check for 
    -- this random contents mask.
    return bit.band(mask, CONTENTS_CURRENT_0) == CONTENTS_CURRENT_0
end
