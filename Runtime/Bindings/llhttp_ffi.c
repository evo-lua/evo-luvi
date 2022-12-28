// #define ENABLE_LLHTTP_CALLBACK_LOGGING 1

#include "llhttp.h"
#include "llhttp_ffi.h"
#include "lua.h"

#include "string.h"

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

#define LLHTTP_INFO_CALLBACK(event_name)            \
	int llhttp_##event_name(llhttp_t* parser_state) \
	{                                               \
		DEBUG(#event_name);                         \
                                                    \
		return HPE_OK;                              \
	}

int llhttp_on_header_value_complete(llhttp_t* parser_state)
{
	DEBUG("on_header_value_complete");

	http_message_t* message = (http_message_t*)parser_state->data;
	if (message == NULL)
		return HPE_OK;

	message->num_headers++;
	return HPE_OK;
}

int llhttp_on_message_complete(llhttp_t* parser_state)
{
	DEBUG("on_message_complete");

	http_message_t* message = (http_message_t*)parser_state->data;
	if (message == NULL)
		return HPE_OK;

	message->is_complete = true;
	return HPE_OK;
}

LLHTTP_INFO_CALLBACK(on_chunk_complete)
LLHTTP_INFO_CALLBACK(on_chunk_header)
LLHTTP_INFO_CALLBACK(on_message_begin)
LLHTTP_INFO_CALLBACK(on_headers_complete)
LLHTTP_INFO_CALLBACK(on_method_complete)
LLHTTP_INFO_CALLBACK(on_header_field_complete)
LLHTTP_INFO_CALLBACK(on_chunk_extension_name_complete)
LLHTTP_INFO_CALLBACK(on_chunk_extension_value_complete)
LLHTTP_INFO_CALLBACK(on_url_complete)

LLHTTP_DATA_CALLBACK(on_version)
LLHTTP_DATA_CALLBACK(on_chunk_extension_name)
LLHTTP_DATA_CALLBACK(on_chunk_extension_value)

int llhttp_on_status_complete(llhttp_t* parser_state)
{
	DEBUG("on_status_complete");

	http_message_t* message = (http_message_t*)parser_state->data;
	if (message == NULL)
		return HPE_OK;

	const int status_code = llhttp_get_status_code(parser_state);
	message->status_code = status_code;

	return HPE_OK;
}

int llhttp_on_version_complete(llhttp_t* parser_state)
{
	DEBUG("on_version_complete");

	http_message_t* message = (http_message_t*)parser_state->data;
	if (message == NULL)
		return HPE_OK;

	message->version_major = llhttp_get_http_major(parser_state);
	message->version_minor = llhttp_get_http_minor(parser_state);

	return HPE_OK;
}

int llhttp_on_reset(llhttp_t* parser_state)
{
	DEBUG("on_reset");

	http_message_t* message = (http_message_t*)parser_state->data;
	if (message == NULL)
		return HPE_OK;

	// Since we omit safety checks in the callback handlers (for performance reasons), make sure we don't write-fault off the end
	message->is_complete = false;
	message->method_length = 0;
	message->url_length = 0;
	message->status_length = 0;
	message->body_length = 0;
	message->status_code = 0;

	for (uint8_t i = 0; i < message->num_headers; i++) {
		message->headers[i].key_length = 0;
		message->headers[i].value_length = 0;
	}
	message->num_headers = 0;

	// The LuaJIT string buffer itself should be managed from Lua if resets are needed; it's considered read-only here

	return HPE_OK;
}

int llhttp_on_url(llhttp_t* parser_state, const char* at, size_t length)
{
	DEBUG("on_url");

	http_message_t* message = (http_message_t*)parser_state->data;
	if (message == NULL)
		return HPE_OK;

	if (message->method_length + length > MAX_URL_LENGTH_IN_BYTES) {
		llhttp_set_error_reason(parser_state, "414 URI Too Long");
		return HPE_USER;
	}

	memcpy(message->url + message->url_length, at, length);
	message->url_length += length;

	return HPE_OK;
}

int llhttp_on_status(llhttp_t* parser_state, const char* at, size_t length)
{
	DEBUG("on_status");

	http_message_t* message = (http_message_t*)parser_state->data;
	if (message == NULL)
		return HPE_OK;

	if (message->status_length + length > MAX_STATUS_LENGTH_IN_BYTES) {
		llhttp_set_error_reason(parser_state, "Status or reason phrase too long");
		return HPE_USER;
	}

	memcpy(message->status + message->status_length, at, length);
	message->status_length += length;

	return HPE_OK;
}

int llhttp_on_method(llhttp_t* parser_state, const char* at, size_t length)
{
	DEBUG("on_method");

	http_message_t* message = (http_message_t*)parser_state->data;
	if (message == NULL)
		return HPE_OK;

	// Can omit boundary checks here since the parser will never call this for invalid methods

	memcpy(message->method + message->method_length, at, length);
	message->method_length += length;

	return HPE_OK;
}

int llhttp_on_header_field(llhttp_t* parser_state, const char* at, size_t length)
{
	DEBUG("on_header_field");

	http_message_t* message = (http_message_t*)parser_state->data;
	if (message == NULL)
		return HPE_OK;

	// The count only increases after the current header field is complete
	const uint8_t last_header_index = message->num_headers;
	if (last_header_index == MAX_HEADER_COUNT) {
		llhttp_set_error_reason(parser_state, "Too many headers");
		return HPE_USER;
	}

	http_header_t* header = &message->headers[last_header_index];

	if (header->key_length + length > MAX_HEADER_KEY_LENGTH_IN_BYTES) {
		llhttp_set_error_reason(parser_state, "431 Request Header Fields Too Large");
		return HPE_USER;
	}

	memcpy(header->key + header->key_length, at, length);
	header->key_length += length;

	return HPE_OK;
}

int llhttp_on_header_value(llhttp_t* parser_state, const char* at, size_t length)
{
	DEBUG("on_header_value");

	http_message_t* message = (http_message_t*)parser_state->data;
	if (message == NULL)
		return HPE_OK;

	// The count only increases after the current header field is complete
	const uint8_t last_header_index = message->num_headers;
	// Can skip boundary checks since it's handled in on_header_key, so we'll never even get here

	http_header_t* header = &message->headers[last_header_index];
	if (header->value_length + length > MAX_HEADER_VALUE_LENGTH_IN_BYTES) {
		llhttp_set_error_reason(parser_state, "431 Request Header Fields Too Large");
		return HPE_USER;
	}

	memcpy(header->value + header->value_length, at, length);
	header->value_length += length;

	return HPE_OK;
}

inline int try_write_extended_payload(llhttp_t* parser_state, const char* at, size_t length)
{
	http_message_t* message = (http_message_t*)parser_state->data; // Can assume this is valid and not NULL here

	if (message->extended_payload_buffer.ptr == NULL) {
		llhttp_set_error_reason(parser_state, "Message body too large (and extended payloads are disabled)");
		return HPE_USER;
	}

	bool has_buffer_enough_space = (message->extended_payload_buffer.size - message->extended_payload_buffer.used) >= length;
	if (!has_buffer_enough_space) {
		llhttp_set_error_reason(parser_state, "Message body too large (cannot fit into extended payload buffer)");
		return HPE_USER;
	}

	memcpy(message->extended_payload_buffer.ptr, at, length);
	message->extended_payload_buffer.used += length;

	return HPE_OK;
}

int llhttp_on_body(llhttp_t* parser_state, const char* at, size_t length)
{
	DEBUG("on_body");

	http_message_t* message = (http_message_t*)parser_state->data;
	if (message == NULL)
		return HPE_OK;

	bool payload_exceeds_buffer_capacity = message->body_length + length > MAX_BODY_LENGTH_IN_BYTES;
	if (payload_exceeds_buffer_capacity)
		return try_write_extended_payload(parser_state, at, length);

	memcpy(message->body + message->body_length, at, length);
	message->body_length += length;

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

size_t llhttp_get_max_url_length() { return MAX_URL_LENGTH_IN_BYTES; }
size_t llhttp_get_max_status_length() { return MAX_STATUS_LENGTH_IN_BYTES; }
size_t llhttp_get_max_header_key_length() { return MAX_HEADER_KEY_LENGTH_IN_BYTES; }
size_t llhttp_get_max_header_value_length() { return MAX_HEADER_VALUE_LENGTH_IN_BYTES; }
size_t llhttp_get_max_header_count() { return MAX_HEADER_COUNT; }
size_t llhttp_get_max_body_length() { return MAX_BODY_LENGTH_IN_BYTES; }
size_t llhttp_get_message_size() { return sizeof(http_message_t); }

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

	// This wrapper must be bound to the llhttp namespace on initialization from Lua, in place of the dynamic binding (.so/.dll load)
	lua_getglobal(L, "STATIC_FFI_EXPORTS");
	lua_pushlightuserdata(L, &llhttp_exports_table);
	lua_setfield(L, -2, "llhttp");
}