-- TODO WSL + vcxsrv
-- export DISPLAY=$(grep nameserver /etc/resolv.conf | sed 's/nameserver //'):0

-- describe("raylib", function() end # TODO static ffi bindings, export and test like llhttp
-- TODO remove global rl, test that too..
-- TODO fix windows build, cannot test OpenGL stuff in WSL?

local raylib = {}

function raylib.load()
	local rl = require("raylib")
	-- dump(rl)
	_G.rl = nil

	return rl
	-- package.preload ... etc
end

local rl = raylib.load()
-- local rl = {}

rl.SetConfigFlags(rl.FLAG_VSYNC_HINT)

rl.InitWindow(800, 450, "raylib [core] example - basic window")

local uv = require("uv")
-- local raylibRenderLoopSignal = uv.new_signal() -- idle vs prepare? idle runs more hotly, but blocks i/o loop?

-- local raylibRenderLoopSignal = uv.new_prepare()
-- raylibRenderLoopSignal:start(function()
--   print("Before I/O polling")

--   DEBUG("RAYLIB_WINDOW_UPDATE") -- RENDER_LOOP_UPDATE
--   rl.BeginDrawing()

--   rl.ClearBackground(rl.RAYWHITE)
--   rl.DrawText("Congrats! You created your first window!", 190, 200, 20, rl.LIGHTGRAY)

--   rl.EndDrawing()
-- end)


-- local raylibRenderLoopSignal = uv.new_idle()
local raylibRenderLoopSignal = uv.new_idle()
raylibRenderLoopSignal:start(function()

	if rl.WindowShouldClose() then
		DEBUG("WINDOW_CLOSE_REQUESTED")
		rl.CloseWindow()
		DEBUG("RENDER_LOOP_SHUTDOWN")
		raylibRenderLoopSignal:stop()
	end
--   print("Before I/O polling")

  DEBUG("EVENT_LOOP_PREPARE") -- EVENT_LOOP_IDLE
  DEBUG("RAYLIB_WINDOW_UPDATE") -- RENDER_LOOP_UPDATE
  rl.BeginDrawing()

  rl.ClearBackground(rl.RAYWHITE)
  rl.DrawText("Congrats! You created your first window!", 190, 200, 20, rl.LIGHTGRAY)

  rl.EndDrawing()

  -- TODO go to sleep if above 60 FPS, it's pointless to render more often?
end)


-- while not rl.WindowShouldClose() do
	-- DEBUG("WINDOW IS NOW ACTIVE")
	-- rl.BeginDrawing()

	-- rl.ClearBackground(rl.RAYWHITE)
	-- rl.DrawText("Congrats! You created your first window!", 190, 200, 20, rl.LIGHTGRAY)

	-- rl.EndDrawing()
-- end

-- rl.CloseWindow()