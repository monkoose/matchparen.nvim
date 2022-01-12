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
    local index, _, bracket = string.find(text, '([' .. chars .. '])', limit and limit + 1)
    return index, bracket
end

local function find_backward_char(reversed_text, chars, limit)
    local length = #reversed_text + 1
    local index, bracket = find_forward_char(reversed_text, chars, limit and length - limit)
    if index then
        return length - index, bracket
    end
end

local function get_line(line)
    return vim.api.nvim_buf_get_lines(0, line, line + 1, false)[1]
end

local function get_reversed_line(line)
    local text = get_line(line)
    if text then
        return string.reverse(get_line(line))
    end
end

local function increment(number)
    return number + 1
end

local function decrement(number)
    return number - 1
end

function M.search(char, line, col, backward, skip, stop)
    local index
    col = col + 1
    stop = stop or function() end
    skip = skip or function() end
    local ok, to_skip
    local next_line
    local find_char
    local get_line_text
    if backward then
        next_line = decrement
        find_char = find_backward_char
        get_line_text = get_reversed_line
    else
        next_line = increment
        find_char = find_forward_char
        get_line_text = get_line
    end
    local text = get_line_text(line)

    repeat
        index = find_char(text, char, col)

        if index then
            col = index
            index = index - 1

            ok, to_skip = pcall(skip, line, index)
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
    local index, bracket
    local chars = right .. left
    col = col + 1
    stop = stop or function() end
    skip = skip or function() end
    local ok, to_skip
    local same_bracket
    local next_line
    local find_char
    local get_line_text
    if backward then
        same_bracket = right
        next_line = decrement
        find_char = find_backward_char
        get_line_text = get_reversed_line
    else
        same_bracket = left
        next_line = increment
        find_char = find_forward_char
        get_line_text = get_line
    end
    local text = get_line_text(line)

    repeat
        index, bracket = find_char(text, chars, col)
        if index then
            col = index
            index = index - 1

            ok, to_skip = pcall(skip, line, index)
            if not ok then return end

            if not to_skip then
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
            col = nil
            line = next_line(line)
            text = get_line_text(line)
        end
    until not text or stop(line, col)
end

return M
