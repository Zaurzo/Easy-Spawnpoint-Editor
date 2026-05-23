
-- My own implementation of the PostEntityCreated hook
-- Please add this, Rubat: https://github.com/Facepunch/garrysmod-requests/issues/2506

local entity_queue = {}

local function call_hook()
    while #entity_queue > 0 do
        local ent = table.remove(entity_queue, 1)

        if ent:IsValid() then
            hook.Run('SpawnpointEditor.PostEntityCreated', ent)
        end
    end
end

hook.Add('OnEntityCreated', 'SpawnpointEditor.PostEntityCreated', function(ent)
    table.insert(entity_queue, ent)

    timer.Create('SpawnpointEditor.PostEntityCreated', 0, 1, call_hook)
end)