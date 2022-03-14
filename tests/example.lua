-- Testing file
-- test get_line
local syntax = require('matchparen.syntax')
--    |    result is 2 14 2 58
local opana = (syntax.skip_by_region('hellloworld(opana)'))
--               |    result is 4 14 4 58
local opana = (syntax.skip_by_region('hellloworld(opana)'))
--                                          |    result is 6 36 6 57
local opana = (syntax.skip_by_region('hellloworld(opana)'))
--                                                 |    result is 8 49 8 55
local opana = (syntax.skip_by_region('hellloworld(opana)'))
