local decode = require("http-codec").decoder()
local uv = require("uv")

_G.DEBUG = function() end -- NOOP so it can be eliminated in optimized traces

local NUM_REQUESTS_TO_PARSE = 500000
local websocketsRequestString =
	"GET /chat HTTP/1.1\r\nHost: example.com:8000\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\n\r\n"
local simpleRequestString = "GET / HTTP/1.1\r\n\r\n"

-- local parser = C_Networking.IncrementalHttpRequestParser()
local ffi = require("ffi")
local ffi_new = ffi.new

-- local llhttp_init = llhttp.bindings.llhttp_init
-- local llhttp_execute = llhttp.bindings.llhttp_execute
-- local llhttp_finish = llhttp.bindings.llhttp_finish
-- local llhttp_reset = llhttp.bindings.llhttp_reset

-- local parserState = ffi_new("llhttp_t")
-- local parserSettings = ffi_new("llhttp_settings_t")
-- llhttp_init(parserState, llhttp.PARSER_TYPES.HTTP_REQUEST, parserSettings)

local pcall = pcall

local startTime = uv.hrtime()
for i = 1, NUM_REQUESTS_TO_PARSE, 1 do
	-- local R, event, extra = pcall(decode, simpleRequestString)
	local R, event, extra = pcall(decode, websocketsRequestString)
	-- llhttp_execute(parserState, websocketsRequestString, #websocketsRequestString)
	-- llhttp_finish(parserState)
	-- llhttp_reset(parserState)
	-- parser:ParseNextChunk(websocketsRequestString)
	-- parser:FinalizeBufferedRequest()
	-- parser:HTTP_MESSAGE_COMPLETE() -- HACK (TODO fix and remove)
	-- parser:ResetInternalState()
end

local endTime = uv.hrtime()
local elapsedTimeInMilliseconds = (endTime - startTime) / 10E5

local function printf(...)
	print(string.format(...))
end

printf("Parsed %d requests in %.2f ms (%.2fs)", NUM_REQUESTS_TO_PARSE, elapsedTimeInMilliseconds, elapsedTimeInMilliseconds/1000)

local numRequestsPerSecond = NUM_REQUESTS_TO_PARSE / elapsedTimeInMilliseconds *1000
printf("Requests per second: %d", numRequestsPerSecond)

local bytesPerRequest = #websocketsRequestString
local totalBytesParsed = bytesPerRequest * NUM_REQUESTS_TO_PARSE
printf("Bytes parsed: %d (%d MB)", totalBytesParsed, totalBytesParsed / (1024^2))

local bandwidthInMegabytesPerSecond = ((totalBytesParsed / (1024^2)) /  (elapsedTimeInMilliseconds/1000))
printf("Bandwith: %.2f MB/s", bandwidthInMegabytesPerSecond)
