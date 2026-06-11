
AddCSLuaFile()

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

    GetChangeData = function(self, ent)
        local id = ent:MapCreationID()

        return id ~= -1 and self.points.changed[id]
    end
}

spawnpoint.editor.SaveData = save_data

if SERVER then
    include('persistence/sv_init.lua')
else
    include('persistence/cl_init.lua')
end