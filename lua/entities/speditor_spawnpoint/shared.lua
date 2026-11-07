ENT.Base = 'base_anim'
ENT.Type = 'anim'
ENT.Model = 'models/editor/playerstart.mdl'
ENT.BodyMaterial = 'editor/orange_mono'
ENT.DoNotDuplicate = true
ENT.DefaultColor = Color(0, 255, 0)

AccessorFunc(ENT, '_no_collision', 'NoCollision', FORCE_BOOL)

function ENT:Initialize()
    self:SetModel(self.Model)
    self:SetSubMaterial(0, self.BodyMaterial)
    self:SetColor(self.DefaultColor)
    self:DrawShadow(false)
    self:SetSolid(SOLID_BBOX)

    self:SetCollisionBounds(
        Vector(-10, -10, 0),
        Vector(10, 10, 70)
    )

    self:EnableCustomCollisions()
end

function ENT:SetupDataTables()
    self:NetworkVar('String', 'SpawnpointClass')
    self:NetworkVar('Bool', 'Master')

    if SERVER then
        self:SetSpawnpointClass(self:GetClass())
        self:SetMaster(false)
    end
end

local MASK_PLAYER_USE = 100745227

function ENT:TestCollision(startpos, delta, isbox, extends, mask)
    if self:GetNoCollision() then
        return false
    end

    if mask == MASK_ALL then -- Block properties menu
        return false
    end
    
    -- Allow player +use
    if bit.band(mask, MASK_PLAYER_USE) == MASK_PLAYER_USE then
        return true
    end

    return mask == SpawnpointEditor.TRACE_MASK
end
