# LLHTTP Parser Optimizations

## Bottlenecks

* C -to-Lua callbabacks (ideal: PULL-style API in llhttp)
* String concatenation and re-creation (idea: LuaJIT string buffers?)
* TGETS (table indexing/metatables?)
* Lots of garbage collection stuff (ideal: allocate fixed-size buffer for request data, do not allocate parts?)
* TRET (return? - maybe tail-calls? Although there isn't any recursion)

## Optimizations

* Instead of Lua strings, use LuaJIT string buffers for the substrings that need to be concatenated
* Store request/response data in a C struct (via FFI), reuse and never free/garbage collect while the parser is still used
* Object pool (to reuse the parsers themselves, doubtful if worth it - unrelated)

## RC: HTTP Parser Library

Goals: Security, spec compliance, performance, ability to offload maintenance

### Candidates

* luvit http: Not actively developed, almost certainly insecure, poorly documented, extremely slow (orders of magnitude in benchmarks)
* libwebsockets: Could not figure out integration (bad docs), not as widely used as mongoose, questionable if maintained to best standards (issues go unanswered when maintainer dislikes them)
* mongoose: Easy to integrate via FFI + good docs, cannot integrate with libuv, performance not a concern (embedded/portability focused)
* llhttp: Best match so far, widely used in NodeJS, however a bit annoying to integrate (statically) and not the best docs/no pull style API = bad for ffi optimizations
* homebrew (yikes): Does not fulfill goals at all, let's not reinvent this particular wheel

## Comparison

llhttp (native/C) = equal to raw FFI
evo-luvi + llhttp-ffi (static and DLL) = equal except for overhead (needs optimization in a few parts)
luvit / pure Lua codec = it's a turtle (makes me think I'm misusing it... can it really be this slow?)
