#pragma once

#include "luvi.h"

#ifndef EVO_VERSION
#define EVO_VERSION "dev-untagged"
#endif

LUALIB_API int luaopen_runtime(lua_State* L);