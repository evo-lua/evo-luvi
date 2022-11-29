--- Container for the generic uv_stream_t APIs
local AsyncStreamMixin = {}

function AsyncStreamMixin:Shutdown()
	return self.handle:shutdown()
end

function AsyncStreamMixin:Listen(...)
	return self.handle:listen(...)
end

function AsyncStreamMixin:Accept(...)
	return self.handle:accept(...)
end

function AsyncStreamMixin:StartReading(...)
	return self.handle:read_start(...)
end

function AsyncStreamMixin:StopReading(...)
	return self.handle:read_stop(...)
end

function AsyncStreamMixin:Write(...)
	return self.handle:write(...)
end

function AsyncStreamMixin:IsReadable()
	return self.handle:is_readable()
end

function AsyncStreamMixin:IsWritable()
	return self.handle:is_writable()
end

function AsyncStreamMixin:SetBlockingMode(...)
	return self.handle:set_blocking(...)
end

function AsyncStreamMixin:GetWriteQueueSize()
	return self.handle:get_write_queue_size()
end

return AsyncStreamMixin
