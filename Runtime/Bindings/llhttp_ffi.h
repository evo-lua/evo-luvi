#pragma once

#include "lua.h"

const char* llhttp_get_version_string(void);
void export_llhttp_bindings(lua_State* L);
