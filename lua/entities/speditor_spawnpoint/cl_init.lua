
include('shared.lua')

--[[
function ENT:Setup()
    self.halo_tab = { self }
end

function ENT:Think()
    self.CanDraw = false

    local ply = LocalPlayer()
    if not spawnpoint_editor.IsAllowedToUse(ply) then return end

    local tool = ply:GetTool()
    if not tool or tool.Mode ~= 'spawnpoint' then return end

    local wep = ply:GetActiveWeapon()
    if not wep:IsValid() or wep:GetClass() ~= 'gmod_tool' then return end

    if tool:GetOperation() ~= 2 then
        local index = self:EntIndex()

        if index == tool:GetClientNumber('index') then
            local tip = self:GetSpawnPointClassName()

            if self:GetIsMasterSpawnPoint() then
                tip = string.format('%s (%s)', tip, language.GetPhrase('speditor.master'))
            end

            local offset = self:OBBCenter()
            offset.z = self:OBBMaxs().z - 6

            AddWorldTip(index, tip, nil, self:GetPos() + offset)

            halo.Add(self.halo_tab, color_white, 1, 1, 2, true, true)
        end
    end

    self.CanDraw = true
end]]

function ENT:Draw()
    local color = self:GetColor()

    render.SuppressEngineLighting(true)
    render.SetColorModulation(color.r / 255, color.g / 255, color.b / 255)

    self:DrawModel()

    render.SuppressEngineLighting(false)
end
