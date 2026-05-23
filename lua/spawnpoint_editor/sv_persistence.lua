
file.CreateDir('spawnpoint_editor')

local persistence_path = 'spawnpoint_editor/' .. game.GetMap() .. '.json'
local json = file.Read(persistence_path, 'DATA')

if json then
    g_SpawnPoints = util.JSONToTable(json)
end

local function save_persistence()
    file.Write(persistence_path, util.TableToJSON(g_SpawnPoints, true))
end

hook.Add('SpawnpointEditor.OnCreated', 'OnCreated', function(spawnpoint)
    local data = {
        pos = spawnpoint:GetPos(),
        ang = spawnpoint:GetAngles(),
        color = spawnpoint:GetSpawnPointColor(),
        master = spawnpoint:GetIsMasterSpawnPoint(),
        index = spawnpoint:EntIndex()
    }

    table.insert(g_SpawnPoints[1], data)

    save_persistence()
end)

hook.Add('SpawnpointEditor.OnRemoved', 'OnRemoved', function(spawnpoint)
    local map_id = spawnpoint:GetSpawnPointMapID()

    if map_id then
        g_SpawnPoints[0][map_id] = { removed = true }
    else
        for k, data in ipairs(g_SpawnPoints[1]) do
            if data.index == spawnpoint:EntIndex() then
                table.remove(g_SpawnPoints[1], k)
                break
            end
        end
    end

    save_persistence()
end)

hook.Add('SpawnpointEditor.OnChanged', 'OnChanged', function(spawnpoint)
    local map_id = spawnpoint:GetSpawnPointMapID()

    if map_id then
        local data = {
            removed = false,
            ang = spawnpoint:GetAngles(),
            master = spawnpoint:GetIsMasterSpawnPoint(),
            color = spawnpoint:GetSpawnPointColor()
        }

        g_SpawnPoints[0][map_id] = data
    else
        for k, data in ipairs(g_SpawnPoints[1]) do
            if data.index == spawnpoint:EntIndex() then
                data.ang = spawnpoint:GetAngles()
                data.master = spawnpoint:GetIsMasterSpawnPoint()
                data.color = spawnpoint:GetSpawnPointColor()

                break
            end
        end
    end

    save_persistence()
end)

concommand.Add('spawnpoint_save', function(ply)
    if not IsValid(ply) or ply:IsSuperAdmin() then
        save_persistence()
    end
end)