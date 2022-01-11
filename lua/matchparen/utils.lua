local conf = require('matchparen').config

local M = {}

-- Determines whether cursor is in a special region
-- @param line number (0-based) line number
-- @param col number (0-based) column number
-- @param fn function that return nil outside of region
-- @return boolean
function M.in_skip_region(line, col, fn)
    if vim.fn.foldclosed(line + 1) ~= -1 then
        return false
    end
    return fn(line, col) ~= nil
end

-- Determines whether a search should stop if searched line outside of range
-- @param line number (0-based) line number
-- @param backward boolean direction of the search
-- @return boolean
function M.limit_by_line(line, backward)
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

local function find_forward_char(text, chars, limit)
    local index, _, bracket = string.find(text, '([' .. chars .. '])', limit)
    return index, bracket
end

local function find_backward_char(text, chars, limit)
    text = text:sub(1, limit)
    if not string.find(text, '([' .. chars ..'])') then return end
    local _, index, bracket = string.find(text, '.*([' .. chars .. '])')
    return index, bracket
end

local function find_char(text, chars, limit, backward)
        if backward then
            return find_backward_char(text, chars, limit and limit - 1)
        else
            return find_forward_char(text, chars, limit and limit + 1)
        end
end

local function next_line_pos(line, backward)
    line = backward and line - 1 or line + 1
    return line, nil
end

local function get_line(line)
    return vim.api.nvim_buf_get_lines(0, line, line + 1, false)[1]
end


function M.search(char, line, col, backward, skip, stop)
    local index
    local text = get_line(line)
    stop = stop or function() end
    skip = skip or function() end

    repeat
        index = find_char(text, char, col, backward)

        if index then
            col = index
            index = index - 1
            if not skip(line, index) then
                if stop(line, index) then return end
                return line, index
            end
        else
            line, col = next_line_pos(line, backward)
            text = get_line(line)
        end
    until not text or stop(line, col)
end

-- Returns line and column of a matched bracket
-- @param left char left bracket
-- @param right char right bracket
-- @param line number (0-based) line number
-- @param col number (0-based) column number
-- @param backward boolean direction of the search
-- @param skip function
-- @param stop function
-- @return (number, number) or nil
function M.search_pair(left, right, line, col, backward, skip, stop)
    local count = 0
    local text = get_line(line)
    local index, bracket
    local chars = right .. left
    local same_bracket = backward and right or left
    col = col + 1
    stop = stop or function() end
    skip = skip or function() end

    repeat
        index, bracket = find_char(text, chars, col, backward)
        if index then
            col = index
            index = index - 1
            if not skip(line, index) then
                if bracket == same_bracket then
                    count = count + 1
                else
                    if count == 0 then
                        if stop(line, index) then return end
                        return line, index
                    else
                        count = count - 1
                    end
                end
            end
        else
            line, col = next_line_pos(line, backward)
            text = get_line(line)
        end
    until not text or stop(line, col)
end

return M
