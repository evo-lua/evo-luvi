# About

This is a modified version of the [Luvi](https://github.com/luvit/luvi) Lua runtime, primarily with the goal of iterating on various ideas and experimentating in an isolated environment.

The runtime is built to serve my own needs first and foremost, which may or may not be of interest to anyone else.  It's a work-in-progress and likely never finished.

If you aren't familiar: Luvi provides a Lua environment based on the [LuaJIT](luajit.org/) compiler, with builtin C libraries like [libuv](https://libuv.org), [OpenSSL](https://openssl.org/) and [miniz](https://github.com/richgel999/miniz).
Luvi also includes facilities to create self-contained executables from your Lua scripts and serves as a foundation for the [luvit](https://github.com/luvit/luvit) runtime, which are inherited by this variant.

---

For more information, see the [Luvi README](https://github.com/luvit/luvi)

Not all sections still apply to this fork, but the foundations are the same.

## Changes from Luvi

Evo (formerly evo-luvi) differs in various ways from the original luvi runtime.

Here are the high-level differences (list is not exhaustive):

* Path resolution is built in (via ported code from [V8](https://v8.dev/) & [NodeJS](https://nodejs.org/))
* A new ``import`` mechanism to load Lua modules by relative paths or from within a ``.evo`` module folder, using GitHub-style package organization (``@owner/packageName`` syntax similar to [npm scopes](https://docs.npmjs.com/misc/scope/))
* Includes [inspect.lua](https://github.com/kikito/inspect.lua) as a builtin extension to aid debugging
* Primarily uses the [Ninja build system](https://github.com/ninja-build/ninja) instead of a jungle of CMake files
* Many new APIs, globals, and other utilities (added on an as-needed basis)
* Focus on tests and refactoring to pay off some technical debt

Whether these and other changes are good ideas, only time will tell :)

## Compatibility

Evo is **fully compatible** with:

* PUC Lua 5.1
* LuaJIT (latest)

It is **generally incompatible** with:

* PUC Lua 5.2, 5.3, or 5.4 (though some 5.2 and 5.3 APIs are supported)
* Any LuaJIT fork that strays too far from upstream (it's dangerous out there!)
* Embedded Lua(u) environments, like those found in games (ROBLOX, WOW, ...)

The primary platforms I am officially supporting are those I actively use:

* Windows 10 (or higher, x64 only)
* Linux (Ubuntu-like, on x64 desktop)
* Mac OS is also covered via the CI, but I don't have one anymore

Things should still work on other platforms, if supported by all dependencies, but YMMV and there may be unforeseen issues (aren't there always?).

## More Documentation

The documentation website (work in progress) can be found here:

* [https://evo-lua.github.io/](https://evo-lua.github.io/)

If something's outdated, wrong, or missing, please open an issue [here](https://github.com/evo-lua/evo-lua.github.io)!

## Licensing Information

See [License.txt](LICENSE.txt) - it's Apache 2.0 (as inherited from Luvi).

Third-party dependencies may have differing (compatible) licenses.
