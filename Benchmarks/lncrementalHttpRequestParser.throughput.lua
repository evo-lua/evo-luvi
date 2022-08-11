local Benchmark = import("./Benchmark.lua")

local benchmark = Benchmark("Throughput: Lua-based parser on top of llhttp (huge overhead)")

local parser
local websocketsRequestString =
	"GET /chat HTTP/1.1\r\nHost: example.com:8000\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\n\r\n"

function benchmark:OnSetup()
	self.globalDebugPrintHandler = _G.DEBUG
	_G.DEBUG = function() end -- NOOP so it can be eliminated in optimized traces

	self.iterationCount = 100000 -- It's too slow to do much more in a reasonable timeframe

	parser = C_Networking.IncrementalHttpRequestParser()
end

function benchmark:OnRun()
	parser:ParseNextChunk(websocketsRequestString)
	parser:FinalizeBufferedRequest()
	parser:HTTP_MESSAGE_COMPLETE() -- HACK (TODO fix and remove)
	parser:ResetInternalState()
end

function benchmark:OnReport(runTimeInNanoseconds, numIterationsPerformed)
	local elapsedTimeInMilliseconds = runTimeInNanoseconds / 10E5

	printf(
		"Parsed %d requests in %.2f ms (%.2fs)",
		numIterationsPerformed,
		elapsedTimeInMilliseconds,
		elapsedTimeInMilliseconds / 1000
	)

	local numRequestsPerSecond = numIterationsPerformed / elapsedTimeInMilliseconds * 1000
	printf("Requests per second: %d", numRequestsPerSecond)

	local bytesPerRequest = #websocketsRequestString
	local totalBytesParsed = bytesPerRequest * numIterationsPerformed
	printf("Bytes parsed: %d (%d MB)", totalBytesParsed, totalBytesParsed / (1024 ^ 2))

	local bandwidthInMegabytesPerSecond = ((totalBytesParsed / (1024 ^ 2)) / (elapsedTimeInMilliseconds / 1000))
	printf("Bandwith: %.2f MB/s", bandwidthInMegabytesPerSecond)

	_G.DEBUG = self.globalDebugPrintHandler
end

return benchmark
