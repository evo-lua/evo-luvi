/*
 *  Copyright 2014 The Luvit Authors. All Rights Reserved.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

#include "luvi.h"
#include "runtime.h"
#include "Bindings/llhttp_ffi.h"

LUALIB_API int luaopen_runtime(lua_State* L)
{
	char buffer[1024];
	lua_newtable(L);
	lua_pushstring(L, "" EVO_VERSION "");
	lua_setfield(L, -2, "version");

	// Can use this to store dereferenced signal handles (for testing and debugging purposes)
	lua_newtable(L);
	lua_setfield(L, -2, "signals");

	lua_newtable(L);
	snprintf(buffer, sizeof(buffer), "%s, lua-openssl %s",
		SSLeay_version(SSLEAY_VERSION), LOPENSSL_VERSION);
	lua_pushstring(L, buffer);
	lua_setfield(L, -2, "ssl");

	// This seems rather messy, but the PCRE2 API doesn't offer a better way for accessing the version AFAICT
	int requiredBufferSizeInBytes = pcre2_config(PCRE2_CONFIG_VERSION, NULL);
	char* versionString = (char*)malloc(requiredBufferSizeInBytes * sizeof(char));
	if (versionString == NULL) { // OOM? Unlikely to ever happen, but still...
		lua_pushstring(L, "?");
	} else {
		int success = pcre2_config(PCRE2_CONFIG_VERSION, versionString);

		if (!success)
			lua_pushstring(L, "???"); // Even less likely to happen, but better safe than sorry?
		else
			lua_pushstring(L, versionString);

		free(versionString);
	}
	lua_setfield(L, -2, "regex");

	lua_pushstring(L, zlibVersion());
	lua_setfield(L, -2, "zlib");

	lua_pushstring(L, llhttp_get_version_string());
	lua_setfield(L, -2, "llhttp");
	lua_pushstring(L, uv_version_string());
	lua_setfield(L, -2, "libuv");
	lua_setfield(L, -2, "libraries");
	return 1;
}
