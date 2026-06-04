
-- My own implementation of the PostEntityCreated hook
-- Please add this, Rubat: https://github.com/Facepunch/garrysmod-requests/issues/2506

local queue = util.Stack()

local function call_hook()
    while queue:Size() > 0 do
        local ent = queue:Pop()

        if ent:IsValid() then
            hook.Run('SpawnpointEditor.PostEntityCreated', ent)
        end
    end
end

hook.Add('OnEntityCreated', 'SpawnpointEditor.PostEntityCreated', function(ent)
    queue:Push(ent)

    timer.Create('SpawnpointEditor.PostEntityCreated', 0, 1, call_hook)
end)
