local uv = require("uv")

local function assertResume(thread, ...)
    local success, err = coroutine.resume(thread, ...)
    if not success then error(debug.traceback(thread, err), 0) end
end

local function makeCallback()
    local thread = coroutine.running()
    return function(err, value, ...)
        if err then
            assertResume(thread, nil, err)
        else
            assertResume(thread, value == nil and true or value, ...)
        end
    end
end

local asyncFunctionCallingIntoC = function()
	local path = "doesNotExist" -- Doesn't matter the libuv returns, as long as it's not causing an error
    uv.fs_stat(path, makeCallback())
	print("\tpre-yield")
    return coroutine.yield()
end


-- If import uses dofile internally, this will cause a "attempt to yield across C-call boundary" error
-- since dofile is a C function and runs the compiled chunk in that context. Using loadfile internally fixes it

local result = asyncFunctionCallingIntoC() -- Simulate async fs access using await (via coroutine.yield())
print("\tpost-yield")
dump(result)