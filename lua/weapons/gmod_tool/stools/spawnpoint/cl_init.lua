
TOOL.SpawnPointIndex = 0

local looking_at_spawnpoint

function TOOL:Think()
    local ent = self:GetTrace().Entity
    looking_at_spawnpoint = IsValid(ent) and ent:GetClass() == 'networked_spawnpoint'

    self:SetClientInfo('index', looking_at_spawnpoint and ent:EntIndex() or 0)
end

local ghost_spawnpoint
local render_settings = {
    model = 'models/editor/playerstart.mdl'
}

function TOOL:DrawHUD()
    if looking_at_spawnpoint then return end
    if not spawnpoint_editor.IsAllowedToUse(self:GetOwner()) then return end

    if not ghost_spawnpoint or not ghost_spawnpoint:IsValid() then
        ghost_spawnpoint = ClientsideModel(render_settings.model)

        ghost_spawnpoint:SetSubMaterial(0, 'editor/orange_mono')
        ghost_spawnpoint:SetNoDraw(true)

        function ghost_spawnpoint:GetSpawnPointColor()
            return self.color
        end
    end

    render_settings.pos = self:GetTrace().HitPos
    render_settings.angle = self:GetAngle()
    ghost_spawnpoint.color = self:GetColorVector()

    cam.Start3D()

    render.SetBlend(0.5)
    render.Model(render_settings, ghost_spawnpoint)
    render.SetBlend(1)

    cam.End3D()
end

local default_convars = TOOL:BuildConVarList()

function TOOL.BuildCPanel(panel)
    panel:Help('#tool.spawnpoint.desc')
    panel:ToolPresets('spawnpoint', default_convars)

    panel:NumSlider('#tool.spawnpoint.rotate_degrees', 'spawnpoint_rotate_degrees', 0, 360)
    panel:NumSlider('#tool.spawnpoint.rotation', 'spawnpoint_rotation', 0, 360)

    panel:CheckBox('#tool.spawnpoint.master', 'spawnpoint_master')
    panel:Help('#tool.spawnpoint.master_desc')

    panel:ColorPicker(
        '#tool.colour.color',
        'spawnpoint_r',
        'spawnpoint_g',
        'spawnpoint_b'
    )

    panel:Button('#tool.spawnpoint.button_restore', 'spawnpoint_restore_default')
    panel:Button('#tool.spawnpoint.button_destroy_map', 'spawnpoint_destroy_map_created')
    panel:Button('#tool.spawnpoint.button_destroy_player', 'spawnpoint_destroy_player_created')
end

hook.Add('CanTool', 'SpawnpointEditor', function(ply, tr, tool_name)
    if tool_name == 'spawnpoint' and not spawnpoint_editor.IsAllowedToUse(ply) then
        return false
    end
end)