local syntax = require('matchparen.syntax')
local ts = require('matchparen.treesitter')
local utils = require('matchparen.utils')

local M = {}

---Returns functions based on `backward` direction
---@param backward boolean
---@return function, function, function
local function get_direction_funcs(backward)
    if backward then
        return utils.dec, utils.find_backward, utils.get_reversed_line
    else
        return utils.inc, utils.find_forward, utils.get_line
    end
end

---Returns positon of the first match of the `pattern` in the current buffer
---starting from `line` and `col`
---@param pattern string
---@param line number 0-based line number
---@param col number 0-based column number
---@param backward boolean direction of the search
---@param skip function
---@param stop function
---@return number|nil, number
function M.match(pattern, line, col, backward, skip, stop)
    col = col + 1
    stop = stop or function() end
    skip = skip or function() end

    local index, bracket
    local ok, to_skip
    local next_line, find, get_line_text = get_direction_funcs(backward)
    local text = get_line_text(line)

    while text do
        index, bracket = find(text, pattern, col)
        if index then
            col = index
            index = utils.dec(index)

            ok, to_skip = pcall(skip, line, index, bracket)
            if not ok then return end

            if not to_skip then
                if stop(line, index) then return end
                return line, index
            end
        else
            line = next_line(line)
            if stop(line) then return end
            col = nil
            text = get_line_text(line)
        end
    end
end

---Returns line and column of a matched bracket
---@param left string
---@param right string
---@param line number 0-based line number
---@param col number 0-based column number
---@param backward boolean direction of the search
---@param skip function
---@param stop function
---@return number|nil, number
function M.pair(left, right, line, col, backward, skip, stop)
    local count = 0
    local pattern = '([' .. right .. left .. '])'
    local same_bracket = backward and right or left
    local skip_same_bracket = function(bracket)
        if bracket == same_bracket then
            count = count + 1
        else
            if count == 0 then
                return false
            else
                count = count - 1
            end
        end
        return true
    end

    local skip_fn
    if skip then
        skip_fn = function(l, c, bracket)
            return skip(l, c) or skip_same_bracket(bracket)
        end
    else
        skip_fn = function(_, _, bracket)
            return skip_same_bracket(bracket)
        end
    end

    return M.match(pattern, line, col, backward, skip_fn, stop)
end

---Returns matched bracket position
---@param matchpair table
---@param line number line of `bracket`
---@param col number column of `bracket`
---@return number|nil, number
function M.match_pos(matchpair, line, col)
    local stop
    local skip
    ts.hl = ts.get_highlighter()

    if ts.hl then
        skip, stop = ts.skip_and_stop(line, col, matchpair.backward)
    else  -- try built-in syntax to skip highlighting in strings and comments
        skip = syntax.skip_by_region(line, col)
        stop = utils.limit_by_line(line, matchpair.backward)
    end

    return M.pair(matchpair.left, matchpair.right, line, col, matchpair.backward, skip, stop)
end

return M
