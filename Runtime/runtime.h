#pragma once

#include "luvi.h"

#ifndef LUVI_VERSION
#define LUVI_VERSION "dev-untagged"
#endif

LUALIB_API int luaopen_runtime(lua_State* L);