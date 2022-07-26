--- Container for the generic uv_tcp_t APIs
local AsyncSocketMixin = {}

function AsyncSocketMixin:Open(...)
	return self.handle:open(...)
end

function AsyncSocketMixin:SetNoDelay(...)
	return self.handle:nodelay(...)
end

function AsyncSocketMixin:SetKeepAlive(...)
	return self.handle:keepalive(...)
end

function AsyncSocketMixin:SetMultiAcceptMode(...)
	return self.handle:simultaneous_accepts(...)
end

function AsyncSocketMixin:Bind(...)
	return self.handle:bind(...)
end

function AsyncSocketMixin:GetPeerName()
	return self.handle:getpeername()
end

function AsyncSocketMixin:GetSocketName()
	return self.handle:getsockname()
end

function AsyncSocketMixin:Connect(...)
	return self.handle:connect(...)
end

function AsyncSocketMixin:SetWriteQueueSize()
	return self.handle:write_queue_size()
end

function AsyncSocketMixin:Reset()
	return self.handle:close_reset()
end

return AsyncSocketMixin
