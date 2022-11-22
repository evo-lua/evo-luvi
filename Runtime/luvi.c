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

#include "./luvi.h"

#ifndef LUVI_VERSION
#define LUVI_VERSION "dev-untagged"
#endif

LUALIB_API int luaopen_luvi(lua_State* L)
{
	char buffer[1024];
	lua_newtable(L);
	lua_pushstring(L, "" LUVI_VERSION "");
	lua_setfield(L, -2, "version");
	lua_newtable(L);
	snprintf(buffer, sizeof(buffer), "%s, lua-openssl %s",
		SSLeay_version(SSLEAY_VERSION), LOPENSSL_VERSION);
	lua_pushstring(L, buffer);
	lua_setfield(L, -2, "ssl");
	lua_pushstring(L, pcre_version());
	lua_setfield(L, -2, "rex");
	lua_pushstring(L, zlibVersion());
	lua_setfield(L, -2, "zlib");

	lua_pushstring(L, llhttp_get_version_string());
	lua_setfield(L, -2, "llhttp");
	lua_pushstring(L, uv_version_string());
	lua_setfield(L, -2, "libuv");
	lua_setfield(L, -2, "options");
	return 1;
}
