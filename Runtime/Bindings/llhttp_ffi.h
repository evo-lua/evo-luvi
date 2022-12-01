#pragma once

#include "lua.h"

#include <stdint.h>

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

// Since we can't trigger Lua callbacks directly without murdering performance, save the relevant info and fetch it from Lua later
// Only data_callbacks (llhttp_data_cb) have a payload, so let's store (0, 0) for info-only callbacks (llhttp_cb)
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
	uint8_t * ptr;
	size_t used;
};
typedef struct lj_writebuffer lj_writebuffer_t;

const char* llhttp_get_version_string(void);
void export_llhttp_bindings(lua_State* L);
