set(LLHTTP_FFI_SOURCE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/deps/llhttp-ffi)
set(LLHTTP_SOURCE_DIRECTORY ${LLHTTP_FFI_SOURCE_DIRECTORY}/llhttp)

message("Enabling Static LLHTTP")
add_subdirectory(${LLHTTP_SOURCE_DIRECTORY})
include_directories(${LLHTTP_SOURCE_DIRECTORY}/include)

add_library(llhttp
	${LLHTTP_SOURCE_DIRECTORY}/src/api.c
	${LLHTTP_SOURCE_DIRECTORY}/src/http.c
	${LLHTTP_SOURCE_DIRECTORY}/src/llhttp.c
	${LLHTTP_FFI_SOURCE_DIRECTORY}/llhttp.def
)
list(APPEND EXTRA_LIBS llhttp)