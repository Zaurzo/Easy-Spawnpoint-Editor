
local looking_at_spawnpoint

function TOOL:Think()
    local ent = self:GetTrace().Entity
    looking_at_spawnpoint = IsValid(ent) and ent:GetClass() == 'editable_spawnpoint'

    self:SetClientInfo('index', looking_at_spawnpoint and ent:EntIndex() or 0)
end

local ghost_spawnpoint
local render_settings = {
    model = 'models/editor/playerstart.mdl'
}

function TOOL:DrawHUD()
    if looking_at_spawnpoint and self:GetOperation() ~= 2 then return end
    if not spawnpoint_editor.IsAllowedToUse(self:GetOwner()) then return end
    if self:IsOwnerHoldingEntity() then return end

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

    local move_ent = self:GetWeapon():GetNWEntity('SpawnpointEditor_MoveEnt')

    if IsValid(move_ent) then
        ghost_spawnpoint.color = move_ent:GetSpawnPointColor()
    else
        ghost_spawnpoint.color = self:GetColorVector()
    end

    cam.Start3D()

    render.SetBlend(0.5)
    render.Model(render_settings, ghost_spawnpoint)
    render.SetBlend(1)

    cam.End3D()
end

local default_convars = TOOL:BuildConVarList()

local function create_button(panel, label, command, msg)
    local button = panel:Button(label, command)

    function button:DoClick()
        RunConsoleCommand(command)

        notification.AddLegacy(msg, NOTIFY_CLEANUP, 5)
        surface.PlaySound('buttons/button15.wav')
    end
end

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

    panel:Help('#tool.spawnpoint.commands')

    create_button(
        panel, 
        '#tool.spawnpoint.button_reset_map_created', 
        'spawnpoint_reset_map_created',
        '#hint.spawnpoint.reset_map_created'
    )

    create_button(
        panel, 
        '#tool.spawnpoint.button_restore', 
        'spawnpoint_restore_missing',
        '#hint.spawnpoint.restore'
    )

    create_button(
        panel, 
        '#tool.spawnpoint.button_remove_map', 
        'spawnpoint_remove_map_created',
        '#hint.spawnpoint.removed_map_created'
    )

    create_button(
        panel, 
        '#tool.spawnpoint.button_remove_player', 
        'spawnpoint_remove_player_created',
        '#hint.spawnpoint.removed_player_created'
    )
end

hook.Add('CanTool', 'SpawnpointEditor', function(ply, tr, tool_name)
    if tool_name == 'spawnpoint' and not spawnpoint_editor.IsAllowedToUse(ply) then
        return false
    end
end)