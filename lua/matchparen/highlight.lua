local conf = require('matchparen').config
local syntax = require('matchparen.syntax')
local ts = require('matchparen.treesitter')

local M = {}

-- @return (bool) if in insert or Replace modes
local function is_in_insert_mode()
    local mode = vim.api.nvim_get_mode().mode
    return mode == 'i' or mode == 'R'
end

local function create_extmark(line, col)
    return vim.api.nvim_buf_set_extmark(
        0, conf.namespace, line, col,
        { end_col = col + 1, hl_group = conf.hl_group }
    )
end

local function delete_extmark(id)
    vim.api.nvim_buf_del_extmark(0, conf.namespace, id)
end

-- Removes highlighting from matched characters
function M.remove()
    delete_extmark(conf.extmarks.current)
    delete_extmark(conf.extmarks.match)
end

-- Highlight characters at positions x and y, if y line position is correct
local function apply_highlight(x_line, x_col, y_line, y_col)
    if y_line >= 0 then
        conf.extmarks.current = create_extmark(x_line, x_col)
        conf.extmarks.match = create_extmark(y_line, y_col)
    end
end

-- Returns true if current buffer has treesitter highlight enabled
local function has_ts_highlight()
    local bufnr = vim.api.nvim_get_current_buf()
    return vim.treesitter.highlighter.active[bufnr] ~= nil
end

-- Returns matched bracket position
-- @param bracket (string) which bracket to match
-- @param line (number) line number of `bracket`
-- @param col (number) column number of `bracket`
-- @param insert (bool) true if in insert mode
-- @return number, number or nil
local function get_match_pos(bracket, line, col, insert)
    local match_line
    local match_col

    if has_ts_highlight() then
        conf.parser = ts.get_parser()
        local skip, skip_node = ts.skip(conf.parser, conf.ts_skip_groups, line - 1, col)
        if skip then
            match_line, match_col = ts.get_skip_match_pos(conf.matchpairs[bracket],
                                                                    skip_node, line, insert)
        else
            match_line, match_col = ts.get_match_pos(conf.matchpairs[bracket],
                                                        line, insert)
        end
    else  -- try built-in syntax to skip highlighting in strings and comments
        match_line, match_col = syntax.get_match_pos(conf.matchpairs[bracket], line, insert)
    end
    return match_line, match_col
end

-- Updates the highlight of brackets by first removing previous highlight
-- and then if there is matching brackets at the new cursor position highlight them
function M.update(in_insert)
    M.remove()
    vim.g.matchparen_tick = vim.api.nvim_buf_get_changedtick(0)

    local cursor_line, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
    -- Do not process current line if it is in closed fold
    if vim.fn.foldclosed(cursor_line) ~= -1 then return end
    -- Should it also check for `pumvisible()` as original matchparen does?
    -- Because I do not notice any difference and popupmenu doesn't close

    local text = vim.api.nvim_get_current_line()
    -- nvim_win_get_cursor returns column started from 0, so we need to
    -- increment it for `string.sub()` to get correct result
    local inc_col = cursor_col + 1
    local bracket = text:sub(inc_col, inc_col)
    in_insert = is_in_insert_mode() or in_insert
    -- `shift` variable used for insert mode to check if we should shift
    -- the cursor position to the left by one column, neovim matchparen calculates bracket
    -- size, but i'm not sure why, does someone use multicolumn characters for `matchpairs` option?
    local shift = false

    if cursor_col > 0 and in_insert then
        local before_char = text:sub(cursor_col, cursor_col)
        if conf.matchpairs[before_char] then
            bracket = before_char
            shift = true
        end
    end

    if not conf.matchpairs[bracket] then return end

    -- shift cursor to the left
    if shift then
        cursor_col = cursor_col - 1
        vim.api.nvim_win_set_cursor(0, { cursor_line, cursor_col })
    end

    local match_line, match_col = get_match_pos(bracket, cursor_line, cursor_col, in_insert)

    -- restore cursor if previously shifted
    if shift then
        cursor_col = cursor_col + 1
        vim.api.nvim_win_set_cursor(0, { cursor_line, cursor_col })
    end

    if not match_line then return end

    -- If shift was true `cursor_col` should be decremented to highlight correct bracket
    cursor_col = shift and cursor_col - 1 or cursor_col
    apply_highlight(cursor_line - 1, cursor_col, match_line, match_col)
end

function M.update_on_tick()
    if vim.g.matchparen_tick ~= vim.api.nvim_buf_get_changedtick(0) then
        M.update()
    end
end

return M
