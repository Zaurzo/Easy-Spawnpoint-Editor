
AddCSLuaFile('cl_init.lua')

util.AddNetworkString('SpawnpointEditor.ReceiveSaveData')

local save_data = spawnpoint.editor.SaveData

function save_data:Save()
    local points = self.points

    points.changed = {}
    points.created = {}

    for k, point in ipairs(ents.FindByClass('networked_spawnpoint')) do
        local data = {
            ang = point:GetAngles(),
            color = point:GetSpawnPointColor(),
            master = point:GetIsMasterSpawnPoint()
        }

        local id = point:GetSpawnPointMapID()

        if id then
            data.removed = point.IsDestroyed
            points.changed[id] = data
        elseif not point.IsDestroyed then
            data.pos = point:GetPos()

            table.insert(points.created, data)
        end
    end

    self:WriteToDisk()
end

net.Receive('SpawnpointEditor.ReceiveSaveData', function(len, ply)
    if not ply:IsSuperAdmin() then return end

end)