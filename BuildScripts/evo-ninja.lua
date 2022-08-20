local llhttp = import("./Targets/llhttp.lua")

local llhttpBuildFile = llhttp:CreateBuildFile()
llhttpBuildFile:Save("llhttp_test.ninja")

-- local path_join = path.join

-- local Executable = import("./Ninja/Executable.lua")
-- local StaticLibrary = import("./Ninja/StaticLibrary.lua")


-- -- root_dir = deps/llhttp-ffi/llhttp
-- -- source_dir = $root_dir/src
-- -- include_dir = $root_dir/include

-- -- build $builddir/api.o: compile $source_dir/api.c
-- --   includes = -I$include_dir
-- -- build $builddir/http.o: compile $source_dir/http.c
-- --   includes = -I$include_dir
-- -- build $builddir/llhttp.o: compile $source_dir/llhttp.c
-- --   includes = -I$include_dir

-- -- build $builddir/libllhttp.a: ar $builddir/api.o $builddir/http.o $builddir/llhttp.o

-- -- set(LLHTTP_FFI_SOURCE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/deps/llhttp-ffi)
-- -- set(LLHTTP_SOURCE_DIRECTORY ${LLHTTP_FFI_SOURCE_DIRECTORY}/llhttp)

-- -- message("Enabling Static LLHTTP")
-- -- add_subdirectory(${LLHTTP_SOURCE_DIRECTORY})
-- -- include_directories(${LLHTTP_SOURCE_DIRECTORY}/include)

-- -- add_library(llhttp
-- -- 	${LLHTTP_SOURCE_DIRECTORY}/src/api.c
-- -- 	${LLHTTP_SOURCE_DIRECTORY}/src/http.c
-- -- 	${LLHTTP_SOURCE_DIRECTORY}/src/llhttp.c
-- -- 	${LLHTTP_FFI_SOURCE_DIRECTORY}/llhttp.def
-- -- )
-- -- list(APPEND EXTRA_LIBS llhttp)

-- local evo = import("Targets/evo.lua")
-- local llhttp = import("Targets/llhttp.lua")
