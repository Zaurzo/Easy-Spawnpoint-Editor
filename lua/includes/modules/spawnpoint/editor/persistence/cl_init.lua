
local save_data = spawnpoint.editor.SaveData

function save_data:SendToServer()
    net.Start('SpawnpointEditor.ReceiveSaveData')
    net.WriteString(util.TableToJSON(self.points))
    net.SendToServer()
end

net.Receive('SpawnpointEditor.ReceiveSaveData', function()
    local points = util.JSONToTable(net.ReadString())

    if points and points.changed and points.created then
        save_data.points = points
        save_data:WriteToDisk()
    end
end)