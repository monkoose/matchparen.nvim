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

-- Returns true if `str` constains `pattern`, false otherwise
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

-- Returns first found index and full match substring in the `text` or nil
-- @param text string
-- @param pattern string
-- @param init number same as in string.find
-- @return (number, string) or nil
function M.find_forward(text, pattern, init)
    local index, _, bracket = string.find(text, pattern, init and init + 1)
    return index, bracket
end

function M.find_backward(reversed_text, pattern, init)
    local length = #reversed_text + 1
    local index, bracket = M.find_forward(reversed_text, pattern, init and length - init)
    if index then
        return length - index, bracket
    end
end

-- Returns text for the `line` of the current buffer
-- @param line number (0-based) line number
-- @return string
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
