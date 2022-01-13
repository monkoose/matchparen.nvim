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

-- Determines whether current mode is insert or Replace
-- @return boolean
function M.is_in_insert_mode()
    local mode = vim.api.nvim_get_mode().mode
    return mode == 'i' or mode == 'R'
end

-- Determines whether `str` constains `pattern`
-- @param str string
-- @param pattern string
-- @return boolean
function M.str_contains(str, pattern)
    return str:find(pattern, 1, true) ~= nil
end

-- Returns 0-based current line and column
-- @return number, number
function M.get_current_pos()
    local line, column = unpack(vim.api.nvim_win_get_cursor(0))
    return line - 1, column
end

function M.find_forward_char(text, chars, limit)
    local index, _, bracket = string.find(text, '([' .. chars .. '])', limit and limit + 1)
    return index, bracket
end

function M.find_backward_char(reversed_text, chars, limit)
    local length = #reversed_text + 1
    local index, bracket = M.find_forward_char(reversed_text, chars, limit and length - limit)
    if index then
        return length - index, bracket
    end
end

function M.get_line(line)
    return vim.api.nvim_buf_get_lines(0, line, line + 1, false)[1]
end

function M.get_reversed_line(line)
    local text = M.get_line(line)
    if text then
        return string.reverse(M.get_line(line))
    end
end

function M.increment(number)
    return number + 1
end

function M.decrement(number)
    return number - 1
end

return M
