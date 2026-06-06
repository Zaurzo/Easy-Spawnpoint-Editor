
require('spawnpoint')
include('spawnpoint_editor/post_entity_created.lua')

local savedata = {
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

    Load = function(self)
        local json = file.Read(self.path, 'DATA')

        if json then
            self.points = util.JSONToTable(json)
        end

        return self.points
    end,

    Clear = function(self)
        self.points.changed = {}
        self.points.created = {}
    end,

    Save = function(self)
        file.CreateDir('spawnpoint_editor')
        file.Write(self.path, util.TableToJSON(self.points, true))
    end,

    GetChangeData = function(self, ent)
        local id = ent:MapCreationID()

        return id ~= -1 and self.points.changed[id]
    end
}

local points = savedata:Load()

-- Register our custom spawnpoint class to be chosen by the
-- default spawnpoint selector
spawnpoint.RegisterClass('networked_spawnpoint')

hook.Add('InitPostEntity', 'SpawnpointEditor.Initialize', function()
    for k, data in ipairs(points.created) do
        local networked_spawnpoint = ents.Create('networked_spawnpoint')

        if not networked_spawnpoint:IsValid() then
            ErrorNoHaltWithStack('could not create networked_spawnpoint')
            break
        end

        networked_spawnpoint:SetPos(data.pos)
        networked_spawnpoint:SetAngles(data.ang)
        networked_spawnpoint:Spawn()
        networked_spawnpoint:AddEFlags(EFL_KEEP_ON_RECREATE_ENTITIES)
        networked_spawnpoint:SetSpawnPointColor(data.color)
        networked_spawnpoint:SetIsMasterSpawnPoint(data.master)
    end
end)

hook.Add('SpawnpointEditor.PostEntityCreated', 'SetupSpawnPoint', function(ent)
    local class = ent:GetClass()
    if not spawnpoint.IsSpawnPointClass(class) or class == 'networked_spawnpoint' then return end

    local data = savedata:GetChangeData(ent)

    if data then
        if data.master then
            ent:AddSpawnFlags(spawnpoint.SF_MASTER_SPAWNPOINT)
        else
            ent:RemoveSpawnFlags(spawnpoint.SF_MASTER_SPAWNPOINT)
        end

        ent:SetAngles(data.ang)
    end

    -- Default spawnpoints are not networked to the client, so we have to create
    -- our own visual representations of them
    local networked_spawnpoint = ents.Create('networked_spawnpoint')

    if not networked_spawnpoint:IsValid() then
        ErrorNoHaltWithStack('could not create networked_spawnpoint')
        return
    end

    networked_spawnpoint:Spawn()
    networked_spawnpoint:SetSpawnPointParent(ent)

    if data then
        if data.removed then
            networked_spawnpoint:Destroy()
        else
            networked_spawnpoint:SetSpawnPointColor(data.color)
        end
    end
end)

hook.Add('ShutDown', 'SpawnpointEditor.Save', function()
    savedata:Clear()

    for k, point in ipairs(ents.FindByClass('networked_spawnpoint')) do
        local data = {
            ang = point:GetAngles(),
            color = point:GetSpawnPointColor(),
            master = point:GetIsMasterSpawnPoint()
        }

        local id = point:GetSpawnPointMapID()

        if id then
            if spawnpoint.IsUnsuitable(point:GetSpawnPointParent()) then
                data.removed = true
            end

            points.changed[id] = data
        else
            data.pos = point:GetPos()

            table.insert(points.created, data)
        end
    end

    savedata:Save()
end)

-- Commands

local function destroy_all_player_created()
    for k, point in ipairs(ents.FindByClass('networked_spawnpoint')) do
        if not point:GetSpawnPointParent() then
            point:Destroy()
        end
    end
end

concommand.Add('spawnpoint_destroy_player_created', function(ply)
    if not IsValid(ply) or ply:IsSuperAdmin() then
        destroy_all_player_created()
    end
end)

concommand.Add('spawnpoint_destroy_map_created', function(ply)
    for k, point in ipairs(ents.FindByClass('networked_spawnpoint')) do
        if point:GetSpawnPointParent() then
            point:Destroy()
        end
    end
end)

concommand.Add('spawnpoint_restore_default', function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    for k, point in ipairs(ents.FindByClass('networked_spawnpoint')) do
        local parent = point:GetSpawnPointParent()

        if parent then
            point:SetNoDraw(false)
            point:SetNoCollide(false)
            point:SetSpawnPointColor(Vector(0, 1, 0))
            point:SetAngles(point.StoredAngle)
            point:SetIsMasterSpawnPoint(point.StoredMaster)

            if point.StoredMaster then
                parent:AddSpawnFlags(spawnpoint.SF_MASTER_SPAWNPOINT)
            else
                parent:RemoveSpawnFlags(spawnpoint.SF_MASTER_SPAWNPOINT)
            end

            spawnpoint.SetUnsuitable(parent, false)
        end
    end

    points.changed = {}
end)
