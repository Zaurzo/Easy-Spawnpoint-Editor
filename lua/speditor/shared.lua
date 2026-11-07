require('spawnpoint')

SpawnpointEditor = SpawnpointEditor or {}

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

---Returns true if the provided player is currently using the spawnpoint editor tool.
---@param ply Player The player to check.
---@return boolean
function SpawnpointEditor:IsUsingTool(ply)
    local tool = ply:GetTool()

    if not tool or tool.Mode ~= 'spawnpoint' then
        return false
    end

    local wep = ply:GetActiveWeapon()

    return wep:IsValid() and wep:GetClass() == 'gmod_tool'
end