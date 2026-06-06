
include('shared.lua')

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
