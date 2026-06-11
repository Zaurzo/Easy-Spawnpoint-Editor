
file.CreateDir('spawnpoint_editor')

local save_data = {
    path = 'spawnpoint_editor/' .. game.GetMap() .. '.json',

    points = {
        changed = { -- Change data of map-created spawnpoints
        --    [1] = {
        --        ang = Angle(),
        --        color = Vector(),
        --        removed = false,
        --        master = false
        --    }
        },
        created = { -- Data of player-created spawnpoints
        --    [1] = {
        --        pos = Vector(),
        --        ang = Angle(),
        --        color = Vector(),
        --        master = false
        --    }
        }
    }
}

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

    file.Write(self.path, util.TableToJSON(points))

    self.loaded = true
end

function save_data:Load()
    if not self.loaded then
        local json = file.Read(self.path, 'DATA')

        if json then
            self.points = util.JSONToTable(json)
        end
    end
    
    self.loaded = true

    return self.points
end

function save_data:GetChangeData(ent)
    local id = ent:MapCreationID()

    return id ~= -1 and self.points.changed[id]
end

return save_data