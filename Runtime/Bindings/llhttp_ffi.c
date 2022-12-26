#define ENABLE_LLHTTP_CALLBACK_LOGGING 1

#include "llhttp.h"
#include "llhttp_ffi.h"
#include "lua.h"

#include <stdio.h>
#include "stdint.h"
#include "string.h"


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
	uint8_t version_length;
	char version[16];
	uint8_t status_length;
	char status[MAX_STATUS_LENGTH_IN_BYTES];
	uint8_t num_headers;
	http_header_t headers[MAX_HEADER_COUNT];
	size_t body_length;
	char body[MAX_BODY_LENGTH_IN_BYTES];
	// We want a continuous memory area (cache locality), but also the flexiliby to stream/buffer large bodies (from Lua) if needed
	luajit_stringbuffer_reference_t extended_payload_buffer; // Optional feature, enabled on demand by allocating a stringBuffer here
} http_message_t;

// request_body_in_persistent_file
// max_temp_file_size
// FILE_FLAG_DELETE_ON_CLOSE

// typedef struct http_message http_message_t;


static void DEBUG(const char* message)
{
#ifdef ENABLE_LLHTTP_CALLBACK_LOGGING
	printf("[C] llhttp_ffi: %s\n", message);
#endif
}

#define LLHTTP_DATA_CALLBACK(event_name)                                           \
	int llhttp_##event_name(llhttp_t* parser_state, const char* at, size_t length) \
	{                                                                              \
		DEBUG(#event_name);                                                        \
                                                                                   \
		return HPE_OK;                                                             \
	}

#define LLHTTP_INFO_CALLBACK(event_name)             \
	int llhttp_##event_name(llhttp_t* parser_state)  \
	{                                                \
		DEBUG(#event_name);                          \
                                                     \
		return HPE_OK;                               \
	}

LLHTTP_INFO_CALLBACK(on_chunk_complete)
// LLHTTP_INFO_CALLBACK(on_header_value_complete)
int llhttp_on_header_value_complete(llhttp_t* parser_state) {
	DEBUG("on_header_value_complete");
	http_message_t* message = (http_message_t*) parser_state->data;
	message->num_headers++;
	return HPE_OK;
}
// LLHTTP_INFO_CALLBACK(on_message_complete)
int llhttp_on_message_complete(llhttp_t* parser_state) {
	DEBUG("on_message_complete");
	http_message_t* message = (http_message_t*) parser_state->data;
	message->is_complete = true;
	return HPE_OK;
}

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
// LLHTTP_INFO_CALLBACK(on_reset)
int llhttp_on_reset(llhttp_t* parser_state) {
	DEBUG("on_reset");
	http_message_t* message = (http_message_t*) parser_state->data;
	message->is_complete = false;
	// TBD reset the other fields as well?
	return HPE_OK;
}
// TODO reset message, or defer until message_begin?

// LLHTTP_DATA_CALLBACK(on_url)
int llhttp_on_url(llhttp_t* parser_state, const char* at, size_t length) {
	DEBUG("on_url");

	http_message_t *http_message = (http_message_t*) parser_state->data;
	if(http_message == NULL) return HPE_OK;
	// TODO test for raw llhttp calls (benchmarks)

  	if (length > sizeof(http_message->url) - 1) {
		// TODO
    	length = sizeof(http_message->url) - 1;
  	}
  	strncpy(http_message->url, at, length);
  	http_message->url[length] = '\0';

	return HPE_OK;
}
LLHTTP_DATA_CALLBACK(on_status)
// LLHTTP_DATA_CALLBACK(on_method)
int llhttp_on_method(llhttp_t* parser_state, const char* at, size_t length) {
	DEBUG("on_method");

	http_message_t *http_message = (http_message_t*) parser_state->data;
if(http_message == NULL) return HPE_OK;
  	if (length > sizeof(http_message->method) - 1) {
		// TODO
    	length = sizeof(http_message->method) - 1;
  	}
  	strncpy(http_message->method, at, length);
  	http_message->method[length] = '\0';

	return HPE_OK;
}
// LLHTTP_DATA_CALLBACK(on_version)
int llhttp_on_version(llhttp_t* parser_state, const char* at, size_t length) {
	DEBUG("on_version");

	http_message_t *http_message = (http_message_t*) parser_state->data;
if(http_message == NULL) return HPE_OK;
  	if (length > sizeof(http_message->version) - 1) {
		// TODO
    	length = sizeof(http_message->version) - 1;
  	}
  	strncpy(http_message->version, at, length);
  	http_message->version[length] = '\0';

	return HPE_OK;
}

LLHTTP_DATA_CALLBACK(on_chunk_extension_name)
LLHTTP_DATA_CALLBACK(on_chunk_extension_value)
// LLHTTP_DATA_CALLBACK(on_header_field)
int llhttp_on_header_field(llhttp_t* parser_state, const char* at, size_t length) {
	DEBUG("on_header_field");

	http_message_t* message = (http_message_t*) parser_state->data;
	if(message == NULL) return HPE_OK;

	// The count only increases after the current header field is complete
	const uint8_t last_header_index = message->num_headers;

	// TODO check size
	http_header_t* header = &message->headers[last_header_index];

  	memcpy(&header->key + header->key_length, at, length);
	header->key_length += length;

	return HPE_OK;
}
// LLHTTP_DATA_CALLBACK(on_header_value)
int llhttp_on_header_value(llhttp_t* parser_state, const char* at, size_t length) {
	DEBUG("on_header_value");

	http_message_t* message = (http_message_t*) parser_state->data;
	if(message == NULL) return HPE_OK;

	// The count only increases after the current header field is complete
	const uint8_t last_header_index = message->num_headers;

	// TODO check size
	http_header_t* header = &message->headers[last_header_index];

  	memcpy(&header->value + header->value_length, at, length);
	header->value_length += length;

	return HPE_OK;
}
// LLHTTP_DATA_CALLBACK(on_body)
int llhttp_on_body(llhttp_t* parser_state, const char* at, size_t length) {
	DEBUG("on_body");

	http_message_t *http_message = (http_message_t*) parser_state->data;
if(http_message == NULL) return HPE_OK;
  	if (length > sizeof(http_message->body) - 1) {
		// TODO
    	length = sizeof(http_message->body) - 1;
  	}
  	strncpy(http_message->body, at, length);
  	http_message->body[length] = '\0';

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

static void init_settings_with_callback_handlers(llhttp_settings_t* settings)
{
	DEBUG("init_settings_with_callback_handlers");

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

size_t llhttp_get_max_url_length() {	return MAX_URL_LENGTH_IN_BYTES; }
size_t llhttp_get_max_status_length() {	return MAX_STATUS_LENGTH_IN_BYTES; }
size_t llhttp_get_max_header_key_length() {	return MAX_HEADER_KEY_LENGTH_IN_BYTES; }
size_t llhttp_get_max_header_value_length() {	return MAX_HEADER_VALUE_LENGTH_IN_BYTES; }
size_t llhttp_get_max_header_count() {	return MAX_HEADER_COUNT; }
size_t llhttp_get_max_body_length() {	return MAX_BODY_LENGTH_IN_BYTES; }
size_t llhttp_get_message_size() {	return sizeof(http_message_t); }

void export_llhttp_bindings(lua_State* L)
{
	static struct static_llhttp_exports_table llhttp_exports_table;
	llhttp_exports_table.llhttp_init = llhttp_init;
	llhttp_exports_table.llhttp_reset = llhttp_reset;
	llhttp_exports_table.llhttp_settings_init = init_settings_with_callback_handlers;
	llhttp_exports_table.llhttp_execute = llhttp_execute;
	llhttp_exports_table.llhttp_finish = llhttp_finish;
	llhttp_exports_table.llhttp_message_needs_eof = llhttp_message_needs_eof;
	llhttp_exports_table.llhttp_should_keep_alive = llhttp_should_keep_alive;
	llhttp_exports_table.llhttp_get_upgrade = llhttp_get_upgrade;
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
	llhttp_exports_table.llhttp_get_version_string = llhttp_get_version_string;
	llhttp_exports_table.llhttp_get_max_url_length = llhttp_get_max_url_length;
	llhttp_exports_table.llhttp_get_max_status_length = llhttp_get_max_status_length;
	llhttp_exports_table.llhttp_get_max_header_key_length = llhttp_get_max_header_key_length;
	llhttp_exports_table.llhttp_get_max_header_value_length = llhttp_get_max_header_value_length;
	llhttp_exports_table.llhttp_get_max_header_count = llhttp_get_max_header_count;
	llhttp_exports_table.llhttp_get_max_body_length = llhttp_get_max_body_length;
	llhttp_exports_table.llhttp_get_message_size = llhttp_get_message_size;

	// TODO add defines here (readonly), as functions - then test in Lua

	// This wrapper must be bound to the llhttp namespace on initialization from Lua, in place of the dynamic binding (.so/.dll load)
	lua_getglobal(L, "STATIC_FFI_EXPORTS");
	lua_pushlightuserdata(L, &llhttp_exports_table);
	lua_setfield(L, -2, "llhttp");
}