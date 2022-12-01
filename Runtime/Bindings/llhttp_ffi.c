// #define ENABLE_LLHTTP_CALLBACK_LOGGING 1
// #define ENABLE_LLHTTP_BUFFER_DUMPS 1

#include "llhttp.h"
#include "llhttp_ffi.h"
#include "lua.h"

#include <stdio.h>
#include "stdint.h"
#include "string.h"

static void DEBUG(const char* message) {
	#ifdef ENABLE_LLHTTP_CALLBACK_LOGGING
	printf("[C] llhttp_ffi: %s\n", message);
	#endif
}

static void DUMP(llhttp_t* parser) {
	#ifdef ENABLE_LLHTTP_BUFFER_DUMPS

	luajit_stringbuffer_reference_t* write_buffer = (luajit_stringbuffer_reference_t*)parser->data;
	if(write_buffer == NULL) return; // Nothing to debug here

	printf("\tluajit_stringbuffer_reference_t ptr: %p\n", write_buffer->ptr);
	printf("\tluajit_stringbuffer_reference_t size: %zu\n", write_buffer->size);
	printf("\tluajit_stringbuffer_reference_t used: %zu\n", write_buffer->used);
	#endif
}

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


// TODO expose via static exports, unit test in Lua

int llhttp_push_event(llhttp_t* parser, llhttp_event_t* event) {
	luajit_stringbuffer_reference_t* write_buffer = (luajit_stringbuffer_reference_t*)parser->data;

	if(write_buffer == NULL) return -1; // Probably raw llhttp-ffi call (benchmarks?), no way to store events in this case

	size_t num_bytes_required = write_buffer->used + sizeof(llhttp_event_t);
	if(num_bytes_required > write_buffer->size) {
		// Uh-oh... That should NEVER happen since we reserve more than enough space in Lua (way too much even, just to be extra safe)
		DEBUG("Failed to llhttp_push_event to the write buffer (not enough space reserved ahead of time?)");
		return num_bytes_required - write_buffer->size;
	}

	uint8_t  offset = 0;
	memcpy(write_buffer->ptr + offset, &event->event_id, sizeof(event->event_id));
	offset += sizeof(event->event_id);
	memcpy(write_buffer->ptr + offset, &event->payload_start_pointer, sizeof(event->payload_start_pointer));
	offset +=  sizeof(event->payload_start_pointer);
	memcpy(write_buffer->ptr + offset, &event->payload_length, sizeof(event->payload_length));

	 // Indicates (to LuaJIT) how many bytes need to be committed to the buffer later
	write_buffer->used+= sizeof(llhttp_event_t);

	// Don't want to overwrite the event that was just queued later...
	write_buffer->ptr += sizeof(llhttp_event_t);

	return 0;
}

#define LLHTTP_DATA_CALLBACK(event_name) \
int llhttp_##event_name(llhttp_t* parser_state, const char* at, size_t length) { \
	DEBUG(#event_name); \
\
	llhttp_event_t event = { event_name, at, length}; \
	llhttp_push_event(parser_state, &event); \
\
	DUMP(parser_state); \
\
	return HPE_OK; \
} \

#define LLHTTP_INFO_CALLBACK(event_name) \
int llhttp_##event_name(llhttp_t* parser_state) { \
	DEBUG(#event_name); \
\
	llhttp_event_t event = { event_name, 0, 0}; \
	llhttp_push_event(parser_state, &event); \
\
	DUMP(parser_state); \
\
	return HPE_OK; \
} \

LLHTTP_INFO_CALLBACK(on_chunk_complete)
LLHTTP_INFO_CALLBACK(on_header_value_complete)
LLHTTP_INFO_CALLBACK(on_message_complete)
LLHTTP_INFO_CALLBACK(on_chunk_header)
LLHTTP_INFO_CALLBACK(on_message_begin)
LLHTTP_INFO_CALLBACK(on_headers_complete)
LLHTTP_INFO_CALLBACK(on_status_complete)
LLHTTP_INFO_CALLBACK(on_method_complete)
LLHTTP_INFO_CALLBACK(on_version_complete)
LLHTTP_INFO_CALLBACK(on_header_field_complete)
LLHTTP_INFO_CALLBACK(on_chunk_extension_name_complete)
LLHTTP_INFO_CALLBACK(on_chunk_extension_value_complete)
LLHTTP_INFO_CALLBACK(on_url_complete)
LLHTTP_INFO_CALLBACK(on_reset)

LLHTTP_DATA_CALLBACK(on_url)
LLHTTP_DATA_CALLBACK(on_status)
LLHTTP_DATA_CALLBACK(on_method)
LLHTTP_DATA_CALLBACK(on_version)
LLHTTP_DATA_CALLBACK(on_chunk_extension_name)
LLHTTP_DATA_CALLBACK(on_chunk_extension_value)
LLHTTP_DATA_CALLBACK(on_header_field)
LLHTTP_DATA_CALLBACK(on_header_value)
LLHTTP_DATA_CALLBACK(on_body)

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

	settings->on_message_begin = llhttp_on_message_begin;
	settings->on_url = llhttp_on_url;
	settings->on_status = llhttp_on_status;
	settings->on_method = llhttp_on_method;
	settings->on_version = llhttp_on_version;
	settings->on_header_field = llhttp_on_header_field;
	settings->on_header_value = llhttp_on_header_value;
	settings->on_chunk_extension_name = llhttp_on_chunk_extension_name;
	settings->on_chunk_extension_value = llhttp_on_chunk_extension_value;
	settings->on_headers_complete = llhttp_on_headers_complete;
	settings->on_body = llhttp_on_body;
	settings->on_message_complete = llhttp_on_message_complete;
	settings->on_url_complete = llhttp_on_url_complete;
	settings->on_status_complete = llhttp_on_status_complete;
	settings->on_method_complete = llhttp_on_method_complete;
	settings->on_version_complete = llhttp_on_version_complete;
	settings->on_header_field_complete = llhttp_on_header_field_complete;
	settings->on_header_value_complete = llhttp_on_header_value_complete;
	settings->on_chunk_extension_name_complete = llhttp_on_chunk_extension_name_complete;
	settings->on_chunk_extension_value_complete = llhttp_on_chunk_extension_value_complete;
	settings->on_chunk_header = llhttp_on_chunk_header;
	settings->on_chunk_complete = llhttp_on_chunk_complete;
	settings->on_reset = llhttp_on_reset;
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

	// This wrapper must be bound to the llhttp namespace on initialization from Lua, in place of the dynamic binding (.so/.dll load)
	lua_getglobal(L, "STATIC_FFI_EXPORTS");
	lua_pushlightuserdata(L, &llhttp_exports_table);
	lua_setfield(L, -2, "llhttp");
}