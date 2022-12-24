// #define ENABLE_LLHTTP_CALLBACK_LOGGING 1

#include "llhttp.h"
#include "llhttp_ffi.h"
#include "lua.h"

#include <stdio.h>
#include "stdint.h"
#include "string.h"


#define MAX_HEADERS 32

// Define a structure to represent a HTTP message
typedef struct http_message {
  char method[16];
  char uri[256];
  char http_version[16];
  struct {
    char name[256];
    char value[4096];
  } headers[MAX_HEADERS];
  size_t num_headers;
  char body[4096];
} http_message_t;

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

// LLHTTP_DATA_CALLBACK(on_url)
int llhttp_on_url(llhttp_t* parser_state, const char* at, size_t length) {
	DEBUG("on_url");

	http_message_t *http_message = (http_message_t*) parser_state->data;
	if(http_message == NULL) return HPE_OK;
	// TODO test for raw llhttp calls (benchmarks)

  	if (length > sizeof(http_message->uri) - 1) {
		// TODO
    	length = sizeof(http_message->uri) - 1;
  	}
  	strncpy(http_message->uri, at, length);
  	http_message->uri[length] = '\0';

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
LLHTTP_DATA_CALLBACK(on_version)
LLHTTP_DATA_CALLBACK(on_chunk_extension_name)
LLHTTP_DATA_CALLBACK(on_chunk_extension_value)
LLHTTP_DATA_CALLBACK(on_header_field)
LLHTTP_DATA_CALLBACK(on_header_value)
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
	llhttp_exports_table.llhttp_store_event = llhttp_get_version_string; // TODO remove
	llhttp_exports_table.stringbuffer_add_event =  llhttp_get_version_string; // TODO remove
	// TODO add defines here (readonly), as functions - then test in Lua

	// This wrapper must be bound to the llhttp namespace on initialization from Lua, in place of the dynamic binding (.so/.dll load)
	lua_getglobal(L, "STATIC_FFI_EXPORTS");
	lua_pushlightuserdata(L, &llhttp_exports_table);
	lua_setfield(L, -2, "llhttp");
}