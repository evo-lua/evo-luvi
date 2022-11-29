local TcpClient = {}

local coroutine_yield = coroutine.yield
local coroutine_running = coroutine.running
local coroutine_wrap = coroutine.wrap
local coroutine_resume = coroutine.resume

local AsyncTaskMixin = {}

function AsyncTaskMixin:Async()
	DEBUG("Scheduling async task for thread " .. coroutine_running())
	self.thread = coroutine_running()
end

mixin(TcpClient, AsyncTaskMixin)

function TcpClient:Write(chunk)
	-- self:Async()

	TcpClient:StartWriting(chunk, function()
		-- TcpClient:OnResume()
	end)

	coroutine_yield()
end

function TcpClient:StartWriting(chunk, onCompletionCallback)
	DEBUG("Queueing chunk " .. chunk)

	local currentThread = coroutine_running()

	local uv = require("uv")
	local fakeWriteTimer = uv.new_timer()
	fakeWriteTimer:start(1000, 0, function()
		DEBUG("Chunk written: " .. chunk)
		coroutine_resume(currentThread)
	end)
	-- coroutine_yield()

end

local function AWAIT(task, ...)
	local currentThread = coroutine_running()

	DEBUG("Scheduling async task in " .. tostring(currentThread))
	local asyncTask = coroutine_wrap(function(...)
		DEBUG("Starting async task in " .. tostring(coroutine_running()))
		task(task, ...)
		DEBUG("Completed async task in " .. tostring(coroutine_running()))
	end)

	asyncTask(...)

	DEBUG("Awaiting completion of async task in " .. tostring(currentThread))
	coroutine_yield()
end

local chunk = "Hello world"
AWAIT(TcpClient.StartWriting, chunk)

DEBUG("All done, shutting down event loop")

return TcpClient