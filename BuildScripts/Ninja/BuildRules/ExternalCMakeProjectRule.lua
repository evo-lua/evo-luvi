local ExternalMakefileProjectRule = {}

function ExternalMakefileProjectRule:Construct()
    return {
        "command",
        "description",
        command = {
			-- TODO bash on unix/osx
            "cmd", "/c", "cmake", "-G", "Ninja", "-DBUILD_STATIC_LIBS=ON", "-DBUILD_SHARED_LIBS=OFF", "-DCMAKE_BUILD_TYPE=Release", "-S", "$in", "-B", "$builddir/$target", "&&", "cmake", "--build",  "$builddir/$target", "--config", "Release",
        --    "cmake", "-S", "$in", "-B", "$builddir/$target"
        },
        description = {"External CMake build in directory", "$in"}
    }
end

ExternalMakefileProjectRule.__call = ExternalMakefileProjectRule.Construct
setmetatable(ExternalMakefileProjectRule, ExternalMakefileProjectRule)

return ExternalMakefileProjectRule
