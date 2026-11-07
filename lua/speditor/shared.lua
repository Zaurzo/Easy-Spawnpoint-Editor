require('lua.weapons.gmod_tool.stools.speditor')

SpawnpointEditor = SpawnpointEditor or {}

-- The mask a trace needs to have to be able to hit the client spawnpoints.
SpawnpointEditor.TRACE_MASK = bit.bor(MASK_SOLID, CONTENTS_CURRENT_0)

-- Note: I need the custom spawnpoints to not collide with anything, but still have the
-- tool's trace to be able to hit them. I chose this random contents mask to ensure a
-- foreign trace won't hit them.

---@enum ToolOperation
SpawnpointEditor.ToolOperation = {
    --- The default operation.
    Add = 0,
    --- When aiming at a spawnpoint.
    Apply = 1,
    --- When you have a spawnpoint selected.
    Move = 2
}

spawnpoint.RegisterClass('editable_spawnpoint')

---Returns true if the provided player is allowed to use the spawnpoint editor tool.
---If servers wish to change the permissions, they should override this function.
---@param ply Player The player to check.
---@return boolean
function SpawnpointEditor:IsAllowedToUseTool(ply)
    return ply:IsSuperAdmin()
end

---Returns the table of the spawnpoint editor tool if the player is currently using it.
---@param ply Player
---@return TOOL speditor
function SpawnpointEditor:TryGetTool(ply)
    if not self:IsAllowedToUseTool(ply) then
        return nil
    end
    
    local tool = ply:GetTool()

    if not tool or tool.Mode ~= 'speditor' then
        return nil
    end

    local wep = ply:GetActiveWeapon()

    if not wep:IsValid() or wep:GetClass() ~= 'gmod_tool' then
        return nil
    end

    return tool
end