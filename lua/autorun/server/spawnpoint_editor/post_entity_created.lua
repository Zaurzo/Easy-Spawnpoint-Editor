
-- My own implementation of the PostEntityCreated hook
-- https://github.com/Facepunch/garrysmod-requests/issues/2506

local stack = util.Stack()

local function call_hook()
    while stack:Size() > 0 do
        local ent = stack:Pop()

        if ent:IsValid() then
            hook.Run('SpawnpointEditor.PostEntityCreated', ent)
        end
    end
end

hook.Add('OnEntityCreated', 'SpawnpointEditor.PostEntityCreated', function(ent)
    stack:Push(ent)

    timer.Create('SpawnpointEditor.PostEntityCreated', 0, 1, call_hook)
end)
