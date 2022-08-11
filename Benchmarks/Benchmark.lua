local uv = require("uv")
local bold = transform.bold

local Benchmark = {
	label = "<no label>",
	iterationCount = 10000000,
}

function Benchmark:Construct(label)
	local instance = {}

	if type(label) == "string" then
		instance.label = label
	end

	setmetatable(instance, self)

	return instance
end

Benchmark.__index = Benchmark
Benchmark.__call = Benchmark.Construct
setmetatable(Benchmark, Benchmark)

function Benchmark:Start(numIterations)

	self:OnSetup()

	numIterations = numIterations or self.iterationCount
	printf("Starting benchmark %s for %d iterations ", bold(self.label), numIterations)

	local startTime = uv.hrtime()
	for i = 1, numIterations, 1 do
		self:OnRun()
	end
	local endTime = uv.hrtime()

	self:OnReport(endTime - startTime, numIterations)

	return true
end

function Benchmark:OnSetup() end
function Benchmark:OnRun() end
function Benchmark:OnReport() end

return Benchmark