local conf = require('matchparen').config
local utils = require('matchparen.utils')

local M = {}

-- Determines whether built-in syntax is on and current buffer has syntax for its filetype
-- @return boolean
local function is_syntax_on()
    return vim.g.syntax_on == 1 and vim.opt.syntax:get() ~= ''
end

-- Determines whether the cursor is inside neovim syntax id name
-- that match any value in `syntax_skip_groups` option list
-- @param line 0-based line number
-- @param col 0-based column number
-- @return boolean
local function in_syntax_skip_region(line, col)
    return utils.in_skip_region(line, col, function(l, c)
        local synstack = vim.fn.synstack(l + 1, c + 1)
        for i = #synstack, math.max(1, #synstack - 3), -1 do
            local synname = string.lower(vim.fn.synIDattr(synstack[i], 'name'))
            for _, pattern in ipairs(conf.syntax_skip_groups) do
                if utils.str_contains(synname, pattern) then
                    return true
                end
            end
        end
    end)
end

-- Returns skip function for `search.match_pos()`
-- @param line 0-based line number
-- @param col 0-based column number
-- @return function
function M.skip_by_region(line, col)
    local skip
    if is_syntax_on() then
        if in_syntax_skip_region(line, col) then
            skip = function(l, c)
                return not in_syntax_skip_region(l, c)
            end
        else
            skip = function(l, c)
                return in_syntax_skip_region(l, c)
            end
        end
    end
    return skip
end

return M
