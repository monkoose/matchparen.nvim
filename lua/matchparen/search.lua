local syntax = require('matchparen.syntax')
local ts = require('matchparen.treesitter')
local utils = require('matchparen.utils')

local M = {}

-- Determines whether a search should stop if searched line outside of range
-- @param line number (0-based) line number
-- @param backward boolean direction of the search
-- @return boolean
local function limit_by_line(line, backward)
    local stop
    local stopline
    local win_height = vim.api.nvim_win_get_height(0)
    if backward then
        stopline = line - win_height
        stop = function(l)
            return l < stopline
        end
    else
        stopline = line + win_height
        stop = function(l)
            return l > stopline
        end
    end
    return stop
end

function M.char(chars, line, col, backward, skip, stop)
    col = col + 1
    stop = stop or function() end
    skip = skip or function() end

    local next_line, find_char, get_line_text
    if backward then
        next_line = utils.decrement
        find_char = utils.find_backward_char
        get_line_text = utils.get_reversed_line
    else
        next_line = utils.increment
        find_char = utils.find_forward_char
        get_line_text = utils.get_line
    end

    local index, bracket
    local ok, to_skip
    local text = get_line_text(line)

    repeat
        index, bracket = find_char(text, chars, col)
        if index then
            col = index
            index = index - 1

            ok, to_skip = pcall(skip, line, index, bracket)
            if not ok then return end

            if not to_skip then
                if stop(line, index) then return end
                return line, index
            end
        else
            col = nil
            line = next_line(line)
            text = get_line_text(line)
        end
    until not text or stop(line, col)
end

-- Returns line and column of a matched bracket
-- @param left string of brackets
-- @param right string of brackets
-- @param line number (0-based) line number
-- @param col number (0-based) column number
-- @param backward boolean direction of the search
-- @param skip function
-- @param stop function
-- @return (number, number) or nil
function M.pair(left, right, line, col, backward, skip, stop)
    local count = 0
    local chars = right .. left
    local same_bracket = backward and right or left
    local skip_same_bracket = function(_, _, bracket)
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

    if skip then
        local old_skip = skip
        skip = function(l, c, bracket)
            return old_skip(l, c) or skip_same_bracket(l, c, bracket)
        end
    else
        skip = skip_same_bracket
    end

    return M.char(chars, line, col, backward, skip, stop)
end

-- Returns matched bracket position
-- @param matchpair table
-- @param line number line of `bracket`
-- @param col number column of `bracket`
-- @param stopline function
-- @return (number, number) or nil
function M.match_pos(matchpair, line, col)
    local stop
    local skip
    ts.hl = ts.get_highlighter()

    if ts.hl then
        ts.trees = ts.get_trees()
        ts.skip_nodes = {}
        local skip_node = ts.get_skip_node(line, col)
        -- FiXME: this if condition only to fix annotying bug for treesitter strings
        if skip_node and not ts.is_node_comment(skip_node) then
            if not ts.is_in_node_range(skip_node, line, col + 1) then
                skip_node = false
            end
        end

        if skip_node then  -- inside string or comment
            stop = ts.limit_by_node(skip_node, matchpair.backward)
        else
            ts.root = ts.get_tree_root()
            local parent = ts.node_at(line, col):parent()
            skip = function(l, c)
                return ts.in_ts_skip_region(l, c, parent)
            end
            stop = limit_by_line(line, matchpair.backward)
        end
    else  -- try built-in syntax to skip highlighting in strings and comments
        skip = syntax.skip_by_region(line, col)
        stop = limit_by_line(line, matchpair.backward)
    end

    return M.pair(matchpair.left, matchpair.right, line, col, matchpair.backward, skip, stop)
end

return M
