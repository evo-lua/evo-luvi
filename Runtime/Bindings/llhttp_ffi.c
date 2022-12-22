#include "llhttp.h"
#include "lua.h"

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

#define EXPAND_AS_STRING(text) #text
#define TOSTRING(text) EXPAND_AS_STRING(text)
#define LLHTTP_VERSION_STRING      \
	TOSTRING(LLHTTP_VERSION_MAJOR) \
	"." TOSTRING(LLHTTP_VERSION_MINOR) "." TOSTRING(LLHTTP_VERSION_PATCH)

const char* llhttp_get_version_string(void)
{
	return LLHTTP_VERSION_STRING;
}

void export_llhttp_bindings(lua_State* L)
{
	static struct static_llhttp_exports_table llhttp_exports_table;
	llhttp_exports_table.llhttp_init = llhttp_init;
	llhttp_exports_table.llhttp_reset = llhttp_reset;
	llhttp_exports_table.llhttp_settings_init = llhttp_settings_init;
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

	lua_getglobal(L, "STATIC_FFI_EXPORTS");
	lua_pushlightuserdata(L, &llhttp_exports_table);
	lua_setfield(L, -2, "llhttp");
}

webview::bind

Binds a native C++ callback so that it will appear under the given name as a
global JavaScript function. Internally it uses init. Callback receives a request string. Request string is a JSON array of all the arguments passed
to the JavaScript function.

// void bind(const std::string name, sync_binding_t fn)

// sync_binding_t is an alias for std::function<std::string(std::string)>
// Thus, an example callback looks like:

// std::string myBoundCallback(string args) {
//   return "\"Return this string to the JS function 'myBoundCallback'\"";
// }

// Now you can call this JavaScript function like so:

// myBoundCallback("arg1", 2, true).then(e => console.log(e));

// in webview_ffi: bind("llhttp", webview_bind_llhttp_callback); // C++, not C?

// TODO use C function bind, the webview docs were just incomplete.. No need for C++ at all?
// void bind(const std::string name, sync_binding_t fn)

// sync_binding_t is an alias for std::function<std::string(std::string)>
// Thus, an example callback looks like:

static const char* myBoundCallback(const char* args) {
	printf("Hello from myBoundCallback (args: %s)! I was bound via webview_bind_llhttp_callback (in C++ land)\n", args);
  	return "\"Return this string to the JS function 'myBoundCallback'\"";
}


void webview_bind_llhttp_callback(webview_t webview_handle) { // TBD How to do this with just C? (#include the webview bindings in the C++ wrapper, extern C, link with runtime objects? Might as well use only C++ then since we still need g++ in the build system...)
	webview_bind(webview_handle, "llhttp", void (*fn)(const char *seq, const char *req,
                                         void *arg),
                              void *arg);
}
// Now you can call this JavaScript function like so:

// myBoundCallback("arg1", 2, true).then(e => console.log(e));
}


// Binds a native C callback so that it will appear under the given name as a
// global JavaScript function. Internally it uses webview_init(). Callback
// receives a request string and a user-provided argument pointer. Request
// string is a JSON array of all the arguments passed to the JavaScript
// function.
// WEBVIEW_API void webview_bind(webview_t w, const char *name,
//                               void (*fn)(const char *seq, const char *req,
//                                          void *arg),
//                               void *arg);
// seq = some internal window._rpc ID / sequence ??? / promise maybe? = javascript_function_identifier ?
// req = requestString = JSON array of args passed to fund
// arg = pointer to ???



// sync resolve and bind in C, not just C++
// Passing data obtained from C into the JS context... efficiently (buffers/TypedArrays ideally)
// run_once_and_poll_for_updates() instead of run()
// List of browser runtime APIs/stuff that you CANNOT do with webview