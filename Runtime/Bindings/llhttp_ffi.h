#pragma once

#include "llhttp.h"
#include "lua.h"

#include <stdbool.h>

// This represents the string buffer's writable area since Lua cannot directly pass the SBuf pointer via FFI (AFAIK), nor the Lua state
// The FFI bindings just write to it, assuming plenty of space has been reserved ahead of time (somewhat wasteful, but should be safe)
struct luajit_stringbuffer_reference {
	size_t size;
	uint8_t* ptr;
	size_t used;
};
typedef struct luajit_stringbuffer_reference luajit_stringbuffer_reference_t;

#define MAX_URL_LENGTH_IN_BYTES 256
#define MAX_STATUS_LENGTH_IN_BYTES 256
#define MAX_HEADER_KEY_LENGTH_IN_BYTES 256
#define MAX_HEADER_VALUE_LENGTH_IN_BYTES 4096
#define MAX_HEADER_COUNT 32
#define MAX_BODY_LENGTH_IN_BYTES 4096

typedef struct {
	uint8_t key_length;
	char key[MAX_HEADER_KEY_LENGTH_IN_BYTES];
	size_t value_length;
	char value[MAX_HEADER_VALUE_LENGTH_IN_BYTES];
} http_header_t;

typedef struct http_message {
	bool is_complete;
	uint8_t method_length;
	char method[16];
	size_t url_length;
	char url[MAX_URL_LENGTH_IN_BYTES];
	uint8_t version_major;
	uint8_t version_minor;
	int status_code;
	uint8_t status_length;
	char status[MAX_STATUS_LENGTH_IN_BYTES];
	uint8_t num_headers;
	http_header_t headers[MAX_HEADER_COUNT];
	size_t body_length;
	char body[MAX_BODY_LENGTH_IN_BYTES];
	// We want a continuous memory area (cache locality), but also the flexiliby to stream/buffer large bodies (from Lua) if needed
	luajit_stringbuffer_reference_t extended_payload_buffer; // Optional feature, enabled on demand by allocating a stringBuffer here
} http_message_t;

// A thin wrapper for the llhttp API, only needed to expose the statically-linked llhttp symbols to Lua and load them via FFI
struct static_llhttp_exports_table {
	void (*llhttp_init)(llhttp_t* parser, llhttp_type_t type, const llhttp_settings_t* settings);
	void (*llhttp_reset)(llhttp_t* parser);
	void (*llhttp_settings_init)(llhttp_settings_t* settings);
	llhttp_errno_t (*llhttp_execute)(llhttp_t* parser, const char* data, size_t len);
	llhttp_errno_t (*llhttp_finish)(llhttp_t* parser);
	int (*llhttp_message_needs_eof)(const llhttp_t* parser);
	int (*llhttp_should_keep_alive)(const llhttp_t* parser);
	uint8_t (*llhttp_get_upgrade)(llhttp_t* parser);
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
	size_t (*llhttp_get_max_url_length)(void);
	size_t (*llhttp_get_max_status_length)(void);
	size_t (*llhttp_get_max_header_key_length)(void);
	size_t (*llhttp_get_max_header_value_length)(void);
	size_t (*llhttp_get_max_header_count)(void);
	size_t (*llhttp_get_max_body_length)(void);
	size_t (*llhttp_get_message_size)(void);
};

const char* llhttp_get_version_string(void);
void export_llhttp_bindings(lua_State* L);
