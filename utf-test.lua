local utf8 = require("utf8")
dump(utf8)

-- local url = "http://example.com/\xD8\x00\xD8\x01\xDF\xFE\xDF\xFF\xFD\xD0\xFD\xCF\xFD\xEF\xFD\xF0\xFF\xFE\xFF\xFF?\xD8\x00\xD8\x01\xDF\xFE\xDF\xFF\xFD\xD0\xFD\xCF\xFD\xEF\xFD\xF0\xFF\xFE\xFF\xFF"
-- print(url)

-- Search: \\u\{([0-9a-fA-F]{2})([0-9a-fA-F]{2})\}
-- Replace: \x$1\x$2