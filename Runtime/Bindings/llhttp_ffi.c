// #define ENABLE_LLHTTP_CALLBACK_LOGGING 1
// #define ENABLE_LLHTTP_BUFFER_DUMPS 1

#include "llhttp.h"
#include "lua.h"

#include <stdio.h>
#include "stdint.h" // for uint8_t * (LuaJIT FFI return value for string_buffer.ref)
#include "inttypes.h" // PRIu8 macro (can remove later)

#include <lj_buf.h>

// We require one event per llhttp_settings callback, plus one extra (ID is 0) for the "hopefully impossible" error case
// (not enough bytes reserved in the LuaJIT string buffer prior to registering the callbacks
//  -> just another safeguard, even if it's probably not needed
enum llhttp_events { // TBD explicit indexing or just use defaults?
	llhttp_ffi_on_buffer_too_small = 0, // Need to buffer.reserve MORE bytes before calling llhttp_execute (in Lua)
	// This has the added bonus of cleanly mapping Lua indices to enum values, since Lua normally starts at 1, and not 0
	llhttp_ffi_on_message_begin = 1,
	llhttp_ffi_on_url = 2,
	llhttp_ffi_on_status = 3,
	llhttp_ffi_on_method = 4,
	llhttp_ffi_on_version = 5,
	llhttp_ffi_on_header_field = 6,
	llhttp_ffi_on_header_value = 7,
	llhttp_ffi_on_chunk_extension_name = 8,
	llhttp_ffi_on_chunk_extension_value = 9,
	llhttp_ffi_on_headers_complete = 10,
	llhttp_ffi_on_body = 11,
	llhttp_ffi_on_message_complete = 12,
	llhttp_ffi_on_url_complete = 13,
	llhttp_ffi_on_status_complete = 14,
	llhttp_ffi_on_method_complete = 15,
	llhttp_ffi_on_version_complete = 16,
	llhttp_ffi_on_header_field_complete = 17,
	llhttp_ffi_on_header_value_complete = 18,
	llhttp_ffi_on_chunk_extension_name_complete = 19,
	llhttp_ffi_on_chunk_extension_value_complete = 20,
	llhttp_ffi_on_chunk_header = 21,
	llhttp_ffi_on_chunk_complete = 22,
	llhttp_ffi_on_reset = 23,
};

// Since we can't trigger Lua events directly without murdering performance, store the relevant info and fetch it from Lua later
// Note: Since only data_callbacks (llhttp_data_cb) have a payload, store (0, 0) for info-only callbacks (llhttp_cb)
struct llhttp_event {
	uint8_t event_id;
	const char* payload_start_pointer;
	size_t payload_length;
};
typedef struct llhttp_event llhttp_event_t;

// This is a bit unfortunate, but in order to store events we rely on LuaJIT to manage the buffer
//  Lua MUST reserve enough bytes ahead of time so that even in a worst-case scenario of
// '1 event per character in the processed chunk' ALL events fit inside the buffer (i.e., #chunk * sizeof(llhttp_event) space is needed)
// It's somewhat wasteful because it's VERY defensive, but unless gigantic payloads arrive the overhead shouldn't matter too much?
// (and those should be blocked from Lua already/the client DCed or whatever, via configurable parameters on the Lua side)
// Note: Have to use the buffer's writable area directly since Lua cannot pass the SBuf pointer via FFI (AFAIK...),
// nor can we pass the Lua state to create new buffers here (which would also be more complicated and error-prone)
struct lj_writebuffer {
	size_t size;
	uint8_t * ptr; // buffer_area_start
	size_t used;
};
typedef struct lj_writebuffer lj_writebuffer_t;
// TODO Move structs to .h

static void DEBUG(char* message) {
	#ifdef ENABLE_LLHTTP_CALLBACK_LOGGING
	printf("[C] llhttp_ffi: %s\n", message);
	#endif
}

static void DUMP(llhttp_t* parser) {
	#ifdef ENABLE_LLHTTP_BUFFER_DUMPS

	lj_writebuffer_t* write_buffer = (lj_writebuffer_t*)parser->data;
	if(write_buffer == NULL) return; // Nothing to debug here

	printf("\tlj_writebuffer_t ptr: %p\n", write_buffer->ptr);
	printf("\tlj_writebuffer_t size: %zu\n", write_buffer->size);
	printf("\tlj_writebuffer_t used: %zu\n", write_buffer->used);
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
	lj_writebuffer_t* write_buffer = (lj_writebuffer_t*)parser->data;

	if(write_buffer == NULL) return -1; // Probably raw llhttp-ffi call (benchmarks?), no way to store events in this case

	size_t num_bytes_required = write_buffer->used + event->payload_length;
	if(num_bytes_required > write_buffer->size) {
		// Uh-oh... That should NEVER happen since we reserve more than enough space in Lua (WAY too much even, just to be extra safe)
		DEBUG("Failed to llhttp_push_event to the write buffer (not enough space reserved ahead of time?)");
		// TODO set first event to error, ignore rest?
		return num_bytes_required - write_buffer->size;
	}

	// We don't care to store the diff (from buffer start to payload start) since we can pass these parameters to LuaJIT's ffi.string()
	// TBD adding padding for 32/64 alignment? needs benchmark
	// TODO copy normally vs memcpy (overhead)?
	memcpy(write_buffer->ptr, &event->event_id, sizeof(event->event_id));
	memcpy(write_buffer->ptr, &event->payload_start_pointer, sizeof(event->payload_start_pointer));
	memcpy(write_buffer->ptr, &event->payload_length, sizeof(event->payload_length));
	write_buffer->used+= sizeof(llhttp_event_t); // Indicates (to LuaJIT) how many bytes need to be committed to the buffer later

	return 0;
}


// TODO rename parser_state to parser everywhere
// TODO Add the missing callbacks (llhttp added a few new ones)

// llhttp info callbacks
int on_header_value_complete(llhttp_t* parser_state)
{
	DEBUG("on_header_value_complete");

	llhttp_event_t event = { llhttp_ffi_on_header_value_complete, 0, 0};
	llhttp_push_event(parser_state, &event);

	DUMP(parser_state);

	return HPE_OK;
}

int on_message_complete(llhttp_t* parser_state)
{
	DEBUG("on_message_complete");

	llhttp_event_t event = { llhttp_ffi_on_message_complete, 0, 0};
	llhttp_push_event(parser_state, &event);

	DUMP(parser_state);
	return HPE_OK;
}

// llhttp data callbacks
int on_url(llhttp_t* parser_state, const char* at, size_t length)
{
	DEBUG("on_url");

	llhttp_event_t event = { llhttp_ffi_on_url, at, length };
	llhttp_push_event(parser_state, &event);

	DUMP(parser_state);

	return HPE_OK;
}

int on_status(llhttp_t* parser_state, const char* at, size_t length)
{
	DEBUG("on_status");

	llhttp_event_t event = { llhttp_ffi_on_status, at, length };
	llhttp_push_event(parser_state, &event);

	DUMP(parser_state);

	return HPE_OK;
}

int on_header_field(llhttp_t* parser_state, const char* at, size_t length)
{
	DEBUG("on_header_field");

	llhttp_event_t event = { llhttp_ffi_on_header_field, at, length };
	llhttp_push_event(parser_state, &event);

	DUMP(parser_state);

	return HPE_OK;
}

int on_header_value(llhttp_t* parser_state, const char* at, size_t length)
{
	DEBUG("on_header_value");

	llhttp_event_t event = { llhttp_ffi_on_header_value, at, length };
	llhttp_push_event(parser_state, &event);

	DUMP(parser_state);

	return HPE_OK;
}

static int on_body(llhttp_t* parser_state, const char* at, size_t length)
{
	DEBUG("on_body");

	llhttp_event_t event = { llhttp_ffi_on_body, at, length };
	llhttp_push_event(parser_state, &event);

	DUMP(parser_state);

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

	// TODO register callbacks for all of them (and create handlers, too)
	// llhttp_ffi_on_message_begin = 1,
	// llhttp_ffi_on_url = 2,
	// llhttp_ffi_on_status = 3,
	// llhttp_ffi_on_method = 4,
	// llhttp_ffi_on_version = 5,
	// llhttp_ffi_on_header_field = 6,
	// llhttp_ffi_on_header_value = 7,
	// llhttp_ffi_on_chunk_extension_name = 8,
	// llhttp_ffi_on_chunk_extension_value = 9,
	// llhttp_ffi_on_headers_complete = 10,
	// llhttp_ffi_on_body = 11,
	// llhttp_ffi_on_message_complete = 12,
	// llhttp_ffi_on_url_complete = 13,
	// llhttp_ffi_on_status_complete = 14,
	// llhttp_ffi_on_method_complete = 15,
	// llhttp_ffi_on_version_complete = 16,
	// llhttp_ffi_on_header_field_complete = 17,
	// llhttp_ffi_on_header_value_complete = 18,
	// llhttp_ffi_on_chunk_extension_name_complete = 19,
	// llhttp_ffi_on_chunk_extension_value_complete = 20,
	// llhttp_ffi_on_chunk_header = 21,
	// llhttp_ffi_on_chunk_complete = 22,
	// llhttp_ffi_on_reset = 23,

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