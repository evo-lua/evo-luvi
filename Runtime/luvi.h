/*
 *  Copyright 2015 The Luvit Authors. All Rights Reserved.
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
#ifndef LUVI_H
#define LUVI_H

#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"
#include "luv.h"
#include "uv.h"

#include <stdlib.h>
#include <string.h>
#ifdef _WIN32
#include <windows.h>
#include <winsock2.h>
#else
#include <errno.h>
#include <unistd.h>
#endif

#if (LUA_VERSION_NUM != 503)
#include "compat-5.3.h"
#endif

#include "openssl.h"

#include "pcre2.h"

#include "zlib.h"
LUALIB_API int luaopen_zlib(lua_State* const L);
int luaopen_lpeg(lua_State* L);

void luvi_openlibs(lua_State* L);
#endif
