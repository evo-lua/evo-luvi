#include "llhttp.h"
// TODO remove printf
#include <stdio.h>

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

struct http_request {
};

struct http_response {
};

struct http_message {
};

// int (*llhttp_data_cb)(llhttp_t* parser_state, const char *at, size_t length);

// Note: Parameters at & length are useless for llhttp_cb, do not use them in non-llhttp_data_cb callbacks
// llhttp info callbacks
int on_header_value_complete(llhttp_t* parser_state, const char* at, size_t length)
{
	printf("[C] llhttp called on_header_value_complete with token %.*s\n", length, at);

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

int on_message_complete(llhttp_t* parser_state, const char* at, size_t length)
{
	printf("[C] llhttp called on_message_complete with token %.*s\n", length, at);
	// DEBUG("[IncrementalHttpRequestParser] HTTP_MESSAGE_COMPLETE triggered")
	// self.isBufferReady = true

	// local methodName = llhttp_method_name(self.state.method)
	// self.bufferedRequest.method:set(ffi_string(methodName))

	// self.bufferedRequest.versionString:set(format("HTTP/%d.%d", self.state.http_major, self.state.http_minor))
	return HPE_OK;
}

// llhttp data callbacks
int on_url(llhttp_t* parser_state, const char* at, size_t length)
{
	printf("[C] llhttp called on_url with token %.*s\n", length, at);
	// self.bufferedRequest.requestedURL:put(parsedString)
	return HPE_OK;
}

int on_status(llhttp_t* parser_state, const char* at, size_t length)
{
	printf("[C] llhttp called on_status with token %.*s\n", length, at);
	// self.bufferedRequest.requestedURL:put(parsedString)
	return HPE_OK;
}

int on_header_field(llhttp_t* parser_state, const char* at, size_t length)
{
	printf("[C] llhttp called on_header_field with token %.*s\n", length, at);
	// self.lastReceivedHeaderKey:put(parsedString)
	return HPE_OK;
}

int on_header_value(llhttp_t* parser_state, const char* at, size_t length)
{
	printf("[C] llhttp called on_header_value with token %.*s\n", length, at);
	// self.lastReceivedHeaderValue:put(parsedString)
	return HPE_OK;
}

int on_body(llhttp_t* parser_state, const char* at, size_t length)
{
	// self.bufferedRequest.body:put(parsedString)
	printf("[C] llhttp called on_body with token %.*s\n", length, at);
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
	printf("Initializing llhttp settings with callbacks...\n"); // TODO remove
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
	llhttp_exports_table.llhttp_get_error_pos = llhttp_get_error_pos;
	llhttp_exports_table.llhttp_errno_name = llhttp_errno_name;
	llhttp_exports_table.llhttp_method_name = llhttp_method_name;
	llhttp_exports_table.llhttp_set_lenient_headers = llhttp_set_lenient_headers;
	llhttp_exports_table.llhttp_set_lenient_chunked_length = llhttp_set_lenient_chunked_length;
	llhttp_exports_table.llhttp_set_lenient_keep_alive = llhttp_set_lenient_keep_alive;

	lua_getglobal(L, "STATIC_FFI_EXPORTS");
	lua_pushlightuserdata(L, &llhttp_exports_table);
	lua_setfield(L, -2, "llhttp");
}