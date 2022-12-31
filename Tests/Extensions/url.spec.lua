local URL = require("url")

describe("URL", function()

	local fixtures = import("./../Fixtures/webkit-url-examples.lua")
	-- dump(fixtures)
	describe("create", function()

local function bURL(url, base)
  return base and URL:Parse(url, base)  or URL:Parse(url)
end

local function runURLTests(urltests)
  for i = 1, #urltests, 1 do
    local expected = urltests[i]
	-- skip comments
    if type(expected) ~= "string" then

		-- test(function()
			if (expected.failure) then

				assertThrows(function()
					bURL(expected.input, expected.base)
				end, "TBD TypeError")
				return
			end
		-- end)

    	local url = bURL(expected.input, expected.base)
      assertEquals(url.href, expected.href, "href")
      assertEquals(url.protocol, expected.protocol, "protocol")
      assertEquals(url.username, expected.username, "username")
      assertEquals(url.password, expected.password, "password")
      assertEquals(url.host, expected.host, "host")
      assertEquals(url.hostname, expected.hostname, "hostname")
      assertEquals(url.port, expected.port, "port")
      assertEquals(url.pathname, expected.pathname, "pathname")
      assertEquals(url.search, expected.search, "search")
      if expected.searchParams then
        assertTrue(url.searchParams)
		-- TBD
        assertEquals(url.searchParams.toString(), expected.searchParams, "searchParams")
	  end
	assertEquals(url.hash, expected.hash, "hash")
-- "Parsing: <" + expected.input + "> against <" + expected.base + ">")
end
end
end

runURLTests(fixtures)

end)

error("nyi")
end)

-- Class: URL
-- new URL(input[, base])
-- url.hash
-- url.host
-- url.hostname
-- url.href
-- url.origin
-- url.password
-- url.pathname
-- url.port
-- url.protocol
-- 	Special schemes
-- url.search
-- url.searchParams
-- url.username
-- url.toString()
-- url.toJSON()
-- URL.createObjectURL(blob)
-- URL.revokeObjectURL(id)
-- Class: URLSearchParams
-- new URLSearchParams()
-- new URLSearchParams(string)
-- new URLSearchParams(obj)
-- new URLSearchParams(iterable)
-- urlSearchParams.append(name, value)
-- urlSearchParams.delete(name)
-- urlSearchParams.entries()
-- urlSearchParams.forEach(fn[, thisArg])
-- urlSearchParams.get(name)
-- urlSearchParams.getAll(name)
-- urlSearchParams.has(name)
-- urlSearchParams.keys()
-- urlSearchParams.set(name, value)
-- urlSearchParams.sort()
-- urlSearchParams.toString()
-- urlSearchParams.values()
-- urlSearchParams[Symbol.iterator]()
-- url.domainToASCII(domain)
-- url.domainToUnicode(domain)
-- url.fileURLToPath(url)
-- url.format(URL[, options])
-- url.pathToFileURL(path)
-- url.urlToHttpOptions(url)
