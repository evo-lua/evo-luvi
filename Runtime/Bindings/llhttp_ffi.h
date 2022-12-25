#pragma once

#include "llhttp.h"
#include "lua.h"

#include <stdint.h>
#include <stdbool.h>

enum llhttp_events {
	on_buffer_too_small = 0, // Need to buffer.reserve MORE bytes before calling llhttp_execute (in Lua)
	// This has the added bonus of cleanly mapping Lua indices to enum values, since Lua normally starts at 1, and not 0
	on_message_begin = 1,
	on_url = 2,
	on_status = 3,
	on_method = 4,
	on_version = 5,
	on_header_field = 6,
	on_header_value = 7,
	on_chunk_extension_name = 8,
	on_chunk_extension_value = 9,
	on_headers_complete = 10,
	on_body = 11,
	on_message_complete = 12,
	on_url_complete = 13,
	on_status_complete = 14,
	on_method_complete = 15,
	on_version_complete = 16,
	on_header_field_complete = 17,
	on_header_value_complete = 18,
	on_chunk_extension_name_complete = 19,
	on_chunk_extension_value_complete = 20,
	on_chunk_header = 21,
	on_chunk_complete = 22,
	on_reset = 23,
};

// We rely on the bytes to be laid out exactly as specified so that LuaJIT can map them 1:1 (and it saves a lot of space)
// The alignment shouldn't really matter because we read the entire buffer in order when replaying (or storing) events...
// But if the compiler inserts padding bytes, they will be pointlessly encoded in the event buffer = useless bloat
#pragma pack(1)

// Since we can't trigger Lua callbacks directly without murdering performance, save the relevant info and fetch it from Lua later
// Only data_callbacks (llhttp_data_cb) have a payload, so let's store (0, 0) for info-only callbacks (llhttp_cb)
struct llhttp_event {
	uint8_t event_id;
	const char* payload_start_pointer;
	size_t payload_length;
};
typedef struct llhttp_event llhttp_event_t;

// This represents the string buffer's writable area since Lua cannot directly pass the SBuf pointer via FFI (AFAIK), nor the Lua state
// The FFI bindings just write to it, assuming plenty of space has been reserved ahead of time (somewhat wasteful, but should be safe)
struct luajit_stringbuffer_reference {
	size_t size;
	uint8_t* ptr;
	size_t used;
};
typedef struct luajit_stringbuffer_reference luajit_stringbuffer_reference_t;


	// -- llhttp_userdata_stringbuffer_allocate
	// -- llhttp_userdata_get_required_size
	// -- llhttp_userdata_get_actual_size
	// -- llhttp_userdata_message_fits_buffer

	// -- llhttp_userdata_reset
	// -- llhttp_userdata_is_message_complete
	// -- llhttp_userdata_is_overflow_error
	// -- llhttp_userdata_is_streaming_body
	// -- llhttp_userdata_get_body_tempfile_path
	// -- lhttp_userdata_is_buffering_body

	// -- llhttp_userdata_get_max_url_size
	// -- llhttp_userdata_get_max_reason_size
	// -- llhttp_userdata_get_max_body_size
	// -- llhttp_userdata_get_max_header_field_size
	// -- llhttp_userdata_get_max_header_value_size
	// -- llhttp_userdata_get_max_headers_array_size
	// -- llhttp_userdata_debug_dump

	// stringbuffer_read_counted_string(ptr, len)

// struct counted_string {
// 	size_t length;

// };
// typedef struct counted_string counted_string_t;

// struct dynamic_message_buffer {
// 	bool is_message_complete;
// 	uint8_t num_version_bytes_used;

// };
// typedef struct dynamic_message_buffer message_buffer_t;

// struct llhttp_userdata {
// 	luajit_stringbuffer_t message_buffer;
// };
// typedef struct llhttp_userdata llhttp_userdata_t;

typedef struct llhttp_userdata_header {
	// version, method, status_code, is_upgrade: stored by llhttp
	// url, reason, headers, body, is_complete: stored by us

	// Adjusted based on input (set by the llhttp-ffi glue code, in C)
	bool is_message_complete;

	size_t url_relative_offset;
	size_t reason_relative_offset;
	size_t headers_relative_offset;
	size_t body_relative_offset;

	size_t url_length;
	size_t reason_length;
	size_t num_headers;
	size_t body_length;

	// Configurable (set by llhttp-ffi API calls, in Lua)
	size_t max_url_length;
	size_t max_reason_length;
	size_t max_num_headers;
	size_t max_header_field_length;
	size_t max_header_value_length;
	size_t max_body_length;

} llhttp_userdata_header_t;

typedef struct llhttp_userdata {
	llhttp_userdata_header_t header;
	luajit_stringbuffer_reference_t buffer;
} llhttp_userdata_t;

// A thin wrapper for the llhttp API, only needed to expose the statically-linked llhttp symbols to Lua and load them via FFI
struct static_llhttp_exports_table {
	void (*llhttp_init)(llhttp_t* parser, llhttp_type_t type, const llhttp_settings_t* settings);
	void (*llhttp_reset)(llhttp_t* parser);
	void (*llhttp_settings_init)(llhttp_settings_t* settings);
	llhttp_errno_t (*llhttp_execute)(llhttp_t* parser, const char* data, size_t len);
	llhttp_errno_t (*llhttp_finish)(llhttp_t* parser);
	int (*llhttp_message_needs_eof)(const llhttp_t* parser);
	int (*llhttp_should_keep_alive)(const llhttp_t* parser);
	uint8_t  (*llhttp_get_upgrade)(llhttp_t* parser);
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
	const char* (*llhttp_get_version_string)(void);
	int (*llhttp_store_event)(llhttp_t* parser, llhttp_event_t* event);
	void (*stringbuffer_add_event)(luajit_stringbuffer_reference_t* buffer, llhttp_event_t* event);
	size_t (*llhttp_get_max_url_length)(void);
	size_t (*llhttp_get_max_header_key_length)(void);
};

const char* llhttp_get_version_string(void);
void export_llhttp_bindings(lua_State* L);
