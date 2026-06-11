-- Testing file
-- test get_line
local syntax = require("matchparen.syntax")
local hello = (syntax.skip_by_region("hellloworld(hello)"))
--            |    result is 4 14 4 58
local hello = (syntax.skip_by_region("hellloworld(hello)"))
--                                  |    result is 6 36 6 57
local hello = (syntax.skip_by_region("hellloworld(hello)"))
--                                               |    result is 8 49 8 55
