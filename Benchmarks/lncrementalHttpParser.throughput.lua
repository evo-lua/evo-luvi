local Benchmark = import("./Benchmark.lua")

local benchmark = Benchmark("Throughput: Lua/FFI layer on top of llhttp")

local parser
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
	parser = C_Networking.IncrementalHttpParser()
end

function benchmark:OnRun()
	local httpMessage = parser:ParseNextChunk(request)
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
