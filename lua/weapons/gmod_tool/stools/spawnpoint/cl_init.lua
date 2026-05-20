
local ghost_spawnpoint

local render_settings = {
    model = 'models/editor/playerstart.mdl'
}

local proxy = {
    name = 'SpawnPointColor'
}

function proxy:init(mat, values)
    self.ResultTo = values.resultvar
end

function proxy:bind(mat, ent)
    if ent.GetSpawnPointColor then
        mat:SetVector(self.ResultTo, ent:GetSpawnPointColor())
    end
end

matproxy.Add(proxy)

function TOOL:SetClientNumber(property, value)
    if self.ClientConVars[property] then
		self.ClientConVars[property]:SetFloat(value)
	end
end

local current_spawnpoint

function TOOL:DrawHUD()
    local tr = self:GetTrace()
    local ent = tr.Entity

    if IsValid(ent) and ent:GetClass() == 'networked_spawnpoint' then
        if current_spawnpoint ~= ent then
            current_spawnpoint = ent

            self:SetClientNumber('index', ent:EntIndex())
        end

        return
    elseif current_spawnpoint then
        current_spawnpoint = nil

        self:SetClientNumber('index', -1)
    end

    if not ghost_spawnpoint or not ghost_spawnpoint:IsValid() then
        ghost_spawnpoint = ClientsideModel(render_settings.model)
        
        ghost_spawnpoint:SetSubMaterial(0, 'editor/orange_mono')
        ghost_spawnpoint:SetNoDraw(true)

        function ghost_spawnpoint:GetSpawnPointColor()
            return self.color
        end
    end

    render_settings.pos = tr.HitPos
    render_settings.angle = self:GetAngle()
    ghost_spawnpoint.color = self:GetColor():ToVector()

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

    panel:ColorPicker(
        '#tool.colour.color', 
        'spawnpoint_r', 
        'spawnpoint_g', 
        'spawnpoint_b'
    )
end