#pragma once

#include "lua.h"

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

const char* llhttp_get_version_string(void);
void export_llhttp_bindings(lua_State* L);
