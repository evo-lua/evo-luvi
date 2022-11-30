local ffi = require("ffi")

local isWindows = (ffi.os == "Windows")

local llhttp = {
	-- Copy/paste these after some processing, via deps/generate-cdefs.sh (whenever the llhttp API changes)
	cdefs = [[
		typedef struct llhttp__internal_s llhttp__internal_t;
		struct llhttp__internal_s {
		  int32_t _index;
		  void* _span_pos0;
		  void* _span_cb0;
		  int32_t error;
		  const char* reason;
		  const char* error_pos;
		  void* data;
		  void* _current;
		  uint64_t content_length;
		  uint8_t type;
		  uint8_t method;
		  uint8_t http_major;
		  uint8_t http_minor;
		  uint8_t header_state;
		  uint8_t lenient_flags;
		  uint8_t upgrade;
		  uint8_t finish;
		  uint16_t flags;
		  uint16_t status_code;
		  uint8_t initial_message_completed;
		  void* settings;
		};
		int llhttp__internal_init(llhttp__internal_t* s);
		int llhttp__internal_execute(llhttp__internal_t* s, const char* p, const char* endp);
		enum llhttp_errno {
		  HPE_OK = 0,
		  HPE_INTERNAL = 1,
		  HPE_STRICT = 2,
		  HPE_CR_EXPECTED = 25,
		  HPE_LF_EXPECTED = 3,
		  HPE_UNEXPECTED_CONTENT_LENGTH = 4,
		  HPE_UNEXPECTED_SPACE = 30,
		  HPE_CLOSED_CONNECTION = 5,
		  HPE_INVALID_METHOD = 6,
		  HPE_INVALID_URL = 7,
		  HPE_INVALID_CONSTANT = 8,
		  HPE_INVALID_VERSION = 9,
		  HPE_INVALID_HEADER_TOKEN = 10,
		  HPE_INVALID_CONTENT_LENGTH = 11,
		  HPE_INVALID_CHUNK_SIZE = 12,
		  HPE_INVALID_STATUS = 13,
		  HPE_INVALID_EOF_STATE = 14,
		  HPE_INVALID_TRANSFER_ENCODING = 15,
		  HPE_CB_MESSAGE_BEGIN = 16,
		  HPE_CB_HEADERS_COMPLETE = 17,
		  HPE_CB_MESSAGE_COMPLETE = 18,
		  HPE_CB_CHUNK_HEADER = 19,
		  HPE_CB_CHUNK_COMPLETE = 20,
		  HPE_PAUSED = 21,
		  HPE_PAUSED_UPGRADE = 22,
		  HPE_PAUSED_H2_UPGRADE = 23,
		  HPE_USER = 24,
		  HPE_CB_URL_COMPLETE = 26,
		  HPE_CB_STATUS_COMPLETE = 27,
		  HPE_CB_METHOD_COMPLETE = 32,
		  HPE_CB_VERSION_COMPLETE = 33,
		  HPE_CB_HEADER_FIELD_COMPLETE = 28,
		  HPE_CB_HEADER_VALUE_COMPLETE = 29,
		  HPE_CB_CHUNK_EXTENSION_NAME_COMPLETE = 34,
		  HPE_CB_CHUNK_EXTENSION_VALUE_COMPLETE = 35,
		  HPE_CB_RESET = 31
		};
		typedef enum llhttp_errno llhttp_errno_t;
		enum llhttp_flags {
		  F_CONNECTION_KEEP_ALIVE = 0x1,
		  F_CONNECTION_CLOSE = 0x2,
		  F_CONNECTION_UPGRADE = 0x4,
		  F_CHUNKED = 0x8,
		  F_UPGRADE = 0x10,
		  F_CONTENT_LENGTH = 0x20,
		  F_SKIPBODY = 0x40,
		  F_TRAILING = 0x80,
		  F_TRANSFER_ENCODING = 0x200
		};
		typedef enum llhttp_flags llhttp_flags_t;
		enum llhttp_lenient_flags {
		  LENIENT_HEADERS = 0x1,
		  LENIENT_CHUNKED_LENGTH = 0x2,
		  LENIENT_KEEP_ALIVE = 0x4,
		  LENIENT_TRANSFER_ENCODING = 0x8,
		  LENIENT_VERSION = 0x10
		};
		typedef enum llhttp_lenient_flags llhttp_lenient_flags_t;
		enum llhttp_type {
		  HTTP_BOTH = 0,
		  HTTP_REQUEST = 1,
		  HTTP_RESPONSE = 2
		};
		typedef enum llhttp_type llhttp_type_t;
		enum llhttp_finish {
		  HTTP_FINISH_SAFE = 0,
		  HTTP_FINISH_SAFE_WITH_CB = 1,
		  HTTP_FINISH_UNSAFE = 2
		};
		typedef enum llhttp_finish llhttp_finish_t;
		enum llhttp_method {
		  HTTP_DELETE = 0,
		  HTTP_GET = 1,
		  HTTP_HEAD = 2,
		  HTTP_POST = 3,
		  HTTP_PUT = 4,
		  HTTP_CONNECT = 5,
		  HTTP_OPTIONS = 6,
		  HTTP_TRACE = 7,
		  HTTP_COPY = 8,
		  HTTP_LOCK = 9,
		  HTTP_MKCOL = 10,
		  HTTP_MOVE = 11,
		  HTTP_PROPFIND = 12,
		  HTTP_PROPPATCH = 13,
		  HTTP_SEARCH = 14,
		  HTTP_UNLOCK = 15,
		  HTTP_BIND = 16,
		  HTTP_REBIND = 17,
		  HTTP_UNBIND = 18,
		  HTTP_ACL = 19,
		  HTTP_REPORT = 20,
		  HTTP_MKACTIVITY = 21,
		  HTTP_CHECKOUT = 22,
		  HTTP_MERGE = 23,
		  HTTP_MSEARCH = 24,
		  HTTP_NOTIFY = 25,
		  HTTP_SUBSCRIBE = 26,
		  HTTP_UNSUBSCRIBE = 27,
		  HTTP_PATCH = 28,
		  HTTP_PURGE = 29,
		  HTTP_MKCALENDAR = 30,
		  HTTP_LINK = 31,
		  HTTP_UNLINK = 32,
		  HTTP_SOURCE = 33,
		  HTTP_PRI = 34,
		  HTTP_DESCRIBE = 35,
		  HTTP_ANNOUNCE = 36,
		  HTTP_SETUP = 37,
		  HTTP_PLAY = 38,
		  HTTP_PAUSE = 39,
		  HTTP_TEARDOWN = 40,
		  HTTP_GET_PARAMETER = 41,
		  HTTP_SET_PARAMETER = 42,
		  HTTP_REDIRECT = 43,
		  HTTP_RECORD = 44,
		  HTTP_FLUSH = 45
		};
		typedef enum llhttp_method llhttp_method_t;
		enum llhttp_status {
		  HTTP_STATUS_CONTINUE = 100,
		  HTTP_STATUS_SWITCHING_PROTOCOLS = 101,
		  HTTP_STATUS_PROCESSING = 102,
		  HTTP_STATUS_EARLY_HINTS = 103,
		  HTTP_STATUS_RESPONSE_IS_STALE = 110,
		  HTTP_STATUS_REVALIDATION_FAILED = 111,
		  HTTP_STATUS_DISCONNECTED_OPERATION = 112,
		  HTTP_STATUS_HEURISTIC_EXPIRATION = 113,
		  HTTP_STATUS_MISCELLANEOUS_WARNING = 199,
		  HTTP_STATUS_OK = 200,
		  HTTP_STATUS_CREATED = 201,
		  HTTP_STATUS_ACCEPTED = 202,
		  HTTP_STATUS_NON_AUTHORITATIVE_INFORMATION = 203,
		  HTTP_STATUS_NO_CONTENT = 204,
		  HTTP_STATUS_RESET_CONTENT = 205,
		  HTTP_STATUS_PARTIAL_CONTENT = 206,
		  HTTP_STATUS_MULTI_STATUS = 207,
		  HTTP_STATUS_ALREADY_REPORTED = 208,
		  HTTP_STATUS_TRANSFORMATION_APPLIED = 214,
		  HTTP_STATUS_IM_USED = 226,
		  HTTP_STATUS_MISCELLANEOUS_PERSISTENT_WARNING = 299,
		  HTTP_STATUS_MULTIPLE_CHOICES = 300,
		  HTTP_STATUS_MOVED_PERMANENTLY = 301,
		  HTTP_STATUS_FOUND = 302,
		  HTTP_STATUS_SEE_OTHER = 303,
		  HTTP_STATUS_NOT_MODIFIED = 304,
		  HTTP_STATUS_USE_PROXY = 305,
		  HTTP_STATUS_SWITCH_PROXY = 306,
		  HTTP_STATUS_TEMPORARY_REDIRECT = 307,
		  HTTP_STATUS_PERMANENT_REDIRECT = 308,
		  HTTP_STATUS_BAD_REQUEST = 400,
		  HTTP_STATUS_UNAUTHORIZED = 401,
		  HTTP_STATUS_PAYMENT_REQUIRED = 402,
		  HTTP_STATUS_FORBIDDEN = 403,
		  HTTP_STATUS_NOT_FOUND = 404,
		  HTTP_STATUS_METHOD_NOT_ALLOWED = 405,
		  HTTP_STATUS_NOT_ACCEPTABLE = 406,
		  HTTP_STATUS_PROXY_AUTHENTICATION_REQUIRED = 407,
		  HTTP_STATUS_REQUEST_TIMEOUT = 408,
		  HTTP_STATUS_CONFLICT = 409,
		  HTTP_STATUS_GONE = 410,
		  HTTP_STATUS_LENGTH_REQUIRED = 411,
		  HTTP_STATUS_PRECONDITION_FAILED = 412,
		  HTTP_STATUS_PAYLOAD_TOO_LARGE = 413,
		  HTTP_STATUS_URI_TOO_LONG = 414,
		  HTTP_STATUS_UNSUPPORTED_MEDIA_TYPE = 415,
		  HTTP_STATUS_RANGE_NOT_SATISFIABLE = 416,
		  HTTP_STATUS_EXPECTATION_FAILED = 417,
		  HTTP_STATUS_IM_A_TEAPOT = 418,
		  HTTP_STATUS_PAGE_EXPIRED = 419,
		  HTTP_STATUS_ENHANCE_YOUR_CALM = 420,
		  HTTP_STATUS_MISDIRECTED_REQUEST = 421,
		  HTTP_STATUS_UNPROCESSABLE_ENTITY = 422,
		  HTTP_STATUS_LOCKED = 423,
		  HTTP_STATUS_FAILED_DEPENDENCY = 424,
		  HTTP_STATUS_TOO_EARLY = 425,
		  HTTP_STATUS_UPGRADE_REQUIRED = 426,
		  HTTP_STATUS_PRECONDITION_REQUIRED = 428,
		  HTTP_STATUS_TOO_MANY_REQUESTS = 429,
		  HTTP_STATUS_REQUEST_HEADER_FIELDS_TOO_LARGE_UNOFFICIAL = 430,
		  HTTP_STATUS_REQUEST_HEADER_FIELDS_TOO_LARGE = 431,
		  HTTP_STATUS_LOGIN_TIMEOUT = 440,
		  HTTP_STATUS_NO_RESPONSE = 444,
		  HTTP_STATUS_RETRY_WITH = 449,
		  HTTP_STATUS_BLOCKED_BY_PARENTAL_CONTROL = 450,
		  HTTP_STATUS_UNAVAILABLE_FOR_LEGAL_REASONS = 451,
		  HTTP_STATUS_CLIENT_CLOSED_LOAD_BALANCED_REQUEST = 460,
		  HTTP_STATUS_INVALID_X_FORWARDED_FOR = 463,
		  HTTP_STATUS_REQUEST_HEADER_TOO_LARGE = 494,
		  HTTP_STATUS_SSL_CERTIFICATE_ERROR = 495,
		  HTTP_STATUS_SSL_CERTIFICATE_REQUIRED = 496,
		  HTTP_STATUS_HTTP_REQUEST_SENT_TO_HTTPS_PORT = 497,
		  HTTP_STATUS_INVALID_TOKEN = 498,
		  HTTP_STATUS_CLIENT_CLOSED_REQUEST = 499,
		  HTTP_STATUS_INTERNAL_SERVER_ERROR = 500,
		  HTTP_STATUS_NOT_IMPLEMENTED = 501,
		  HTTP_STATUS_BAD_GATEWAY = 502,
		  HTTP_STATUS_SERVICE_UNAVAILABLE = 503,
		  HTTP_STATUS_GATEWAY_TIMEOUT = 504,
		  HTTP_STATUS_HTTP_VERSION_NOT_SUPPORTED = 505,
		  HTTP_STATUS_VARIANT_ALSO_NEGOTIATES = 506,
		  HTTP_STATUS_INSUFFICIENT_STORAGE = 507,
		  HTTP_STATUS_LOOP_DETECTED = 508,
		  HTTP_STATUS_BANDWIDTH_LIMIT_EXCEEDED = 509,
		  HTTP_STATUS_NOT_EXTENDED = 510,
		  HTTP_STATUS_NETWORK_AUTHENTICATION_REQUIRED = 511,
		  HTTP_STATUS_WEB_SERVER_UNKNOWN_ERROR = 520,
		  HTTP_STATUS_WEB_SERVER_IS_DOWN = 521,
		  HTTP_STATUS_CONNECTION_TIMEOUT = 522,
		  HTTP_STATUS_ORIGIN_IS_UNREACHABLE = 523,
		  HTTP_STATUS_TIMEOUT_OCCURED = 524,
		  HTTP_STATUS_SSL_HANDSHAKE_FAILED = 525,
		  HTTP_STATUS_INVALID_SSL_CERTIFICATE = 526,
		  HTTP_STATUS_RAILGUN_ERROR = 527,
		  HTTP_STATUS_SITE_IS_OVERLOADED = 529,
		  HTTP_STATUS_SITE_IS_FROZEN = 530,
		  HTTP_STATUS_IDENTITY_PROVIDER_AUTHENTICATION_ERROR = 561,
		  HTTP_STATUS_NETWORK_READ_TIMEOUT = 598,
		  HTTP_STATUS_NETWORK_CONNECT_TIMEOUT = 599
		};
		typedef enum llhttp_status llhttp_status_t;
		typedef llhttp__internal_t llhttp_t;
		typedef struct llhttp_settings_s llhttp_settings_t;
		typedef int (*llhttp_data_cb)(llhttp_t*, const char *at, size_t length);
		typedef int (*llhttp_cb)(llhttp_t*);
		struct llhttp_settings_s {
		  llhttp_cb on_message_begin;
		  llhttp_data_cb on_url;
		  llhttp_data_cb on_status;
		  llhttp_data_cb on_method;
		  llhttp_data_cb on_version;
		  llhttp_data_cb on_header_field;
		  llhttp_data_cb on_header_value;
		  llhttp_data_cb on_chunk_extension_name;
		  llhttp_data_cb on_chunk_extension_value;
		  llhttp_cb on_headers_complete;
		  llhttp_data_cb on_body;
		  llhttp_cb on_message_complete;
		  llhttp_cb on_url_complete;
		  llhttp_cb on_status_complete;
		  llhttp_cb on_method_complete;
		  llhttp_cb on_version_complete;
		  llhttp_cb on_header_field_complete;
		  llhttp_cb on_header_value_complete;
		  llhttp_cb on_chunk_extension_name_complete;
		  llhttp_cb on_chunk_extension_value_complete;
		  llhttp_cb on_chunk_header;
		  llhttp_cb on_chunk_complete;
		  llhttp_cb on_reset;
		};
		void llhttp_init(llhttp_t* parser, llhttp_type_t type,
						 const llhttp_settings_t* settings);
		llhttp_t* llhttp_alloc(llhttp_type_t type);
		void llhttp_free(llhttp_t* parser);
		uint8_t llhttp_get_type(llhttp_t* parser);
		uint8_t llhttp_get_http_major(llhttp_t* parser);
		uint8_t llhttp_get_http_minor(llhttp_t* parser);
		uint8_t llhttp_get_method(llhttp_t* parser);
		int llhttp_get_status_code(llhttp_t* parser);
		uint8_t llhttp_get_upgrade(llhttp_t* parser);
		void llhttp_reset(llhttp_t* parser);
		void llhttp_settings_init(llhttp_settings_t* settings);
		llhttp_errno_t llhttp_execute(llhttp_t* parser, const char* data, size_t len);
		llhttp_errno_t llhttp_finish(llhttp_t* parser);
		int llhttp_message_needs_eof(const llhttp_t* parser);
		int llhttp_should_keep_alive(const llhttp_t* parser);
		void llhttp_pause(llhttp_t* parser);
		void llhttp_resume(llhttp_t* parser);
		void llhttp_resume_after_upgrade(llhttp_t* parser);
		llhttp_errno_t llhttp_get_errno(const llhttp_t* parser);
		const char* llhttp_get_error_reason(const llhttp_t* parser);
		void llhttp_set_error_reason(llhttp_t* parser, const char* reason);
		const char* llhttp_get_error_pos(const llhttp_t* parser);
		const char* llhttp_errno_name(llhttp_errno_t err);
		const char* llhttp_method_name(llhttp_method_t method);
		const char* llhttp_status_name(llhttp_status_t status);
		void llhttp_set_lenient_headers(llhttp_t* parser, int enabled);
		void llhttp_set_lenient_chunked_length(llhttp_t* parser, int enabled);
		void llhttp_set_lenient_keep_alive(llhttp_t* parser, int enabled);
		void llhttp_set_lenient_transfer_encoding(llhttp_t* parser, int enabled);
	]] ..
	-- These are copied from the runtime's FFI bindings (to access statically-linked llhttp exports via FFI)
	[[
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
	]] ..
	-- And this is unlikely to ever change, based on the LuaJIT string.buffer API (needed to pass data from C to FFI without callbacks)
	[[
		struct lj_writebuffer {
			size_t size;
			uint8_t* ptr;
			size_t used;
		};
		typedef struct lj_writebuffer lj_writebuffer_t;

		struct llhttp_event {
			uint8_t event_id;
			const char* payload_start_pointer;
			size_t payload_length;
		};
		typedef struct llhttp_event llhttp_event_t;
	]],
	PARSER_TYPES = {
		HTTP_BOTH = 0,
		HTTP_REQUEST = 1,
		HTTP_RESPONSE = 2
	},
	ERROR_TYPES = {
		HPE_OK = 0,
		HPE_INTERNAL = 1,
		HPE_STRICT = 2,
		HPE_LF_EXPECTED = 3,
		HPE_UNEXPECTED_CONTENT_LENGTH = 4,
		HPE_CLOSED_CONNECTION = 5,
		HPE_INVALID_METHOD = 6,
		HPE_INVALID_URL = 7,
		HPE_INVALID_CONSTANT = 8,
		HPE_INVALID_VERSION = 9,
		HPE_INVALID_HEADER_TOKEN = 10,
		HPE_INVALID_CONTENT_LENGTH = 11,
		HPE_INVALID_CHUNK_SIZE = 12,
		HPE_INVALID_STATUS = 13,
		HPE_INVALID_EOF_STATE = 14,
		HPE_INVALID_TRANSFER_ENCODING = 15,
		HPE_CB_MESSAGE_BEGIN = 16,
		HPE_CB_HEADERS_COMPLETE = 17,
		HPE_CB_MESSAGE_COMPLETE = 18,
		HPE_CB_CHUNK_HEADER = 19,
		HPE_CB_CHUNK_COMPLETE = 20,
		HPE_PAUSED = 21,
		HPE_PAUSED_UPGRADE = 22,
		HPE_PAUSED_H2_UPGRADE = 23,
		HPE_USER = 24
	},
	HTTP_METHODS = {
		HTTP_DELETE = 0,
		HTTP_GET = 1,
		HTTP_HEAD = 2,
		HTTP_POST = 3,
		HTTP_PUT = 4,
		HTTP_CONNECT = 5,
		HTTP_OPTIONS = 6,
		HTTP_TRACE = 7,
		HTTP_COPY = 8,
		HTTP_LOCK = 9,
		HTTP_MKCOL = 10,
		HTTP_MOVE = 11,
		HTTP_PROPFIND = 12,
		HTTP_PROPPATCH = 13,
		HTTP_SEARCH = 14,
		HTTP_UNLOCK = 15,
		HTTP_BIND = 16,
		HTTP_REBIND = 17,
		HTTP_UNBIND = 18,
		HTTP_ACL = 19,
		HTTP_REPORT = 20,
		HTTP_MKACTIVITY = 21,
		HTTP_CHECKOUT = 22,
		HTTP_MERGE = 23,
		HTTP_MSEARCH = 24,
		HTTP_NOTIFY = 25,
		HTTP_SUBSCRIBE = 26,
		HTTP_UNSUBSCRIBE = 27,
		HTTP_PATCH = 28,
		HTTP_PURGE = 29,
		HTTP_MKCALENDAR = 30,
		HTTP_LINK = 31,
		HTTP_UNLINK = 32,
		HTTP_SOURCE = 33,
		HTTP_PRI = 34,
		HTTP_DESCRIBE = 35,
		HTTP_ANNOUNCE = 36,
		HTTP_SETUP = 37,
		HTTP_PLAY = 38,
		HTTP_PAUSE = 39,
		HTTP_TEARDOWN = 40,
		HTTP_GET_PARAMETER = 41,
		HTTP_SET_PARAMETER = 42,
		HTTP_REDIRECT = 43,
		HTTP_RECORD = 44,
		HTTP_FLUSH = 45
	},
	SHARED_OBJECT_NAME = isWindows and "llhttp.dll" or "./libllhttp.so",
}

-- In order to use the same bindings when statically linking the API (with a lightuserdata wrapper), defer loading
function llhttp.load(libraryPath) -- Use this when dynamically loading, instead of the lightuserdata API wrapper object
	llhttp.bindings = ffi.load(libraryPath or llhttp.SHARED_OBJECT_NAME)
end

function llhttp.initialize()
	if llhttp.initialized then
		return
	end

	ffi.cdef(llhttp.cdefs)

	llhttp.initialized = true

end

return llhttp