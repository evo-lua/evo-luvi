local changelog = {
	["v3.1.0"] = {
		newFeatures = {
			"A global ``extend`` builtin is now available to complement ``mixin`` with more typical, metatable-based inheritance",
		},
		improvements = {
			"TCP clients and servers now trigger ``TCP_BACKPRESSURE_*`` events based on their internal write buffer status",
			"TCP clients and servers now trigger ``TCP_EOF_RECEIVED`` when the connected peer unilaterally closes the socket",
			"The runtime now always includes debug symbols for embedded LuaJIT bytecode objects to enable better stack traces",
		},
		breakingChanges = {
			"The standalone [llhttp-ffi](https://github.com/evo-lua/llhttp-ffi) bindings are now integrated with the runtime itself (and will not be maintained independently)",
			"The preloaded ``luvi`` library is now called ``runtime`` and has a slightly different exports signature",
		},
	},
	["v3.0.0"] = {
		newFeatures = {
			"The NodeJS [low-level HTTP parser](https://github.com/nodejs/llhttp) is now included in the runtime and made available via the preloaded ``llhttp`` library",
		},
		breakingChanges = {
			"The legacy CMake build system has been replaced with a much simpler one that is based on [Ninja](https://ninja-build.org/) files",
			"The obsolete ``env`` library has been removed (use the  ``uv`` library for accessing environment variables instead)",
		},
	},
}

return changelog
