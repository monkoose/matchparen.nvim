local conf = require('matchparen').config
local utils = require('matchparen.utils')

local M = {}

---Determines whether built-in syntax is on and current buffer has syntax for its filetype
---@return boolean
local function is_syntax_on()
    return vim.g.syntax_on == 1 and vim.opt.syntax:get() ~= ''
end

---Returns iterator with the last three syntax group names
---under the `line` `col` position in the current buffer
---@param line number 0-based line number
---@param col number 0-based column number
---@return function
local function last3_synnames(line, col)
    local synstack = vim.fn.synstack(line + 1, col + 1)
    local len = #synstack
    local last3 = {
        synstack[len],
        synstack[len - 1],
        synstack[len - 2],
    }
    local i = 0

    return function ()
        i = i + 1
        if i <= #last3 then
            local synname = string.lower(vim.fn.synIDattr(last3[i], "name"))
            return synname
        end
    end
end

---Determines whether the cursor is inside neovim syntax id name
---that match any value in `syntax_skip_groups` option list
---@param line number 0-based line number
---@param col number 0-based column number
---@return boolean
local function in_syntax_skip_region(line, col)
    return utils.in_skip_region(line, col, function(l, c)
        for synname in last3_synnames(l, c) do
            for _, pattern in ipairs(conf.syntax_skip_groups) do
                if utils.str_contains(synname, pattern) then
                    return true
                end
            end
        end
    end)
end

---Returns skip function for `search.match_pos()`
---@param line number 0-based line number
---@param col number 0-based column number
---@return function|nil
function M.skip_by_region(line, col)
    if not is_syntax_on() then return end

    if in_syntax_skip_region(line, col) then
        return function(l, c)
            return not in_syntax_skip_region(l, c)
        end
    else
        return function(l, c)
            return in_syntax_skip_region(l, c)
        end
    end
end

return M
