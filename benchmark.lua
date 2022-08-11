local benchmarks = {
	"./Benchmarks/llhttp-ffi.throughput.lua",
	"./Benchmarks/lncrementalHttpRequestParser.throughput.lua",
}

for _, filePath in pairs(benchmarks) do
	local benchmark = import(filePath)
	-- For CI pipelines and scripts, ensure the return code indicates EXIT_FAILURE if at least one assertion has failed
	assert(benchmark:Start(), "Assertion failure in benchmark " .. filePath)
end
