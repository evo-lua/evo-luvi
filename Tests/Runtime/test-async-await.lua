local asyncOutputTask = coroutine.create(function()
	print("PING")
	coroutine.yield()
	print("PONG")
	coroutine.yield()
	print("PING")
	coroutine.yield()
	print("PONG")
	coroutine.yield()
	print("DONE")
	coroutine.yield()
end)

local uv = require("uv")

local currentThread = coroutine.running()
local repeatingIntervalTimer = uv.new_timer()

repeatingIntervalTimer:start(100, 10, function()
	print("Timer elapsed, continue running async task")
	-- coroutine.resume(currentThread)
	-- if task is done (coroutine is dead) then cancel timer
		if coroutine.status(asyncOutputTask) == "dead" then
			print("Async task done (coroutine is dead)")
			repeatingIntervalTimer:stop()
		else
			print("Async task is NOT done (resume it)")
			coroutine.resume(asyncOutputTask)
		end
end)
