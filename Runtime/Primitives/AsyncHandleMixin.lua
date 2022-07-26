--- Container for the generic uv_handle_t APIs
local AsyncHandleMixin = {}

function AsyncHandleMixin:IsActive()
	return self.handle:is_active()
end

function AsyncHandleMixin:IsClosing()
	return self.handle:is_closing()
end

function AsyncHandleMixin:Close()
	return self.handle:close()
end

function AsyncHandleMixin:Reference()
	return self.handle:ref()
end

function AsyncHandleMixin:Unreference()
	return self.handle:unref()
end

function AsyncHandleMixin:HasReference()
	return self.handle:has_ref()
end

function AsyncHandleMixin:SetReceiveBufferSize(bufferSizeInBytes)
	return self.handle:recv_buffer_size(bufferSizeInBytes)
end

function AsyncHandleMixin:GetReceiveBufferSize()
	return self.handle:recv_buffer_size()
end

function AsyncHandleMixin:SetSendBufferSize(bufferSizeInBytes)
	return self.handle:send_buffer_size(bufferSizeInBytes)
end

function AsyncHandleMixin:GetSendBufferSize()
	return self.handle:send_buffer_size()
end

function AsyncHandleMixin:GetReadOnlyFileDescriptor()
	return self.handle:fileno()
end

function AsyncHandleMixin:GetTypeInfo()
	return self.handle:handle_get_type()
end

return AsyncHandleMixin
