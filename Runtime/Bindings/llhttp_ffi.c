#include "llhttp.h"
#include "lua.h"

#include <stdio.h>
#include "stdint.h" // for uint8_t * (LuaJIT FFI return value for string_buffer.ref)
#include "inttypes.h" // PRIu8 macro (can remove later)

#include <lj_buf.h>

#define ENABLE_LLHTTP_CALLBACK_LOGGING 1

static void DEBUG(char* message) {
	#ifdef ENABLE_LLHTTP_CALLBACK_LOGGING
	printf("[C] llhttp_ffi: %s\n", message);
	#endif
}

// typedef SBuf LuaJIT_StringBuffer;

// Must use a LuaJIT string buffer's writable area directly since Lua cannot pass the SBuf pointer via FFI (AFAIK...)
struct lj_writebuffer {
	size_t size;
	uint8_t * ptr; // buffer_area_start
	size_t used;
};
typedef struct lj_writebuffer lj_writebuffer_t;

struct static_llhttp_exports_table {
	void (*llhttp_init)(llhttp_t* parser, llhttp_type_t type, const llhttp_settings_t* settings);
	void (*llhttp_reset)(llhttp_t* parser);
	void (*llhttp_settings_init)(llhttp_settings_t* settings);
	llhttp_errno_t (*llhttp_execute)(llhttp_t* parser, const char* data, size_t len);
	llhttp_errno_t (*llhttp_finish)(llhttp_t* parser);
	int (*llhttp_message_needs_eof)(const llhttp_t* parser);
	int (*llhttp_should_keep_alive)(const llhttp_t* parser);
	void (*llhttp_pause)(llhttp_t* parser);
	void (*llhttp_resume)(llhttp_t* parser);
	void (*llhttp_resume_after_upgrade)(llhttp_t* parser);
	llhttp_errno_t (*llhttp_get_errno)(const llhttp_t* parser);
	const char* (*llhttp_get_error_reason)(const llhttp_t* parser);
	void (*llhttp_set_error_reason)(llhttp_t* parser, const char* reason);
	const char* (*llhttp_get_error_pos)(const llhttp_t* parser);
	const char* (*llhttp_errno_name)(llhttp_errno_t err);
	const char* (*llhttp_method_name)(llhttp_method_t method);
	void (*llhttp_set_lenient_headers)(llhttp_t* parser, int enabled);
	void (*llhttp_set_lenient_chunked_length)(llhttp_t* parser, int enabled);
	void (*llhttp_set_lenient_keep_alive)(llhttp_t* parser, int enabled);
};

// TODO Add the missing callbacks (llhttp added a few new ones)

// llhttp info callbacks
int on_header_value_complete(llhttp_t* parser_state)
{
	DEBUG("on_header_value_complete");
	// printf("[C] llhttp called on_header_value_complete with token %.*s\n", length, at);

	// local fieldName = tostring(self.lastReceivedHeaderKey)
	// local fieldValue = tostring(self.lastReceivedHeaderValue)
	// DEBUG(format("Storing received header pair - %s: %s", fieldName, fieldValue))
	// self.bufferedRequest.headers[fieldName] = fieldValue

	// -- This is somewhat redundant, but allows serializing headers in the exact order they were received later
	// -- .All the while, also preserving the ability to perform dictionary lookups (constant-time + ease-of-use)
	// self.bufferedRequest.headers[#self.bufferedRequest.headers + 1] = fieldName

	// -- Reset buffer so the next key-value-pair can be stored
	// self.lastReceivedHeaderKey:reset()
	// self.lastReceivedHeaderValue:reset()
	return HPE_OK;
}

int on_message_complete(llhttp_t* parser_state)
{

	DEBUG("on_message_complete");

	// printf("[C] llhttp called on_message_complete with token %.*s\n", length, at);
	//  DEBUG("[IncrementalHttpRequestParser] HTTP_MESSAGE_COMPLETE triggered")
	//  self.isBufferReady = true

	// local methodName = llhttp_method_name(self.state.method)
	// self.bufferedRequest.method:set(ffi_string(methodName))

	// self.bufferedRequest.versionString:set(format("HTTP/%d.%d", self.state.http_major, self.state.http_minor))
	return HPE_OK;
}

// llhttp data callbacks
int on_url(llhttp_t* parser_state, const char* at, size_t length)
{

	DEBUG("on_url");

	// printf("[C] llhttp called on_url with token %.*s\n", length, at);
	// //  self.bufferedRequest.requestedURL:put(parsedString)
	// http_request* buffered_request = (http_request*)parser_state->data;

	lj_writebuffer_t* write_buffer = (lj_writebuffer_t*)parser_state->data;
	printf("lj_writebuffer_t ptr: %p\n", write_buffer->ptr);
	printf("lj_writebuffer_t size: %zu\n", write_buffer->size);
	// lj_buf_putmem( (LuaJIT_StringBuffer*) parser_state->data, "on_url#", strlen("on_url#"));
	// lj_buf_putmem(write_buffer, at, length);
	// We need to get this data into Lua without using callbacks... this isn't great, but I haven't found a more efficient way yet
	// I'd love to do zero-copy somehow, but since we want Lua tables at the other end that's probably impossible anyway?
	// As long as this doesn't incur the same 20-50x slowdown as using C->Lua callbacks it might be fine, for now...
	if(length > write_buffer->size) {
		// Uh-oh... That should NEVER happen since we reserve more than enough space in Lua (WAY too much even, just to be extra safe)
		DEBUG("Failed to memcpy on_url data to write buffer (not enough space reserved in Lua?)");
	} else
	{
		// TODO also write event ID and separator so we can replay the events in Lua
		memcpy(write_buffer->ptr, at, length);
		write_buffer->used+= length; // Indicates (to LuaJIT) how many bytes need to be committed to the buffer later
	}

	// printf("lj)buf_putmem done\n");

	return HPE_OK;
}

int on_status(llhttp_t* parser_state, const char* at, size_t length)
{

	DEBUG("on_status");

	printf("[C] llhttp called on_status with token %.*s\n", length, at);
	//  self.bufferedRequest.requestedURL:put(parsedString)
	return HPE_OK;
}

int on_header_field(llhttp_t* parser_state, const char* at, size_t length)
{
	printf("[C] llhttp called on_header_field with token %.*s\n", length, at);
	//  self.lastReceivedHeaderKey:put(parsedString)
	return HPE_OK;
}

int on_header_value(llhttp_t* parser_state, const char* at, size_t length)
{
	printf("[C] llhttp called on_header_value with token %.*s\n", length, at);
	//  self.lastReceivedHeaderValue:put(parsedString)
	return HPE_OK;
}

static int on_body(llhttp_t* parser_state, const char* at, size_t length)
{
	// self.bufferedRequest.body:put(parsedString)
	printf("[C] llhttp called on_body with token %.*s\n", (int)length, at);


	return HPE_OK;
}

#define EXPAND_AS_STRING(text) #text
#define TOSTRING(text) EXPAND_AS_STRING(text)
#define LLHTTP_VERSION_STRING      \
	TOSTRING(LLHTTP_VERSION_MAJOR) \
	"." TOSTRING(LLHTTP_VERSION_MINOR) "." TOSTRING(LLHTTP_VERSION_PATCH)

const char* llhttp_get_version_string(void)
{
	return LLHTTP_VERSION_STRING;
}

static void init_settings_with_callbacks(llhttp_settings_t* settings)
{
	DEBUG("init_settings_with_callbacks");

	llhttp_settings_init(settings);

	// Set up info callbacks
	settings->on_header_value_complete = on_header_value_complete;
	settings->on_message_complete = on_message_complete;

	// Set up data callbacks
	settings->on_url = on_url;
	settings->on_status = on_status;
	settings->on_header_field = on_header_field;
	settings->on_header_value = on_header_value;
	settings->on_body = on_body;
}

void export_llhttp_bindings(lua_State* L)
{
	static struct static_llhttp_exports_table llhttp_exports_table;
	llhttp_exports_table.llhttp_init = llhttp_init;
	llhttp_exports_table.llhttp_reset = llhttp_reset;
	llhttp_exports_table.llhttp_settings_init = init_settings_with_callbacks;
	llhttp_exports_table.llhttp_execute = llhttp_execute;
	llhttp_exports_table.llhttp_finish = llhttp_finish;
	llhttp_exports_table.llhttp_message_needs_eof = llhttp_message_needs_eof;
	llhttp_exports_table.llhttp_should_keep_alive = llhttp_should_keep_alive;
	llhttp_exports_table.llhttp_pause = llhttp_pause;
	llhttp_exports_table.llhttp_resume = llhttp_resume;
	llhttp_exports_table.llhttp_resume_after_upgrade = llhttp_resume_after_upgrade;
	llhttp_exports_table.llhttp_get_errno = llhttp_get_errno;
	llhttp_exports_table.llhttp_get_error_reason = llhttp_get_error_reason;
	llhttp_exports_table.llhttp_set_error_reason = llhttp_set_error_reason;
	llhttp_exports_table.llhttp_get_error_pos = llhttp_get_error_pos;
	llhttp_exports_table.llhttp_errno_name = llhttp_errno_name;
	llhttp_exports_table.llhttp_method_name = llhttp_method_name;
	llhttp_exports_table.llhttp_set_lenient_headers = llhttp_set_lenient_headers;
	llhttp_exports_table.llhttp_set_lenient_chunked_length = llhttp_set_lenient_chunked_length;
	llhttp_exports_table.llhttp_set_lenient_keep_alive = llhttp_set_lenient_keep_alive;
	// llhttp_exports_table.luaState = L;

	lua_getglobal(L, "STATIC_FFI_EXPORTS"); // TODO This will seem like a hack to anyone who hasn't read Mike Pall's post? Document it...
	lua_pushlightuserdata(L, &llhttp_exports_table);
	lua_setfield(L, -2, "llhttp");
}