local M = { error = nil }

---Determines whether a search should stop if searched line outside of range
---@param line number 0-based line number
---@param backward boolean direction of the search
---@return function
function M.limit_by_line(line, backward)
    local stopline
    local win_height = vim.api.nvim_win_get_height(0)
    if backward then
        stopline = line - win_height
        return function(l)
            return l < stopline
        end
    else
        stopline = line + win_height
        return function(l)
            return l > stopline
        end
    end
end

---Returns true if line is inside closed fold
---@param line number 0-based line number
---@return boolean
function M.inside_closed_fold(line)
    return vim.fn.foldclosed(line + 1) ~= -1
end

---Determines whether cursor is in a special region
---@param line number 0-based line number
---@param col number 0-based column number
---@param fn function that return nil outside of the region
---@return boolean
function M.in_skip_region(line, col, fn)
    if M.inside_closed_fold(line) then
        return false
    end
    return fn(line, col) ~= nil
end

---Determines whether current mode is insert or Replace
---@return boolean
function M.is_in_insert_mode()
    local mode = vim.api.nvim_get_mode().mode
    return mode == 'i' or mode == 'R'
end

---Returns true if `str` constains `pattern`, false otherwise
---@param str string
---@param pattern string
---@return boolean
function M.str_contains(str, pattern)
    return str:find(pattern, 1, true) ~= nil
end

---Returns 0-based current line and column
---@return number, number
function M.get_current_pos()
    local line, column = unpack(vim.api.nvim_win_get_cursor(0))
    return line - 1, column
end

---Returns first found index and full match substring (if pattern
---is in a capture) in the `text` or nil
---@param text string
---@param pattern string
---@param init number same as in string.find
---@return number|nil, string
function M.find_forward(text, pattern, init)
    local index, _, bracket = string.find(text, pattern, init and init + 1)
    return index, bracket
end

---Returns first backward index and full match substring in the `text` or nil
---@param reversed_text string
---@param pattern string
---@param init number same as in string.find
---@return number|nil, string
function M.find_backward(reversed_text, pattern, init)
    local length = #reversed_text + 1
    local index, bracket = M.find_forward(reversed_text, pattern, init and length - init)
    if index then
        return length - index, bracket
    end
end

---Returns text for the `line` of the current buffer
---@param line number 0-based line number
---@return string
function M.get_line(line)
    return vim.api.nvim_buf_get_lines(0, line, line + 1, false)[1]
end

---Returns reversed text for the `line` of the current buffer
---@param line number 0-based line number
---@return string
function M.get_reversed_line(line)
    local text = M.get_line(line)
    if text then
        return string.reverse(M.get_line(line))
    end
end

---Increments `n` by 1
---@param n number
---@return number
function M.inc(n)
    return n + 1
end

---Decrements `n` by 1
---@param n number
---@return number
function M.dec(n)
    return n - 1
end

---Calculates maximum width based on length of the `strings`
---@param strings string[]
---@return number
function M.max_display_width(strings)
    local width = 0
    for _, str in ipairs(strings) do
        width = math.max(vim.fn.strdisplaywidth(str), width)
    end
    return width
end

---Displays floating window with error information
function M.show_error()
    local buf = vim.api.nvim_create_buf(false, true)
    local ui = vim.api.nvim_list_uis()[1]
    local lines = vim.split(M.error, '\n')
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)
    vim.highlight.range(buf, 0, 'ErrorMsg', { 0, 0 }, { #lines, 1000 })
    local width = math.min(ui.width - 20, M.max_display_width(lines))
    local height = math.min(ui.height - 8, #lines)
    local col = ui.width / 2 - width / 2
    local row = ui.height / 2 - height / 2 - 2

    -- top border text
    local top_message = vim.api.nvim_create_buf(false, true)
    local top_text = ' matchparen Error '
    local top_width = string.len(top_text)
    vim.api.nvim_buf_set_lines(top_message, 0, -1, true, { top_text })
    vim.highlight.range(top_message, 0, 'FloatBorder', { 0, 0 }, { 1, 1000 })
    local top_win = vim.api.nvim_open_win(top_message, 0, {
        relative = 'editor',
        width = top_width,
        height = 1,
        row = row,
        col = col + width / 2 - top_width / 2,
        border = 'none',
        style = 'minimal',
        zindex = 1010,
        focusable = false,
    })

    -- bottom border text
    local bottom_message = vim.api.nvim_create_buf(false, true)
    local bottom_text = ' Esc or q - closes this window, yy - to copy the error message '
    local bottom_width = string.len(bottom_text)
    vim.api.nvim_buf_set_lines(bottom_message, 0, 1, true, { bottom_text })
    vim.highlight.range(bottom_message, 0, 'FloatBorder', { 0, 0 }, { 1, 1000 })
    vim.highlight.range(bottom_message, 0, 'Number', { 0, 1 }, { 0, 9 })
    vim.highlight.range(bottom_message, 0, 'Number', { 0, 32 }, { 0, 34 })
    local bottom_win
    if bottom_width + 2 <= width then
        bottom_win = vim.api.nvim_open_win(bottom_message, 0, {
            relative = 'editor',
            width = bottom_width,
            height = 1,
            row = row + height + 1,
            col = col + width / 2 - bottom_width / 2,
            border = 'none',
            style = 'minimal',
            zindex = 1010,
            focusable = false,
        })
    end

    -- main window
    local win = vim.api.nvim_open_win(buf, 0, {
        relative = 'editor',
        width = width,
        height = height,
        col = col,
        row = row,
        border = 'single',
        style = 'minimal',
        zindex = 1000,
    })

    function M.close_windows()
        pcall(vim.api.nvim_win_close, bottom_win, false)
        pcall(vim.api.nvim_win_close, top_win, false)
    end

    vim.cmd('autocmd WinClosed ' .. win .. ' lua require("matchparen.utils").close_windows()')
    vim.api.nvim_win_set_option(win, 'wrap', true)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', '<Cmd>close<CR>', { noremap = true})
    vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<Cmd>close<CR>', { noremap = true})
    vim.api.nvim_buf_set_keymap(buf, 'n', 'yy', '<Cmd>%yank +<CR>', {})
end

return M
