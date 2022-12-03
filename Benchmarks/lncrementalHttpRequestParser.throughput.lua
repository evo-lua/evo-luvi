local Benchmark = import("./Benchmark.lua")

local benchmark = Benchmark("Throughput: Lua-based parser on top of llhttp")

local parser
local websocketsRequestString =
	"GET /chat HTTP/1.1\r\nHost: example.com:8000\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\n\r\n"
local nodeRequest1 = "GET /wp-content/uploads/2010/03/hello-kitty-darth-vader-pink.jpg HTTP/1.1\r\n"
	.. "Host: www.kittyhell.com\r\n"
	.. "User-Agent: Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; ja-JP-mac; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 Pathtraq/0.9\r\n"
	.. "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\n"
	.. "Accept-Language: ja,en-us;q=0.7,en;q=0.3\r\n"
	.. "Accept-Encoding: gzip,deflate\r\n"
	.. "Accept-Charset: Shift_JIS,utf-8;q=0.7,*;q=0.7\r\n"
	.. "Keep-Alive: 115\r\n"
	.. "Connection: keep-alive\r\n"
	.. "Cookie: wp_ozh_wsa_visits=2; wp_ozh_wsa_visit_lasttime=xxxxxxxxxx; __utma=xxxxxxxxx.xxxxxxxxxx.xxxxxxxxxx.xxxxxxxxxx.xxxxxxxxxx.x; __utmz=xxxxxxxxx.xxxxxxxxxx.x.x.utmccn=(referral)|utmcsr=reader.livedoor.com|utmcct=/reader/|utmcmd=referral\r\n\r\n"
local nodeRequest2 = "POST /joyent/http-parser HTTP/1.1\r\n"
	.. "Host: github.com\r\n"
	.. "DNT: 1\r\n"
	.. "Accept-Encoding: gzip, deflate, sdch\r\n"
	.. "Accept-Language: ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4\r\n"
	.. "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) "
	.. "AppleWebKit/537.36 (KHTML, like Gecko) "
	.. "Chrome/39.0.2171.65 Safari/537.36\r\n"
	.. "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,"
	.. "image/webp,*/*;q=0.8\r\n"
	.. "Referer: https://github.com/joyent/http-parser\r\n"
	.. "Connection: keep-alive\r\n"
	.. "Transfer-Encoding: chunked\r\n"
	.. "Cache-Control: max-age=0\r\n\r\nb\r\nhello world\r\n0\r\n\r\n"

local request = nodeRequest2

function benchmark:OnSetup()
	self.globalDebugPrintHandler = _G.DEBUG
	_G.DEBUG = function() end -- NOOP so it can be eliminated in optimized traces

	-- self.iterationCount = 100 -- It's too slow to do much more in a reasonable timeframe

	parser = C_Networking.IncrementalHttpParser()
end

function benchmark:OnRun()
	parser:ParseNextChunk(request)

	for index=0, parser:GetNumBufferedEvents() - 1, 1 do
		local event = parser:GetBufferedEvents(index)
		parser:ReplayParserEvent(event)
	end
	-- print(event)
	-- for index, event in ipairs(events) do
	-- 	 -- Better clear the internal buffer to avoid incurring the wrath of the OOM killer...
	-- end
	parser:ClearBufferedEvents()
	-- parser:FinalizeBufferedRequest()
	-- parser:HTTP_MESSAGE_COMPLETE() -- HACK (TODO fix and remove)
	-- parser:ResetInternalState()
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

	local bytesPerRequest = #request
	local totalBytesParsed = bytesPerRequest * numIterationsPerformed
	printf("Bytes parsed: %d (%d MB)", totalBytesParsed, totalBytesParsed / (1024 ^ 2))

	local bandwidthInMegabytesPerSecond = ((totalBytesParsed / (1024 ^ 2)) / (elapsedTimeInMilliseconds / 1000))
	printf("Bandwith: %.2f MB/s", bandwidthInMegabytesPerSecond)

	_G.DEBUG = self.globalDebugPrintHandler
end

return benchmark
