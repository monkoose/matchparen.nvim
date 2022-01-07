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
-- @return boolean
function M.in_syntax_skip_region()
    return utils.in_skip_region(function(line, col)
        for _, id in ipairs(vim.fn.synstack(line + 1, col + 1)) do
            local synname = string.lower(vim.fn.synIDattr(id, 'name'))
            for _, pattern in ipairs(conf.syntax_skip_groups) do
                if string.find(synname, pattern) then
                    return true
                end
            end
        end
    end)
end

-- Returns 0-based line and column of matched bracket if any or nil
-- @param matchpair
-- @param line 1-based current line number
-- @param insert true if in insert mode
-- @return (number, number) or nil
function M.get_match_pos(matchpair, line, insert)
    local skip_ref
    if is_syntax_on() then
        if M.in_syntax_skip_region() then
            skip_ref = '!matchparen#skip()'
        else
            skip_ref = 'matchparen#skip()'
        end
    else
        skip_ref = ''
    end

    return utils.search_pair_pos(matchpair, skip_ref, line, insert)
end

return M
