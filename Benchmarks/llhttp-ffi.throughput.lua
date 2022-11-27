local Benchmark = import("./Benchmark.lua")

local benchmark = Benchmark("Throughput: Raw llhttp calls via FFI (minimal overhead)")

local ffi = require("ffi")
local ffi_new = ffi.new
local buffer = require("string.buffer")

local llhttp = require("llhttp")
local llhttp_init = llhttp.bindings.llhttp_init
local llhttp_settings_init = llhttp.bindings.llhttp_settings_init
local llhttp_execute = llhttp.bindings.llhttp_execute
local llhttp_finish = llhttp.bindings.llhttp_finish
local llhttp_reset = llhttp.bindings.llhttp_reset

local parserState
local websocketsRequestString =
	"GET /chat HTTP/1.1\r\nHost: example.com:8000\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\n\r\n"

function benchmark:OnSetup()
	self.globalDebugPrintHandler = _G.DEBUG
	_G.DEBUG = function() end -- NOOP so it can be eliminated in optimized traces

	parserState = ffi_new("llhttp_t")
	local parserSettings = ffi_new("llhttp_settings_t")
	llhttp_settings_init(parserSettings)
	llhttp_init(parserState, llhttp.PARSER_TYPES.HTTP_REQUEST, parserSettings)
	parserState.data = buffer.new()
end

function benchmark:OnRun()
	llhttp_execute(parserState, websocketsRequestString, #websocketsRequestString)
	llhttp_finish(parserState)
	llhttp_reset(parserState)
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
