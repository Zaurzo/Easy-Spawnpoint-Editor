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
    },

    WriteToDisk = function(self)
        file.Write(self.path, util.TableToJSON(self.points))

        self.loaded = true
    end,

    Load = function(self)
        if not self.loaded then
            local json = file.Read(self.path, 'DATA')

            if json then
                self.points = util.JSONToTable(json)
            end
        end
        
        self.loaded = true

        return self.points
    end,

    BuildSaveData = function(self)
        local points = {
            changed = {},
            created = {}
        }

        for k, point in ipairs(ents.FindByClass('editable_spawnpoint')) do
            local data = {
                pos = point:GetPos(),
                ang = point:GetAngles(),
                color = point:GetSpawnPointColor(),
                master = point:GetIsMasterSpawnPoint()
            }

            local id = point:GetSpawnPointMapID()

            if id then
                data.removed = point.IsDestroyed
                points.changed[id] = data
            elseif not point.IsDestroyed then
                table.insert(points.created, data)
            end
        end

        return points
    end,

    Save = function(self)
        self.points = self:BuildSaveData()
        self:WriteToDisk()
    end,

    GetChangeData = function(self, ent)
        local id = ent:MapCreationID()

        return id ~= -1 and self.points.changed[id]
    end
}

--[[if SERVER then
    util.AddNetworkString('SpawnpointEditor.ReceiveSaveData')

    net.Receive('SpawnpointEditor.ReceiveSaveData', function(len, ply)
        if not spawnpoint_editor.IsAllowedToUse(ply) then return end

        local points = util.JSONToTable(net.ReadString())
        if not points or not points.changed or not points.created then return end

        save_data.points = points
        save_data:WriteToDisk()

        for k, point in ipairs(ents.FindByClass('editable_spawnpoint')) do
            local parent = point:GetSpawnPointParent()

            if parent then
                point:DontDeleteOnRemove(parent)
                point:SetParent(nil)
            end

            point:Remove()
        end

        spawnpoint_editor.Setup()
    end)
end]]

return save_data